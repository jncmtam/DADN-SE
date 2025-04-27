package mqtt

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"hamstercare/internal/websocket"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/google/uuid"
)

type TopicConfig struct {
	Temperature string
	Humidity    string
	Light       string
	WaterLevel  string
	Fan         string
	LED         string
	Pump        string
}

type MQTTPayload struct {
	Username  string  `json:"username"`
	CageName  string  `json:"cagename"`
	Type      string  `json:"type"`
	ID        string  `json:"id"`
	DataName  string  `json:"dataname"`
	Value     float64 `json:"value"`
	Timestamp int64   `json:"time"`
}

func DefaultTopics() TopicConfig {
	return TopicConfig{
		Temperature: "hamster/user1/cage1/sensor/00000000-0000-0000-0000-000000000001/temperature",
		Humidity:    "hamster/user1/cage1/sensor/00000000-0000-0000-0000-000000000002/humidity",
		Light:       "hamster/user1/cage1/sensor/00000000-0000-0000-0000-000000000003/light",
		WaterLevel:  "hamster/user1/cage1/sensor/00000000-0000-0000-0000-000000000004/water-level",
		Fan:         "hamster/user1/cage1/device/00000000-0000-0000-0000-000000000005/fan",
		LED:         "hamster/user1/cage1/device/00000000-0000-0000-0000-000000000006/led",
		Pump:        "hamster/user1/cage1/device/00000000-0000-0000-0000-000000000007/pump",
	}
}

func (tc *TopicConfig) GetAllTopics() []string {
	return []string{
		tc.Temperature,
		tc.Humidity,
		tc.Light,
		tc.WaterLevel,
		tc.Fan,
		tc.LED,
		tc.Pump,
	}
}

type JSONTime int64

func (jt *JSONTime) UnmarshalJSON(data []byte) error {
	var str string
	if err := json.Unmarshal(data, &str); err == nil {
		i, err := strconv.ParseInt(str, 10, 64)
		if err != nil {
			return fmt.Errorf("failed to parse time string '%s': %v", str, err)
		}
		*jt = JSONTime(i)
		return nil
	}
	var i int64
	if err := json.Unmarshal(data, &i); err != nil {
		return fmt.Errorf("failed to unmarshal time: %v", err)
	}
	*jt = JSONTime(i)
	return nil
}

type MessagePayload struct {
	Username string   `json:"username"`
	Cagename string   `json:"cagename"`
	Type     string   `json:"type"`
	ID       string   `json:"id"`
	Dataname string   `json:"dataname"`
	Value    float64  `json:"value"`
	Time     JSONTime `json:"time"`
}

type MQTTClient struct {
	client mqtt.Client
}

func NewMQTTClient(client mqtt.Client) *MQTTClient {
	return &MQTTClient{client: client}
}

func ConnectMQTT(db *sql.DB, wsHub *websocket.Hub) mqtt.Client {
	broker := os.Getenv("MQTT_BROKER")
	log.Printf("MQTT_BROKER value: %s", broker)
	if broker == "" {
		broker = "tcp://192.168.254.173:1883"
		log.Printf("Using default MQTT broker: %s", broker)
	}
	if !strings.HasPrefix(broker, "tcp://") && !strings.HasPrefix(broker, "ssl://") && !strings.HasPrefix(broker, "ws://") {
		broker = "tcp://" + broker
	}

	clientID := os.Getenv("MQTT_CLIENT")
	if clientID == "" {
		clientID = "hamstercare-mqtt-" + uuid.New().String()
		log.Printf("Using generated client ID: %s", clientID)
	} else {
		log.Printf("Using MQTT_CLIENT from env: %s", clientID)
	}

	mqttClient := NewMQTTClient(nil)
	opts := mqtt.NewClientOptions().
		AddBroker(broker).
		SetClientID(clientID).
		SetUsername(os.Getenv("MQTT_USERNAME")).
		SetPassword(os.Getenv("MQTT_PASSWORD")).
		SetConnectTimeout(15 * time.Second).
		SetDefaultPublishHandler(func(client mqtt.Client, msg mqtt.Message) {
			mqttClient.client = client
			handleMessage(mqttClient, db, wsHub, msg)
		}).
		SetOnConnectHandler(func(client mqtt.Client) {
			log.Println("Connected to MQTT broker")
			topic := "hamster/user1/cage1/#"
			if token := client.Subscribe(topic, 0, nil); token.Wait() && token.Error() != nil {
				log.Printf("Error subscribing to topic %s: %v", topic, token.Error())
			} else {
				log.Printf("Subscribed to topic: %s", topic)
			}
		}).
		SetConnectionLostHandler(func(client mqtt.Client, err error) {
			log.Printf("Connection lost: %v", err)
		})

	client := mqtt.NewClient(opts)
	mqttClient.client = client

	maxRetries := 5
	for attempt := 1; attempt <= maxRetries; attempt++ {
		log.Printf("Attempting to connect to MQTT broker (Attempt %d/%d)", attempt, maxRetries)
		if token := client.Connect(); token.Wait() && token.Error() != nil {
			log.Printf("Error connecting to MQTT broker: %v", token.Error())
			if attempt == maxRetries {
				log.Fatalf("Failed to connect to MQTT broker after %d attempts", maxRetries)
			}
			time.Sleep(time.Duration(1<<uint(attempt)) * time.Second)
			continue
		}
		break
	}

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigChan
		log.Println("Disconnecting from MQTT broker")
		client.Disconnect(250)
		log.Println("Disconnected from MQTT broker")
		os.Exit(0)
	}()

	return client
}

func StartMQTTClientSub(broker, topic, username, cagename, typename string, db *sql.DB, wsHub *websocket.Hub) (mqtt.Client, error) {
	if broker == "" {
		broker = os.Getenv("MQTT_BROKER")
		if broker == "" {
			broker = "tcp://10.28.128.93:1883"
		}
	}
	log.Printf("StartMQTTClientSub using broker: %s", broker)
	if !strings.HasPrefix(broker, "tcp://") && !strings.HasPrefix(broker, "ssl://") && !strings.HasPrefix(broker, "ws://") {
		broker = "tcp://" + broker
	}

	clientID := "hamstercare-sub-" + uuid.New().String()
	mqttClient := NewMQTTClient(nil)
	opts := mqtt.NewClientOptions().
		AddBroker(broker).
		SetClientID(clientID).
		SetUsername(os.Getenv("MQTT_USERNAME")).
		SetPassword(os.Getenv("MQTT_PASSWORD")).
		SetDefaultPublishHandler(func(client mqtt.Client, msg mqtt.Message) {
			mqttClient.client = client
			handleMessage(mqttClient, db, wsHub, msg)
		}).
		SetOnConnectHandler(func(client mqtt.Client) {
			log.Println("✅ Connected to MQTT broker")
			if token := client.Subscribe(topic, 0, nil); token.Wait() && token.Error() != nil {
				log.Printf("❌ Error subscribing to topic %s: %v", topic, token.Error())
			} else {
				log.Printf("📡 Subscribed to topic: %s", topic)
			}
		}).
		SetConnectionLostHandler(func(client mqtt.Client, err error) {
			log.Printf("⚠️ Connection lost: %v", err)
		})

	client := mqtt.NewClient(opts)
	mqttClient.client = client
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		return nil, fmt.Errorf("❌ Error connecting to MQTT broker: %v", token.Error())
	}

	return client, nil
}

func StartMQTTClientPub(broker, topic, username, cagename, typename, id, dataname, value string) error {
	if !strings.HasPrefix(broker, "tcp://") && !strings.HasPrefix(broker, "ssl://") && !strings.HasPrefix(broker, "ws://") {
		broker = "tcp://" + broker
	}

	opts := mqtt.NewClientOptions().
		AddBroker(broker).
		SetClientID("hamstercare-pub-" + uuid.New().String()).
		SetUsername(os.Getenv("MQTT_USERNAME")).
		SetPassword(os.Getenv("MQTT_PASSWORD"))

	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		return fmt.Errorf("error connecting to MQTT broker: %v", token.Error())
	}
	defer client.Disconnect(250)

	valueFloat, err := strconv.ParseFloat(value, 64)
	if err != nil {
		return fmt.Errorf("error parsing value as float: %v", err)
	}

	payload := map[string]interface{}{
		"username": username,
		"cagename": cagename,
		"type":     typename,
		"id":       id,
		"dataname": dataname,
		"value":    valueFloat,
		"time":     time.Now().Unix(),
	}

	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("error marshalling JSON: %v", err)
	}

	topic = fmt.Sprintf("hamster/%s/%s/%s/%s/%s", username, cagename, typename, id, dataname)
	if token := client.Publish(topic, 0, false, jsonPayload); token.Wait() && token.Error() != nil {
		return fmt.Errorf("error publishing message: %v", token.Error())
	}
	log.Printf("Published message to topic %s: %s", topic, jsonPayload)
	return nil
}
// Tạo thông báo realtime qua websoket và đẩy vào bảng notifications
func createNotification(tx *sql.Tx, wsHub *websocket.Hub, userID, cageID, sensorID, sensorType, message string, value float64, notificationType, title string, timestamp time.Time) {
    notificationID := uuid.New().String()
    if timestamp.IsZero() {
        timestamp = time.Now()
        log.Printf("[WARNING] Timestamp is zero, using current time: %s", timestamp.Format(time.RFC3339))
    }

    log.Printf("[INFO] Storing notification: ID=%s, Type=%s, Title=%s, Message=%s, UserID=%s, CageID=%s, Timestamp=%s",
        notificationID, notificationType, title, message, userID, cageID, timestamp.Format(time.RFC3339))
    _, err := tx.ExecContext(context.Background(), `
        INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        notificationID, userID, cageID, notificationType, title, message, false, timestamp)
    if err != nil {
        log.Printf("[ERROR] Error storing notification in DB: %v", err)
        return
    }

    wsMessage := websocket.NotificationMessage{
        ID:        notificationID,
        Title:     title,
        Timestamp: timestamp.Format(time.RFC3339),
        Type:      notificationType,
        Read:      false,
    }

    log.Printf("[INFO] Sending WebSocket notification: ID=%s, Type=%s, Title=%s, UserID=%s, CageID=%s",
        notificationID, notificationType, title, userID, cageID)
    select {
    case wsHub.Broadcast <- websocket.Message{UserID: userID, CageID: cageID, Type: "notification", NotificationData: wsMessage}:
        log.Printf("[INFO] Successfully sent WebSocket notification: ID=%s, Type=%s", notificationID, notificationType)
    default:
        log.Printf("[WARNING] WebSocket broadcast channel full, dropping notification: ID=%s, Type=%s", notificationID, notificationType)
    }
}

func checkCriticalValues(tx *sql.Tx, wsHub *websocket.Hub, userID, cageID, sensorID, sensorType string, value float64, timestamp time.Time) {
    var title, message string
    notificationType := "warning"

    log.Printf("[INFO] Checking critical values: sensorID=%s, sensorType=%s, value=%.1f", sensorID, sensorType, value)
    switch sensorType {
    case "temperature":
        if value > 30.0 {
            title = "Cage 1: High Temperature Alert"
            message = "Temperature is high, please turn on fan."
            createNotification(tx, wsHub, userID, cageID, sensorID, sensorType, message, value, notificationType, title, timestamp)
        }
    case "water_level":
        if value > 3.0 {
            title = "Cage 1: Water Refill Detected"
            message = fmt.Sprintf("Water refill detected: distance = %.1f cm", value)
            createNotification(tx, wsHub, userID, cageID, sensorID, sensorType, message, value, notificationType, title, timestamp)
        }
    case "light":
        if value > 1000.0 {
            title = "Cage 1: High Light Intensity Alert"
            message = fmt.Sprintf("High light intensity detected: %.1f lux. Consider reducing light exposure.", value)
            createNotification(tx, wsHub, userID, cageID, sensorID, sensorType, message, value, notificationType, title, timestamp)
        }
    default:
        log.Printf("[INFO] No critical value check for sensorType=%s", sensorType)
    }
}

    func checkAutomationRules(tx *sql.Tx, wsHub *websocket.Hub, userID, cageID, sensorID, sensorType string, value float64, timestamp time.Time, mqttClient mqtt.Client, db *sql.DB) error {
        log.Printf("[INFO] Checking automation rules: cageID=%s, sensorType=%s, sensorID=%s, value=%.1f", cageID, sensorType, sensorID, value)

        validSensorTypes := []string{"temperature", "humidity", "light", "water_level"}
        if !contains(validSensorTypes, sensorType) {
            log.Printf("[ERROR] Invalid sensor type: %s", sensorType)
            return fmt.Errorf("invalid sensor type: %s", sensorType)
        }

        rows, err := tx.QueryContext(context.Background(), `
            SELECT ar.id, ar.sensor_id, s.type AS sensor_type, ar.condition, ar.threshold, ar.action, ar.device_id, d.name, d.type
            FROM automation_rules ar
            JOIN sensors s ON ar.sensor_id = s.id
            JOIN devices d ON ar.device_id = d.id
            WHERE ar.cage_id = $1 AND s.type = $2
        `, cageID, sensorType)
        if err != nil {
            log.Printf("[ERROR] Error querying automation rules: %v", err)
            return fmt.Errorf("failed to query automation rules: %w", err)
        }
        defer rows.Close()

        ruleFound := false
        for rows.Next() {
            ruleFound = true
            var rule struct {
                ID         string
                SensorID   string
                SensorType string
                Condition  string
                Threshold  float64
                Action     string
                DeviceID   string
                DeviceName string
                DeviceType string
            }
            if err := rows.Scan(&rule.ID, &rule.SensorID, &rule.SensorType, &rule.Condition, &rule.Threshold, &rule.Action, &rule.DeviceID, &rule.DeviceName, &rule.DeviceType); err != nil {
                log.Printf("[ERROR] Error scanning automation rule: %v", err)
                continue
            }

            log.Printf("[INFO] Found rule: ID=%s, SensorID=%s, SensorType=%s, Condition=%s, Threshold=%.1f, Action=%s, DeviceID=%s",
                rule.ID, rule.SensorID, rule.SensorType, rule.Condition, rule.Threshold, rule.Action, rule.DeviceID)

            if rule.SensorID != sensorID {
                log.Printf("[INFO] Skipping rule %s: SensorID mismatch (expected %s, got %s)", rule.ID, sensorID, rule.SensorID)
                continue
            }

            shouldTrigger := false
            switch rule.Condition {
            case ">":
                shouldTrigger = value > rule.Threshold
            case "<":
                shouldTrigger = value < rule.Threshold
            case "=":
                shouldTrigger = math.Abs(value-rule.Threshold) < 0.01
            default:
                log.Printf("[ERROR] Invalid condition in rule %s: %s", rule.ID, rule.Condition)
                continue
            }

            if shouldTrigger {
                log.Printf("[INFO] Automation rule triggered: ID=%s, Sensor=%s, Action=%s", rule.ID, sensorID, rule.Action)
                deviceValue := 1.0
                status := "on"
                if rule.Action == "turn_off" {
                    deviceValue = 0.0
                    status = "off"
                }

                _, err = tx.ExecContext(context.Background(), `
                    UPDATE devices
                    SET value = $1, updated_at = $2
                    WHERE id = $3
                `, deviceValue, timestamp, rule.DeviceID)
                if err != nil {
                    log.Printf("[ERROR] Error updating device %s: %v", rule.DeviceID, err)
                    continue
                }

                topic := fmt.Sprintf("hamster/control/%s/%s/%s", userID, cageID, rule.DeviceID)
                payload := map[string]interface{}{
                    "value": deviceValue,
                    "time":  timestamp.UnixMilli(),
                }
                payloadBytes, err := json.Marshal(payload)
                if err != nil {
                    log.Printf("[ERROR] Error marshaling MQTT payload: %v", err)
                    continue
                }

                token := mqttClient.Publish(topic, 1, false, payloadBytes)
                if token.Wait() && token.Error() != nil {
                    log.Printf("[ERROR] Error publishing MQTT message: %v", token.Error())
                    continue
                }

                title := fmt.Sprintf("Cage 1: Device %s Status Changed", rule.DeviceName)
                message := fmt.Sprintf("Device %s set to %s due to %s %.1f", rule.DeviceName, status, sensorType, value)
                createNotification(tx, wsHub, userID, cageID, sensorID, sensorType, message, value, "info", title, timestamp)
            } else {
                log.Printf("[INFO] Rule %s not triggered: value=%.1f, condition=%s, threshold=%.1f", rule.ID, value, rule.Condition, rule.Threshold)
            }
        }

        if !ruleFound {
            log.Printf("[INFO] No automation rules found for cageID=%s, sensorType=%s", cageID, sensorType)
        }

        return nil
    }

func handleMessage(mqttClient *MQTTClient, db *sql.DB, wsHub *websocket.Hub, msg mqtt.Message) {
    topic := msg.Topic()
    payload := msg.Payload()
    log.Printf("[INFO] Received MQTT message: topic=%s, payload=%s", topic, string(payload))

    // Kiểm tra định dạng topic
    parts := strings.Split(topic, "/")
    if len(parts) != 6 || parts[0] != "hamster" {
        log.Printf("[ERROR] Invalid topic format: %s, expected hamster/<username>/<cagename>/<type>/<id>/<dataname>", topic)
        return
    }
    username, cagename, typeStr, id, dataname := parts[1], parts[2], parts[3], parts[4], parts[5]
    log.Printf("[DEBUG] Parsed topic: username=%s, cagename=%s, type=%s, id=%s, dataname=%s", username, cagename, typeStr, id, dataname)

    // Phân tích payload
    var message MessagePayload
    if err := json.Unmarshal(payload, &message); err != nil {
        log.Printf("[ERROR] Failed to unmarshal payload: %v, payload=%s", err, string(payload))
        return
    }
    log.Printf("[DEBUG] Parsed payload: username=%s, cagename=%s, type=%s, id=%s, dataname=%s, value=%.1f, time=%d",
        message.Username, message.Cagename, message.Type, message.ID, message.Dataname, message.Value, message.Time)

    // Kiểm tra tính hợp lệ của payload
    if message.Username == "" || message.Cagename == "" || message.ID == "" || message.Dataname == "" {
        log.Printf("[ERROR] Incomplete payload: %+v", message)
        return
    }

    sensorType := dataname
    if dataname == "water-level" {
        sensorType = "water_level"
        log.Printf("[DEBUG] Normalized dataname=water-level to sensorType=water_level")
    }

    // Xử lý timestamp
    var timestamp time.Time
    if message.Time > 0 {
        timestamp = time.Unix(int64(message.Time/1000), 0)
        log.Printf("[INFO] Using MQTT timestamp: %d -> %s", message.Time, timestamp.Format(time.RFC3339))
    } else {
        log.Printf("[WARNING] Invalid or missing timestamp in payload: %d, using current time", message.Time)
        timestamp = time.Now()
    }

    // Bắt đầu giao dịch cơ sở dữ liệu
    tx, err := db.BeginTx(context.Background(), nil)
    if err != nil {
        log.Printf("[ERROR] Error starting transaction: %v", err)
        return
    }
    defer func() {
        if r := recover(); r != nil {
            log.Printf("[ERROR] Panic in handleMessage: topic=%s, err=%v", topic, r)
            tx.Rollback()
        }
    }()
    defer tx.Rollback()

    // Lấy userID và cageID
    var userID, cageID string
    err = tx.QueryRowContext(context.Background(), `
        SELECT u.id, c.id
        FROM users u
        JOIN cages c ON c.user_id = u.id
        WHERE u.username = $1 AND c.name = $2
    `, username, cagename).Scan(&userID, &cageID)
    if err != nil {
        log.Printf("[ERROR] Error fetching user/cage ID: username=%s, cagename=%s, err=%v", username, cagename, err)
        return
    }
    log.Printf("[INFO] Fetched userID=%s, cageID=%s for username=%s, cagename=%s", userID, cageID, username, cagename)

    unit := determineUnit(sensorType)

    // Xử lý tin nhắn cảm biến
    if typeStr == "sensor" {
        // Cập nhật cảm biến trong DB
        _, err = tx.ExecContext(context.Background(), `
            UPDATE sensors
            SET value = $1, unit = $2, updated_at = $3
            WHERE id = $4
        `, message.Value, unit, timestamp, id)
        if err != nil {
            log.Printf("[ERROR] Error updating sensor: id=%s, err=%v", id, err)
            return
        }
        log.Printf("[INFO] Updated sensor: id=%s, value=%.1f, unit=%s, timestamp=%s",
            id, message.Value, unit, timestamp.Format(time.RFC3339))

        // Gửi dữ liệu cảm biến qua WebSocket
        wsSensorMsg := websocket.SensorMessage{
            SensorID: sensorType,
            Values:   make(map[string]float64),
        }
        wsSensorMsg.Values[id] = message.Value

        log.Printf("[INFO] Sending WebSocket sensor data: SensorID=%s, UserID=%s, CageID=%s, Value=%.1f",
            id, userID, cageID, message.Value)
        select {
        case wsHub.Broadcast <- websocket.Message{UserID: userID, CageID: cageID, Type: "sensor", SensorData: wsSensorMsg}:
            log.Printf("[INFO] Successfully sent sensor data to WebSocket: sensorID=%s", id)
        default:
            log.Printf("[WARNING] Broadcast channel full, dropping sensor message: sensorID=%s", id)
        }

        // Kiểm tra giá trị tới hạn
        log.Printf("[INFO] Calling checkCriticalValues: sensorID=%s, sensorType=%s, value=%.1f", id, sensorType, message.Value)
        checkCriticalValues(tx, wsHub, userID, cageID, id, sensorType, message.Value, timestamp)

        // Kiểm tra quy tắc tự động hóa
        log.Printf("[INFO] Calling checkAutomationRules: sensorID=%s, sensorType=%s, value=%.1f", id, sensorType, message.Value)
        if err := checkAutomationRules(tx, wsHub, userID, cageID, id, sensorType, message.Value, timestamp, mqttClient.client, db); err != nil {
            log.Printf("[ERROR] Error checking automation rules: %v", err)
        }
    } else if typeStr == "device" {
        // Xử lý tin nhắn thiết bị
        title := fmt.Sprintf("Cage 1: Device %s Status Changed", dataname)
        messageText := fmt.Sprintf("Device %s set to %s", dataname, determineDeviceStatus(message.Value))
        log.Printf("[INFO] Creating device notification: Type=info, Title=%s, Message=%s", title, messageText)
        createNotification(tx, wsHub, userID, cageID, id, sensorType, messageText, message.Value, "info", title, timestamp)
    } else {
        log.Printf("[ERROR] Unknown message type: %s", typeStr)
        return
    }

    // Commit giao dịch
    if err := tx.Commit(); err != nil {
        log.Printf("[ERROR] Error committing transaction: %v", err)
        return
    }

    log.Printf("[INFO] Successfully processed MQTT message: topic=%s, type=%s, id=%s", topic, typeStr, id)
}

func determineUnit(sensorType string) string {
    switch sensorType {
    case "temperature":
        return "°C"
    case "humidity":
        return "%"
    case "light":
        return "lux"
    case "water_level":
        return "cm"
    default:
        return ""
    }
}

func determineDeviceStatus(value float64) string {
    if value == 0 {
        return "off"
    }
    return "on"
}

func contains(slice []string, item string) bool {
    for _, s := range slice {
        if s == item {
            return true
        }
    }
    return false
}