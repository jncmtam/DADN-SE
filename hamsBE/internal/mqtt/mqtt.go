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
		broker = "tcp://172.20.10.8:1883"
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

func handleMessage(mqttClient *MQTTClient, db *sql.DB, wsHub *websocket.Hub, msg mqtt.Message) {
	topic := msg.Topic()
	payload := msg.Payload()
	log.Printf("Received payload on topic %s: %s", topic, string(payload))

	parts := strings.Split(topic, "/")
	if len(parts) != 6 || parts[0] != "hamster" {
		log.Printf("Invalid topic format: %s", topic)
		return
	}
	username, cagename, typeStr, id, dataname := parts[1], parts[2], parts[3], parts[4], parts[5]

	var message MessagePayload
	if err := json.Unmarshal(payload, &message); err != nil {
		log.Printf("Failed to unmarshal payload: %v", err)
		return
	}

	// Handle timestamp
	var timestamp time.Time
	if message.Time > 0 {
		timestamp = time.Unix(int64(message.Time/1000), 0)
		log.Printf("Using MQTT timestamp: %d -> %s", message.Time, timestamp.Format(time.RFC3339))
	} else {
		log.Printf("Invalid or missing timestamp in payload: %d, using current time", message.Time)
		timestamp = time.Now()
	}

	tx, err := db.BeginTx(context.Background(), nil)
	if err != nil {
		log.Printf("Error starting transaction: %v", err)
		return
	}
	defer tx.Rollback()

	var userID, cageID string
	err = tx.QueryRowContext(context.Background(), `
        SELECT u.id, c.id
        FROM users u
        JOIN cages c ON c.user_id = u.id
        WHERE u.username = $1 AND c.name = $2
    `, username, cagename).Scan(&userID, &cageID)
	if err != nil {
		log.Printf("Error fetching user/cage ID: %v", err)
		return
	}

	unit := determineUnit(dataname)

	if typeStr == "sensor" {
		_, err = tx.ExecContext(context.Background(), `
            UPDATE sensors
            SET value = $1, unit = $2, updated_at = $3
            WHERE id = $4
        `, message.Value, unit, timestamp, id)
		if err != nil {
			log.Printf("Error updating sensor %s: %v", id, err)
			return
		}
		if typeStr == "sensor" {
			wsSensorMsg := websocket.Message{
				UserID:   userID,
				CageID:   cageID,
				Type:     "sensor", // 💬 đây là type client đang listen
				SensorID: id,
				Unit:     unit,
				Message:  fmt.Sprintf("Sensor %s updated", dataname),
				Time:     timestamp.Unix(),
				Value:    message.Value,
				Data: map[string]interface{}{
					"sensor_id":   id,
					"sensor_type": dataname,
					"value":       message.Value,
					"timestamp":   timestamp.Unix(),
				},
			}
			select {
			case wsHub.Broadcast <- wsSensorMsg:
				log.Printf("[WebSocket] Sent sensor data to WebSocket client: %s", dataname)
			default:
				log.Printf("[WebSocket] Broadcast channel full, dropping sensor message")
			}
		}
		if dataname == "water_level" {
			log.Printf("[CHECK] Distance sensor value: %.2f cm", message.Value)
			if message.Value > 3.0 {
				log.Printf("[WATER_REFILL] Distance %.2f cm > 3.0 cm detected, counting as refill!", message.Value)

				_, err := tx.ExecContext(context.Background(), `
				INSERT INTO statistics (id, cage_id, water_refill_sl, created_at, updated_at)
				VALUES ($1, $2, $3, $4, $4)
			`, uuid.New().String(), cageID, 1, timestamp)
				if err != nil {
					log.Printf("[ERROR] Failed to insert water refill record: %v", err)
					return
				}

				// 🌟 Gọi updateWaterStatistic luôn:
				if err := updateWaterStatistic(tx, cageID, userID, wsHub, context.Background()); err != nil {
					log.Printf("[ERROR] Failed to update statistic after refill: %v", err)
				}

				log.Printf("[WATER_REFILL] Successfully recorded a water refill for cage %s", cageID)
			}

			log.Printf("Calling checkCriticalValues for sensor %s, type %s, value %.2f", id, dataname, message.Value)
			checkCriticalValues(tx, wsHub, userID, cageID, id, dataname, message.Value, timestamp)

			log.Printf("Calling checkAutomationRules for sensor %s, type %s, value %.2f", id, dataname, message.Value)
			checkAutomationRules(tx, wsHub, userID, cageID, id, dataname, message.Value, timestamp, mqttClient.client, db)
		}
	} else if typeStr == "device" {
		// Xử lý thiết bị
		var status string
		if message.Value == 0.0 {
			status = "off"
		} else if message.Value == 1.0 {
			switch dataname {
			case "lock":
				status = "locked"
			default:
				status = "on"
			}
		} else {
			log.Printf("Invalid device value: %v", message.Value)
			return
		}

		_, err = tx.ExecContext(context.Background(), `
            UPDATE devices
            SET status = $1, last_status = status, updated_at = $2
            WHERE id = $3
        `, status, timestamp, id)
		if err != nil {
			log.Printf("Error updating device %s: %v", id, err)
			return
		}

		title := fmt.Sprintf("Device %s: Status Changed", dataname)
		messageText := fmt.Sprintf("Device %s set to %s", dataname, status)
		createNotification(tx, wsHub, userID, cageID, id, dataname, "", message.Value, "notification", title, messageText, timestamp)
	}

	if err := tx.Commit(); err != nil {
		log.Printf("Error committing transaction: %v", err)
		return
	}

	log.Printf("Successfully processed MQTT message: topic=%s, type=%s, id=%s", topic, typeStr, id)
}

func SaveMessageToDB(db *sql.DB, wsHub *websocket.Hub, mqttClient mqtt.Client, payload MQTTPayload) error {
	ctx := context.Background()
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to start transaction: %v", err)
	}
	defer tx.Rollback()

	var userID, cageID string
	err = tx.QueryRowContext(ctx, `
        SELECT u.id, c.id 
        FROM users u
        JOIN cages c ON c.user_id = u.id
        WHERE u.username = $1 AND c.name = $2`,
		payload.Username, payload.CageName).Scan(&userID, &cageID)
	if err != nil {
		return fmt.Errorf("user or cage not found: %v", err)
	}

	value := payload.Value
	timestamp := time.Unix(payload.Timestamp, 0)

	switch payload.Type {
	case "sensor":
		var sensorID, sensorType string
		err = tx.QueryRowContext(ctx, `
            SELECT id, type 
            FROM sensors 
            WHERE id = $1 AND cage_id = $2`,
			payload.ID, cageID).Scan(&sensorID, &sensorType)
		if err != nil {
			return fmt.Errorf("sensor not found for id %s in cage %s: %v", payload.ID, cageID, err)
		}

		_, err = tx.ExecContext(ctx, `
            UPDATE sensors 
            SET value = $1, updated_at = $2 
            WHERE id = $3`,
			value, timestamp, sensorID)
		if err != nil {
			return fmt.Errorf("failed to update sensor data: %v", err)
		}
		checkCriticalValues(tx, wsHub, userID, cageID, sensorID, sensorType, value, timestamp)
		checkAutomationRules(tx, wsHub, userID, cageID, sensorID, sensorType, value, timestamp, mqttClient, db)

	case "device":
		// Kiểm tra và cập nhật trạng thái thiết bị
		newStatus := "off"
		if payload.Value == 1.0 {
			switch payload.DataName {
			case "lock":
				newStatus = "locked"
			default:
				newStatus = "on"
			}
		}

		// Cập nhật trạng thái thiết bị trong bảng devices
		_, err = tx.ExecContext(ctx, `
            UPDATE devices
            SET status = $1, last_status = status, updated_at = $2
            WHERE id = $3 AND cage_id = $4`,
			newStatus, timestamp, payload.ID, cageID)
		if err != nil {
			return fmt.Errorf("failed to update device status: %v", err)
		}

		// Gửi thông báo qua WebSocket
		deviceName := payload.DataName
		title := fmt.Sprintf("Device %s: Action %s executed", deviceName, newStatus)
		message := fmt.Sprintf("Device %s set to %s", deviceName, newStatus)
		createNotification(tx, wsHub, userID, cageID, "", "", "", payload.Value, "info", title, message, timestamp)

		// Xử lý logic đặc biệt cho bơm
		if payload.DataName == "pump" {
			if payload.Value == 1.0 {
				// Khi bơm được bật, tự động tắt sau 2 giây và cập nhật thống kê nước
				go func() {
					time.Sleep(2 * time.Second)
					newTx, err := db.BeginTx(context.Background(), nil)
					if err != nil {
						log.Printf("Error starting transaction for pump turn_off: %v", err)
						return
					}
					defer newTx.Rollback()

					// Tắt bơm
					_, err = newTx.ExecContext(context.Background(), `
                        UPDATE devices 
                        SET status = 'off', last_status = 'on', updated_at = $1 
                        WHERE id = $2
                    `, time.Now(), payload.ID)
					if err != nil {
						log.Printf("Error turning off pump %s: %v", payload.ID, err)
						return
					}

					// Gửi message MQTT để thông báo bơm tắt
					topic := fmt.Sprintf("hamster/%s/%s/device/%s/%s", payload.Username, payload.CageName, payload.ID, payload.DataName)
					mqttPayload := map[string]interface{}{
						"username": payload.Username,
						"cagename": payload.CageName,
						"type":     "device",
						"id":       payload.ID,
						"dataname": payload.DataName,
						"value":    0.0,
						"time":     time.Now().Unix(),
					}
					payloadBytes, err := json.Marshal(mqttPayload)
					if err != nil {
						log.Printf("Error marshaling MQTT payload: %v", err)
						return
					}
					if token := mqttClient.Publish(topic, 0, false, payloadBytes); token.Wait() && token.Error() != nil {
						log.Printf("Error publishing pump turn_off: %v", token.Error())
					}

					// Gửi thông báo qua WebSocket
					title := "Device: Pump stopped"
					message := "Pump turned off after 2-second refill"
					createNotification(newTx, wsHub, userID, cageID, "", "", "", 0.0, "info", title, message, time.Now())

					// Cập nhật thống kê nước
					if err := updateWaterStatistic(newTx, cageID, userID, wsHub, context.Background()); err != nil {
						log.Printf("Error updating water statistic: %v", err)
					}

					if err := newTx.Commit(); err != nil {
						log.Printf("Error committing pump turn_off transaction: %v", err)
					}
				}()
			}
		}
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %v", err)
	}
	return nil
}

func checkCriticalValues(tx *sql.Tx, wsHub *websocket.Hub, userID, cageID, sensorID, sensorType string, value float64, timestamp time.Time) {
	var title, message, unit string
	notificationType := "notification"

	log.Printf("Checking critical values: sensorType=%s, sensorID=%s, value=%.1f", sensorType, sensorID, value)
	switch sensorType {
	case "temperature":
		unit = "°C"
		if value < 16.0 {
			title = "Cage: Low Temperature Alert"
			message = fmt.Sprintf("Low temperature detected: %.1f°C. Please check the cage environment.", value)
		} else if value > 30.0 {
			title = "Cage: High Temperature Alert"
			message = fmt.Sprintf("High temperature detected: %.1f°C. Please check the cage environment.", value)
		}
	case "humidity":
		unit = "%"
		if value > 80.0 {
			title = "Cage: High Humidity Alert"
			message = fmt.Sprintf("High humidity detected: %.1f%%. Consider improving ventilation.", value)
		}
	case "light":
		unit = "lux"
		if value > 1000.0 {
			title = "Cage: High Light Intensity Alert"
			message = fmt.Sprintf("High light intensity detected: %.1f lux. Consider reducing light exposure.", value)
			log.Printf("Light threshold exceeded: %s - %s", title, message)
		}
	case "distance":
		unit = "cm"
		waterLevel := (20.0 - value) / 20.0 * 100
		if waterLevel < 20.0 {
			title = "Cage: Low Water Level Alert"
			message = fmt.Sprintf("Low water level detected: %.1f%%. Please refill the water.", waterLevel)
		}
	}

	if title != "" {
		log.Printf("Creating notification: Type=%s, Title=%s, Message=%s", notificationType, title, message)
		createNotification(tx, wsHub, userID, cageID, sensorID, sensorType, unit, value, notificationType, title, message, timestamp)
	}
}

func checkAutomationRules(tx *sql.Tx, wsHub *websocket.Hub, userID, cageID, sensorID, sensorType string, value float64, timestamp time.Time, mqttClient mqtt.Client, db *sql.DB) error {
	log.Printf("Checking automation rules: cageID=%s, sensorType=%s, sensorID=%s, value=%.1f", cageID, sensorType, sensorID, value)

	// Validate sensorType against allowed enum values
	validSensorTypes := []string{"temperature", "humidity", "light", "water_level"}
	if !contains(validSensorTypes, sensorType) {
		log.Printf("Invalid sensor type: %s", sensorType)
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
		log.Printf("Error querying automation rules: %v", err)
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
			log.Printf("Error scanning automation rule: %v", err)
			continue
		}

		if rule.SensorID != sensorID {
			log.Printf("Skipping rule %s: SensorID mismatch (expected %s, got %s)", rule.ID, sensorID, rule.SensorID)
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
			log.Printf("Invalid condition in rule %s: %s", rule.ID, rule.Condition)
			continue
		}

		if shouldTrigger {
			log.Printf("Automation rule triggered: ID=%s, Sensor=%s, Action=%s", rule.ID, sensorID, rule.Action)

			// Validate action based on device type
			validActions := map[string][]string{
				"fan":   {"turn_on", "turn_off"},
				"light": {"turn_on", "turn_off"},
				"pump":  {"refill"},
				"lock":  {"lock"},
			}
			allowedActions, ok := validActions[rule.DeviceType]
			if !ok || !contains(allowedActions, rule.Action) {
				log.Printf("Invalid action %s for device type %s in rule %s", rule.Action, rule.DeviceType, rule.ID)
				continue
			}

			// Map action to device status
			actionToStatus := map[string]string{
				"turn_on":  "on",
				"turn_off": "off",
				"refill":   "on",
				"lock":     "locked",
			}
			newStatus := actionToStatus[rule.Action]

			// Update device status
			_, err = tx.ExecContext(context.Background(), `
                UPDATE devices
                SET status = $1, last_status = status, updated_at = $2
                WHERE id = $3
            `, newStatus, timestamp, rule.DeviceID)
			if err != nil {
				log.Printf("Error updating device %s: %v", rule.DeviceID, err)
				return fmt.Errorf("failed to update device %s: %w", rule.DeviceID, err)
			}

			// Get username and cagename for MQTT
			var username, cagename string
			err = tx.QueryRowContext(context.Background(), `
                SELECT u.username, c.name
                FROM users u
                JOIN cages c ON c.user_id = u.id
                WHERE c.id = $1
            `, cageID).Scan(&username, &cagename)
			if err != nil {
				log.Printf("Error fetching username and cagename: %v", err)
				return fmt.Errorf("failed to fetch username and cagename: %w", err)
			}

			// Publish MQTT message
			topic := fmt.Sprintf("hamster/%s/%s/device/%s/%s", username, cagename, rule.DeviceID, rule.DeviceName)
			payload := map[string]interface{}{
				"username": username,
				"cagename": cagename,
				"type":     "device",
				"id":       rule.DeviceID,
				"dataname": rule.DeviceName,
				"value":    rule.Action,
				"time":     timestamp.Unix() * 1000,
			}
			payloadBytes, err := json.Marshal(payload)
			if err != nil {
				log.Printf("Error marshaling MQTT payload: %v", err)
				return fmt.Errorf("failed to marshal MQTT payload: %w", err)
			}
			if token := mqttClient.Publish(topic, 0, false, payloadBytes); token.Wait() && token.Error() != nil {
				log.Printf("Error publishing MQTT message: %v", token.Error())
			} else {
				log.Printf("Published MQTT message: topic=%s, payload=%s", topic, string(payloadBytes))
			}

			// Send device_status_change WebSocket event
			title := fmt.Sprintf("Device %s: Automation Triggered", rule.DeviceName)
			message := fmt.Sprintf("Device %s set to %s due to %s %.1f", rule.DeviceName, newStatus, sensorType, value)
			wsMsg := websocket.Message{
				UserID:   userID,
				Type:     "device_status_change",
				Title:    title,
				Message:  message,
				CageID:   cageID,
				SensorID: sensorID,
				Unit:     determineUnit(sensorType),
				Time:     timestamp.Unix(),
				Value:    value,
				Data: map[string]interface{}{
					"device_id":   rule.DeviceID,
					"device_name": rule.DeviceName,
					"action":      rule.Action,
					"sensor_type": sensorType,
					"value":       value,
					"timestamp":   timestamp.Unix(),
				},
			}
			select {
			case wsHub.Broadcast <- wsMsg:
				log.Printf("Sent device_status_change WebSocket notification: %s", message)
			default:
				log.Printf("WebSocket broadcast channel full, dropping notification: %s", message)
			}

			// Store notification
			_, err = tx.ExecContext(context.Background(), `
                INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            `, uuid.New().String(), userID, cageID, "device_status_change", title, message, false, timestamp)
			if err != nil {
				log.Printf("Error storing notification: %v", err)
				return fmt.Errorf("failed to store notification: %w", err)
			}

			// Handle pump auto-off
			if rule.DeviceType == "pump" && rule.Action == "refill" {
				go func() {
					time.Sleep(2 * time.Second)
					newTx, err := db.BeginTx(context.Background(), nil)
					if err != nil {
						log.Printf("Error starting transaction for pump turn_off: %v", err)
						return
					}
					defer newTx.Rollback()

					_, err = newTx.ExecContext(context.Background(), `
                        UPDATE devices 
                        SET status = 'off', last_status = 'on', updated_at = $1 
                        WHERE id = $2
                    `, time.Now(), rule.DeviceID)
					if err != nil {
						log.Printf("Error turning off pump %s: %v", rule.DeviceID, err)
						return
					}

					topic := fmt.Sprintf("hamster/%s/%s/device/%s/%s", username, cagename, rule.DeviceID, rule.DeviceName)
					payload := map[string]interface{}{
						"username": username,
						"cagename": cagename,
						"type":     "device",
						"id":       rule.DeviceID,
						"dataname": rule.DeviceName,
						"value":    "turn_off",
						"time":     time.Now().Unix() * 1000,
					}
					payloadBytes, _ := json.Marshal(payload)
					if token := mqttClient.Publish(topic, 0, false, payloadBytes); token.Wait() && token.Error() != nil {
						log.Printf("Error publishing pump turn_off: %v", token.Error())
					}

					title := "Device: Pump Stopped"
					message := "Pump turned off after 2-second refill"
					wsMsg := websocket.Message{
						UserID:  userID,
						Type:    "info",
						Title:   title,
						Message: message,
						CageID:  cageID,
						Time:    time.Now().Unix(),
						Value:   0.0,
					}
					select {
					case wsHub.Broadcast <- wsMsg:
						log.Printf("Sent WebSocket notification: %s", message)
					default:
						log.Printf("WebSocket broadcast channel full, dropping notification: %s", message)
					}

					_, err = newTx.ExecContext(context.Background(), `
                        INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
                        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                    `, uuid.New().String(), userID, cageID, "info", title, message, false, time.Now())
					if err != nil {
						log.Printf("Error storing notification: %v", err)
					}

					if err := newTx.Commit(); err != nil {
						log.Printf("Error committing pump turn_off transaction: %v", err)
					}
				}()
			}
		}
	}

	if !ruleFound {
		log.Printf("No automation rules found for cageID=%s, sensorType=%s", cageID, sensorType)
	}

	return nil
}

func createNotification(tx *sql.Tx, wsHub *websocket.Hub, userID, cageID, sensorID, sensorType, unit string, value float64, notificationType, title, message string, timestamp time.Time) {
	notificationID := uuid.New().String()
	log.Printf("Storing notification in DB: ID=%s, Type=%s, Title=%s, Message=%s, UserID=%s, CageID=%s",
		notificationID, notificationType, title, message, userID, cageID)
	_, err := tx.ExecContext(context.Background(), `
        INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
		notificationID, userID, cageID, notificationType, title, message, false, timestamp)
	if err != nil {
		log.Printf("Error storing notification in DB: %v", err)
		return
	}

	wsMessage := websocket.Message{
		UserID:   userID,
		Type:     notificationType,
		Title:    title,
		SensorID: sensorID,
		Unit:     unit,
		Message:  message,
		CageID:   cageID,
		Time:     timestamp.Unix(),
		Value:    value,
		Data: map[string]interface{}{
			"id":        sensorID,
			"type":      sensorType,
			"value":     value,
			"unit":      unit,
			"timestamp": timestamp.Unix(),
		},
	}

	log.Printf("Sending WebSocket notification: Type=%s, Title=%s, Message=%s, UserID=%s, CageID=%s",
		notificationType, title, message, userID, cageID)
	select {
	case wsHub.Broadcast <- wsMessage:
		log.Printf("Successfully sent WebSocket notification: Type=%s, Title=%s", notificationType, title)
	default:
		log.Printf("Warning: WebSocket broadcast channel full, dropping notification: Type=%s, Title=%s", notificationType, title)
	}
}

// Helper function to check if a slice contains a string
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
func updateWaterStatistic(tx *sql.Tx, cageID, userID string, wsHub *websocket.Hub, ctx context.Context) error {
	log.Printf("[STATISTIC] Updating water statistic for cageID=%s", cageID)

	// Đếm tổng số lần refill trong ngày hôm nay
	var totalRefills int
	err := tx.QueryRowContext(ctx, `
        SELECT COALESCE(SUM(water_refill_sl), 0)
        FROM water_refills
        WHERE cage_id = $1 AND created_at::date = CURRENT_DATE
    `, cageID).Scan(&totalRefills)
	if err != nil {
		return fmt.Errorf("[STATISTIC] Failed to sum water_refill_sl: %w", err)
	}

	log.Printf("[STATISTIC] Total refills today: %d", totalRefills)

	// Update hoặc Insert vào bảng statistic
	_, err = tx.ExecContext(ctx, `
        INSERT INTO statistic (cage_id, water_refill_sl, created_at, updated_at)
        VALUES ($1, $2, NOW(), NOW())
        ON CONFLICT (cage_id, created_at::date)
        DO UPDATE SET water_refill_sl = $2, updated_at = NOW()
    `, cageID, totalRefills)
	if err != nil {
		return fmt.Errorf("[STATISTIC] Failed to update statistic table: %w", err)
	}

	// Gửi notification WebSocket (nếu thích)
	title := "Cage: Water Usage Updated"
	messageText := fmt.Sprintf("Today's water usage updated: %d refills.", totalRefills)
	wsMsg := websocket.Message{
		UserID:  userID,
		CageID:  cageID,
		Type:    "notification",
		Title:   title,
		Message: messageText,
		Time:    time.Now().Unix(),
		Value:   float64(totalRefills),
	}
	select {
	case wsHub.Broadcast <- wsMsg:
		log.Printf("[WebSocket] Sent statistic update message: %s", messageText)
	default:
		log.Printf("[WebSocket] Broadcast channel full, dropping statistic message")
	}

	return nil
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
