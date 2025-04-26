package mqtt

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/google/uuid"
	"hamstercare/internal/websocket"
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

func DefaultTopics() TopicConfig {
	return TopicConfig{
		Temperature: "sensor/temperature",
		Humidity:    "sensor/humidity",
		Light:       "sensor/light",
		WaterLevel:  "sensor/water-level",
		Fan:         "device/fan",
		LED:         "device/led",
		Pump:        "device/pump",
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
	Value    string   `json:"value"`
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
	if broker == "" {
		broker = "tcp://localhost:1883"
	}
	if !strings.HasPrefix(broker, "tcp://") && !strings.HasPrefix(broker, "ssl://") && !strings.HasPrefix(broker, "ws://") {
		broker = "tcp://" + broker
	}

	clientID := "hamstercare-mqtt-" + uuid.New().String()
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
			log.Println("Connected to MQTT broker")
			if token := client.Subscribe("hamster/#", 0, nil); token.Wait() && token.Error() != nil {
				log.Fatalf("Error subscribing to topic hamster/#: %v", token.Error())
			}
			log.Println("Subscribed to hamster/#")
			topicConfig := DefaultTopics()
			for _, topic := range topicConfig.GetAllTopics() {
				topic = "hamster/user1/cage1/" + topic
				if token := client.Subscribe(topic, 0, nil); token.Wait() && token.Error() != nil {
					log.Printf("Error subscribing to topic %s: %v", topic, token.Error())
				} else {
					log.Printf("Subscribed to topic: %s", topic)
				}
			}
		}).
		SetConnectionLostHandler(func(client mqtt.Client, err error) {
			log.Printf("Connection lost: %v", err)
		})

	client := mqtt.NewClient(opts)
	mqttClient.client = client
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("Error connecting to MQTT broker: %v", token.Error())
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
	clientID := "hamstercare-sub-" + uuid.New().String()
	if !strings.HasPrefix(broker, "tcp://") && !strings.HasPrefix(broker, "ssl://") && !strings.HasPrefix(broker, "ws://") {
		broker = "tcp://" + broker
	}

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
			fullTopic := topic
			if topic != "hamster/#" {
				fullTopic = fmt.Sprintf("hamster/%s/%s/%s/#", username, cagename, typename)
			}
			if token := client.Subscribe(fullTopic, 0, nil); token.Wait() && token.Error() != nil {
				log.Printf("❌ Error subscribing to topic %s: %v", fullTopic, token.Error())
			} else {
				log.Printf("📡 Subscribed to topic: %s", fullTopic)
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

	payload := map[string]interface{}{
		"username": username,
		"cagename": cagename,
		"type":     typename,
		"id":       id,
		"dataname": dataname,
		"value":    value,
		"time":     time.Now().Unix(),
	}

	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("error marshalling JSON: %v", err)
	}

	topic = fmt.Sprintf("hamster/%s/%s/%s", username, cagename, topic)
	if token := client.Publish(topic, 0, false, jsonPayload); token.Wait() && token.Error() != nil {
		return fmt.Errorf("error publishing message: %v", token.Error())
	}
	log.Printf("Published message to topic %s: %s", topic, jsonPayload)
	return nil
}

func handleMessage(mqttClient *MQTTClient, db *sql.DB, wsHub *websocket.Hub, msg mqtt.Message) {
	topic := msg.Topic()
	payload := msg.Payload()
	log.Printf("Received payload: %s", string(payload))

	parts := strings.Split(topic, "/")
	if len(parts) < 4 || parts[0] != "hamster" {
		log.Printf("Invalid topic format: %s", topic)
		return
	}
	username, cagename := parts[1], parts[2]
	typeStr := parts[3]
	dataname := parts[len(parts)-1]

	var message MessagePayload
	if err := json.Unmarshal(payload, &message); err != nil {
		log.Printf("Failed to unmarshal payload: %v", err)
		return
	}

	if message.Username != username || message.Cagename != cagename || message.Type != typeStr {
		log.Printf("Payload mismatch: username=%s, cagename=%s, type=%s, expected %s/%s/%s",
			message.Username, message.Cagename, message.Type, username, cagename, typeStr)
		return
	}

	var value float64
	var status string
	if typeStr == "device" {
		switch message.Value {
		case "turn_on":
			status = "on"
			value = 1.0
		case "turn_off":
			status = "off"
			value = 0.0
		case "refill":
			status = "on"
			value = 1.0
		case "lock":
			status = "locked"
			value = 0.0
		default:
			parsedValue, err := strconv.ParseFloat(message.Value, 64)
			if err != nil {
				log.Printf("Failed to parse device value '%s' as float64: %v", message.Value, err)
				return
			}
			value = parsedValue
			status = "off"
			if value > 0 {
				status = "on"
			}
		}
	} else {
		var err error
		value, err = strconv.ParseFloat(message.Value, 64)
		if err != nil {
			log.Printf("Failed to parse sensor value '%s' as float64: %v", message.Value, err)
			return
		}
	}

	ctx := context.Background()
	if err := SaveMessageToDB(ctx, db, wsHub, mqttClient.client, message, value, status, dataname); err != nil {
		log.Printf("Failed to save message to DB: %v", err)
		return
	}
}

func SaveMessageToDB(ctx context.Context, db *sql.DB, wsHub *websocket.Hub, mqttClient mqtt.Client, payload MessagePayload, value float64, status, dataname string) error {
	if db == nil {
		return fmt.Errorf("database connection is nil")
	}

	userName := payload.Username
	cageName := payload.Cagename
	typeName := payload.Type
	timestamp := time.Unix(int64(payload.Time), 0)

	log.Printf("Processing data: User=%s, Cage=%s, Type=%s, Data=%s, Value=%s",
		userName, cageName, typeName, dataname, payload.Value)

	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %v", err)
	}
	defer func() {
		if err != nil {
			_ = tx.Rollback()
		}
	}()

	var userID string
	err = tx.QueryRowContext(ctx, `SELECT id FROM users WHERE username = $1`, userName).Scan(&userID)
	if err != nil {
		return fmt.Errorf("user not found: %v", err)
	}

	var cageID string
	err = tx.QueryRowContext(ctx, `SELECT id FROM cages WHERE name = $1 AND user_id = $2`, cageName, userID).Scan(&cageID)
	if err != nil {
		return fmt.Errorf("cage '%s' not found for user '%s': %v", cageName, userName, err)
	}

	switch typeName {
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
		unit := determineUnit(sensorType)
		wsHub.Broadcast <- websocket.Message{
			UserID:  userID,
			Type:    "sensor_data",
			Title:   fmt.Sprintf("Sensor %s Update", sensorType),
			Message: fmt.Sprintf("%s: %.1f%s", sensorType, value, unit),
			CageID:  cageID,
			Time:    timestamp.Unix(),
			Value:   value,
		}

		checkCriticalValues(tx, wsHub, userID, cageID, sensorID, sensorType, value, timestamp)
		checkAutomationRules(tx, wsHub, userID, cageID, sensorID, sensorType, value, timestamp, mqttClient, db)

	case "device":
		var deviceID, deviceType string
		err = tx.QueryRowContext(ctx, `
            SELECT id, type 
            FROM devices 
            WHERE id = $1 AND cage_id = $2`,
			payload.ID, cageID).Scan(&deviceID, &deviceType)
		if err != nil {
			return fmt.Errorf("device not found for id %s in cage %s: %v", payload.ID, cageID, err)
		}

		_, err = tx.ExecContext(ctx, `
            UPDATE devices 
            SET status = $1, last_status = status, updated_at = $2 
            WHERE id = $3`,
			status, timestamp, deviceID)
		if err != nil {
			return fmt.Errorf("failed to update device data: %v", err)
		}

		title := fmt.Sprintf("Device %s: Status changed", dataname)
		message := fmt.Sprintf("Device %s set to %s", dataname, status)
		createNotification(tx, wsHub, userID, cageID, "info", title, message, timestamp)

		if deviceType == "pump" && payload.Value == "refill" {
			if err := updateWaterStatistic(tx, cageID, userID, wsHub); err != nil {
				log.Printf("Failed to update water statistic: %v", err)
			}
		}
	default:
		return fmt.Errorf("unknown type: %s", typeName)
	}

	if err = tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %v", err)
	}

	log.Println("Data successfully updated in the database")
	return nil
}

func checkCriticalValues(tx *sql.Tx, wsHub *websocket.Hub, userID, cageID, sensorID, sensorType string, value float64, timestamp time.Time) {
	var title, message string
	notificationType := "warning"

	switch sensorType {
	case "temperature":
		if value < 15.0 {
			title = "Cage: Low temperature"
			message = fmt.Sprintf("Low temperature detected: %.1f°C", value)
		} else if value > 30.0 {
			title = "Cage: High temperature"
			message = fmt.Sprintf("High temperature detected: %.1f°C", value)
		}
	case "humidity":
		if value > 80.0 {
			title = "Cage: High humidity"
			message = fmt.Sprintf("High humidity detected: %.1f%%", value)
		}
	case "light":
		if value > 1000.0 {
			title = "Cage: High light intensity"
			message = fmt.Sprintf("High light intensity detected: %.1f lux", value)
		}
	case "water-level", "distance":
		waterLevel := (20.0 - value) / 20.0 * 100
		if waterLevel < 20.0 {
			title = "Cage: Low water level"
			message = fmt.Sprintf("Low water level detected: %.1f%%", waterLevel)
		}
	}

	if title != "" {
		createNotification(tx, wsHub, userID, cageID, notificationType, title, message, timestamp)
	}
}

func checkAutomationRules(tx *sql.Tx, wsHub *websocket.Hub, userID, cageID, sensorID, sensorType string, value float64, timestamp time.Time, mqttClient mqtt.Client, db *sql.DB) {
	rows, err := tx.QueryContext(context.Background(), `
        SELECT id, device_id, condition, threshold, action, d.type
        FROM automation_rules ar
        JOIN devices d ON ar.device_id = d.id
        WHERE sensor_id = $1 AND cage_id = $2
    `, sensorID, cageID)
	if err != nil {
		log.Printf("Error querying automation rules: %v", err)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var ruleID, deviceID, condition, action, deviceType string
		var threshold float64
		if err := rows.Scan(&ruleID, &deviceID, &condition, &threshold, &action, &deviceType); err != nil {
			log.Printf("Error scanning rule: %v", err)
			continue
		}

		triggered := false
		switch condition {
		case ">":
			triggered = value > threshold
		case "<":
			triggered = value < threshold
		case "=":
			triggered = value == threshold
		}

		if triggered {
			status := ""
			switch action {
			case "turn_on", "refill":
				status = "on"
			case "turn_off":
				status = "off"
			case "lock":
				status = "locked"
			}
			_, err = tx.ExecContext(context.Background(), `
                UPDATE devices 
                SET status = $1, last_status = status, updated_at = $2 
                WHERE id = $3
            `, status, timestamp, deviceID)
			if err != nil {
				log.Printf("Error updating device %s: %v", deviceID, err)
				continue
			}

			title := fmt.Sprintf("Device: Action %s executed", action)
			message := fmt.Sprintf("Automation rule triggered: %s on device", action)
			createNotification(tx, wsHub, userID, cageID, "info", title, message, timestamp)

			if action == "refill" && deviceType == "pump" {
				go func() {
					time.Sleep(2 * time.Second)
					newTx, err := db.BeginTx(context.Background(), nil)
					if err != nil {
						log.Printf("Error starting transaction for turn_off: %v", err)
						return
					}
					defer newTx.Rollback()

					_, err = newTx.ExecContext(context.Background(), `
                        UPDATE devices 
                        SET status = 'off', last_status = 'on', updated_at = $1 
                        WHERE id = $2
                    `, time.Now(), deviceID)
					if err != nil {
						log.Printf("Error turning off device %s: %v", deviceID, err)
						return
					}

					var username, cagename, deviceName string
					err = newTx.QueryRowContext(context.Background(), `
                        SELECT u.username, c.name, d.name
                        FROM users u
                        JOIN cages c ON c.user_id = u.id
                        JOIN devices d ON d.cage_id = c.id
                        WHERE d.id = $1
                    `, deviceID).Scan(&username, &cagename, &deviceName)
					if err != nil {
						log.Printf("Error fetching MQTT details: %v", err)
						return
					}

					topic := fmt.Sprintf("hamster/%s/%s/device/%s", username, cagename, deviceName)
					payload := map[string]interface{}{
						"username": username,
						"cagename": cagename,
						"type":     "device",
						"id":       deviceID,
						"dataname": deviceName,
						"value":    "turn_off",
						"time":     time.Now().Unix(),
					}
					payloadBytes, _ := json.Marshal(payload)
					if token := mqttClient.Publish(topic, 0, false, payloadBytes); token.Wait() && token.Error() != nil {
						log.Printf("Error publishing turn_off message: %v", token.Error())
					}

					title := "Device: Pump stopped"
					message := "Pump turned off after 2-second refill"
					createNotification(newTx, wsHub, userID, cageID, "info", title, message, time.Now())

					if err := newTx.Commit(); err != nil {
						log.Printf("Error committing turn_off transaction: %v", err)
					}
				}()
			}
		}
	}
}

func createNotification(tx *sql.Tx, wsHub *websocket.Hub, userID, cageID, notificationType, title, message string, timestamp time.Time) {
	notificationID := uuid.New().String()
	_, err := tx.ExecContext(context.Background(), `
        INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
		notificationID, userID, cageID, notificationType, title, message, false, timestamp)
	if err != nil {
		log.Printf("Error creating notification: %v", err)
		return
	}

	wsHub.Broadcast <- websocket.Message{
		UserID:  userID,
		Type:    notificationType,
		Title:   title,
		Message: message,
		CageID:  cageID,
		Time:    timestamp.Unix(),
		Value:   0.0,
	}
}

func updateWaterStatistic(tx *sql.Tx, cageID, userID string, wsHub *websocket.Hub) error {
	currentDate := time.Now().Format("2006-01-02")
	var statisticID string
	var waterRefillSl int

	err := tx.QueryRowContext(context.Background(), `
        SELECT id, water_refill_sl FROM statistic WHERE cage_id = $1 AND created_at::date = $2
    `, cageID, currentDate).Scan(&statisticID, &waterRefillSl)
	if err == sql.ErrNoRows {
		statisticID = uuid.New().String()
		waterRefillSl = 1
		_, err = tx.ExecContext(context.Background(), `
            INSERT INTO statistic (id, cage_id, water_refill_sl, created_at, updated_at)
            VALUES ($1, $2, $3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        `, statisticID, cageID, waterRefillSl)
	} else if err == nil {
		waterRefillSl++
		_, err = tx.ExecContext(context.Background(), `
            UPDATE statistic
            SET water_refill_sl = $1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $2
        `, waterRefillSl, statisticID)
	}
	if err != nil {
		return fmt.Errorf("failed to update water statistic: %v", err)
	}

	var threshold int
	err = tx.QueryRowContext(context.Background(), `
        SELECT high_water_usage_threshold FROM settings WHERE cage_id = $1
    `, cageID).Scan(&threshold)
	if err == sql.ErrNoRows {
		threshold = 10
	} else if err != nil {
		log.Printf("Error fetching threshold: %v", err)
	}

	if waterRefillSl >= threshold {
		title := "High Water Usage Alert"
		message := fmt.Sprintf("High water usage: %d refills (2s each) today", waterRefillSl)
		wsHub.Broadcast <- websocket.Message{
			UserID:  userID,
			Type:    "high_water_usage",
			Title:   title,
			Message: message,
			CageID:  cageID,
			Time:    time.Now().Unix(),
			Value:   float64(waterRefillSl),
		}
		_, err = tx.ExecContext(context.Background(), `
            INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        `, uuid.New().String(), userID, cageID, "high_water_usage", title, message, false, time.Now())
		if err != nil {
			log.Printf("Error storing notification: %v", err)
		}
	}

	log.Printf("Water statistic updated for cage %s: %d refills (2s each)", cageID, waterRefillSl)
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
	case "water-level", "distance":
		return "cm"
	default:
		return ""
	}
}