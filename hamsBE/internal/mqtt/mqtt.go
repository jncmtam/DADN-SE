package mqtt

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"time"

	"hamstercare/internal/database"
	"hamstercare/internal/model"

	"github.com/eclipse/paho.mqtt.golang"
)

var db *sql.DB
var client mqtt.Client

// ConnectMQTT connects to the MQTT broker
func ConnectMQTT(database *sql.DB) mqtt.Client {
	db = database
	opts := mqtt.NewClientOptions()
	opts.AddBroker("tcp://localhost:1883")
	opts.SetClientID("go_mqtt_client")
	opts.SetKeepAlive(60 * time.Second)
	opts.SetPingTimeout(1 * time.Second)
	opts.OnConnect = func(c mqtt.Client) {
		log.Println("Connected to MQTT broker")
		SubscribeToMQTT(c)
		go checkScheduleRules() // Start schedule rule checker
	}

	client = mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatalf("Error connecting to MQTT broker: %v", token.Error())
	}
	return client
}

// SensorData represents sensor data from MQTT
type SensorData struct {
	SensorID   string  `json:"sensor_id"`
	SensorType string  `json:"sensor_type"`
	Value      float64 `json:"value"`
	Timestamp  string  `json:"timestamp"`
}

// DeviceData represents device data from MQTT
type DeviceData struct {
	DeviceID   string `json:"device_id"`
	DeviceType string `json:"device_type"`
	Value      string `json:"value"` // status
	Timestamp  string `json:"timestamp"`
}

// MQTTHandler processes incoming MQTT messages
func MQTTHandler(client mqtt.Client, msg mqtt.Message) {
	// Parse topic: hamster/{user_id}/{cage_id}/{type}/{id}
	topicParts := strings.Split(msg.Topic(), "/")
	if len(topicParts) != 5 || topicParts[0] != "hamster" {
		log.Printf("Invalid topic format: %s", msg.Topic())
		return
	}
	userID, cageID, msgType, id := topicParts[1], topicParts[2], topicParts[3], topicParts[4]

	// Parse JSON payload
	var payload map[string]interface{}
	if err := json.Unmarshal(msg.Payload(), &payload); err != nil {
		log.Printf("Error parsing payload: %v", err)
		return
	}

	// Validate cage_id and user_id
	var validCageID string
	err := db.QueryRow(`
		SELECT id FROM cages WHERE id = $1 AND user_id = $2
	`, cageID, userID).Scan(&validCageID)
	if err == sql.ErrNoRows {
		log.Printf("Invalid cage_id %s or user_id %s", cageID, userID)
		return
	} else if err != nil {
		log.Printf("Error validating cage: %v", err)
		return
	}

	if msgType == "sensor" {
		sensorData, ok := parseSensorData(payload, id)
		if !ok {
			log.Printf("Invalid sensor payload: %v", payload)
			return
		}
		if err := processSensorData(sensorData, cageID, userID); err != nil {
			log.Printf("Error processing sensor data: %v", err)
		}
	} else if msgType == "device" {
		deviceData, ok := parseDeviceData(payload, id)
		if !ok {
			log.Printf("Invalid device payload: %v", payload)
			return
		}
		if err := processDeviceData(deviceData, cageID, userID); err != nil {
			log.Printf("Error processing device data: %v", err)
		}
	}
}

// parseSensorData extracts sensor data from payload
func parseSensorData(payload map[string]interface{}, sensorID string) (SensorData, bool) {
	sensor := SensorData{SensorID: sensorID}
	if id, ok := payload["sensor_id"].(string); !ok || id != sensorID {
		return sensor, false
	}
	if sensorType, ok := payload["sensor_type"].(string); ok {
		sensor.SensorType = sensorType
	} else {
		return sensor, false
	}
	if value, ok := payload["value"].(float64); ok {
		sensor.Value = value
	} else {
		return sensor, false
	}
	if ts, ok := payload["timestamp"].(string); ok {
		sensor.Timestamp = ts
	} else {
		sensor.Timestamp = time.Now().Format(time.RFC3339)
	}
	return sensor, true
}

// parseDeviceData extracts device data from payload
func parseDeviceData(payload map[string]interface{}, deviceID string) (DeviceData, bool) {
	device := DeviceData{DeviceID: deviceID}
	if id, ok := payload["device_id"].(string); !ok || id != deviceID {
		return device, false
	}
	if deviceType, ok := payload["device_type"].(string); ok {
		device.DeviceType = deviceType
	} else {
		return device, false
	}
	if value, ok := payload["value"].(string); ok {
		device.Value = value
	} else {
		return device, false
	}
	if ts, ok := payload["timestamp"].(string); ok {
		device.Timestamp = ts
	} else {
		device.Timestamp = time.Now().Format(time.RFC3339)
	}
	return device, true
}

// processSensorData saves sensor data and checks automation rules
func processSensorData(sensor SensorData, cageID, userID string) error {
	// Check if sensor exists
	var existingSensorID string
	err := db.QueryRow(`
		SELECT id FROM sensors WHERE id = $1 AND cage_id = $2
	`, sensor.SensorID, cageID).Scan(&existingSensorID)

	sensorModel := &model.Sensor{
		ID:        sensor.SensorID,
		Name:      sensor.SensorID, // Use ID as name if not provided
		Type:      sensor.SensorType,
		Value:     sensor.Value,
		Unit:      getSensorUnit(sensor.SensorType),
		CageID:    cageID,
		CreatedAt: time.Now(),
	}

	if err == sql.ErrNoRows {
		// Insert new sensor
		if err := database.InsertSensorData(db, sensorModel); err != nil {
			return fmt.Errorf("error inserting sensor: %v", err)
		}
	} else if err != nil {
		return fmt.Errorf("error checking sensor: %v", err)
	} else {
		// Update existing sensor
		if err := database.UpdateSensorData(db, sensorModel); err != nil {
			return fmt.Errorf("error updating sensor: %v", err)
		}
	}

	// Check automation rules
	return checkAutomationRules(sensor, cageID, userID)
}

// processDeviceData saves device data
func processDeviceData(device DeviceData, cageID, userID string) error {
	// Check if device exists
	var existingDeviceID string
	err := db.QueryRow(`
		SELECT id FROM devices WHERE id = $1 AND cage_id = $2
	`, device.DeviceID, cageID).Scan(&existingDeviceID)

	// Validate device status
	validStatuses := map[string]bool{
		"on":    true,
		"off":   true,
		"auto":  true,
		"refill": true, // Allow refill for pumps
	}
	if !validStatuses[device.Value] {
		return fmt.Errorf("invalid device status: %s", device.Value)
	}

	// For pumps, map "refill" to "on" for status
	status := device.Value
	if device.Value == "refill" && device.DeviceType == "pump" {
		status = "on"
	}

	deviceModel := &model.Device{
		ID:         device.DeviceID,
		Name:       device.DeviceID, // Use ID as name if not provided
		Type:       device.DeviceType,
		Status:     status,
		LastStatus: status,
		CageID:     cageID,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}

	if err == sql.ErrNoRows {
		// Insert new device
		if err := database.InsertDeviceData(db, deviceModel); err != nil {
			return fmt.Errorf("error inserting device: %v", err)
		}
	} else if err != nil {
		return fmt.Errorf("error checking device: %v", err)
	} else {
		// Update existing device
		if err := database.UpdateDeviceData(db, deviceModel); err != nil {
			return fmt.Errorf("error updating device: %v", err)
		}
	}

	// Update water statistics for refill
	if device.Value == "refill" && device.DeviceType == "pump" {
		if err := database.UpdateWaterStatistic(db, cageID); err != nil {
			log.Printf("Error updating water statistic: %v", err)
		}
	}

	return nil
}

// getSensorUnit returns the unit for a sensor type
func getSensorUnit(sensorType string) string {
	switch sensorType {
	case "temperature":
		return "°C"
	case "humidity":
		return "%"
	case "light":
		return "lux"
	case "distance":
		return "cm"
	case "infrared":
		return ""
	default:
		return "unknown"
	}
}

// checkAutomationRules evaluates automation rules for sensor data
func checkAutomationRules(sensor SensorData, cageID, userID string) error {
	rows, err := db.Query(`
		SELECT id, sensor_id, device_id, condition, threshold, action, unit, cage_id
		FROM automation_rules
		WHERE sensor_id = $1 AND cage_id = $2
	`, sensor.SensorID, cageID)
	if err != nil {
		return fmt.Errorf("error querying automation rules: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var rule model.AutomationRule
		if err := rows.Scan(&rule.ID, &rule.SensorID, &rule.DeviceID, &rule.Condition, &rule.Threshold, &rule.Action, &rule.Unit, &rule.CageID); err != nil {
			log.Printf("Error scanning automation rule: %v", err)
			continue
		}

		// Validate unit
		if rule.Unit != getSensorUnit(sensor.SensorType) {
			log.Printf("Unit mismatch for sensor %s: rule unit %s, sensor unit %s", sensor.SensorID, rule.Unit, getSensorUnit(sensor.SensorType))
			continue
		}

		// Evaluate condition
		trigger := false
		switch rule.Condition {
		case ">":
			trigger = sensor.Value > rule.Threshold
		case "<":
			trigger = sensor.Value < rule.Threshold
		case "=":
			trigger = sensor.Value == rule.Threshold
		}

		if trigger {
			// Update device status
			newStatus := rule.Action
			if rule.Action == "refill" {
				newStatus = "on" // Refill sets pump to "on" temporarily
			}
			_, err = db.Exec(`
				UPDATE devices
				SET status = $1, last_status = status, updated_at = $2
				WHERE id = $3 AND cage_id = $4
			`, newStatus, time.Now().Format(time.RFC3339), rule.DeviceID, cageID)
			if err != nil {
				log.Printf("Error updating device %s: %v", rule.DeviceID, err)
			}

			// Update water statistics for refill
			if rule.Action == "refill" {
				if err := database.UpdateWaterStatistic(db, cageID); err != nil {
					log.Printf("Error updating water statistic: %v", err)
				}
			}

			// Publish action to MQTT
			topic := fmt.Sprintf("hamster/%s/%s/device/%s", userID, cageID, rule.DeviceID)
			payload := map[string]interface{}{
				"device_id":   rule.DeviceID,
				"device_type": "unknown", // Fetch actual type if needed
				"value":       rule.Action,
				"timestamp":   time.Now().Format(time.RFC3339),
			}
			if payloadBytes, err := json.Marshal(payload); err == nil {
				client.Publish(topic, 0, false, payloadBytes)
				log.Printf("Published to %s: %s", topic, string(payloadBytes))
			} else {
				log.Printf("Error marshaling payload: %v", err)
			}
		}
	}
	return nil
}

// checkScheduleRules periodically checks schedule rules
func checkScheduleRules() {
	for {
		now := time.Now()
		currentTime := now.Format("15:04")
		currentDay := strings.ToLower(now.Weekday().String()[:3])

		rows, err := db.Query(`
			SELECT id, device_id, execution_time, days, action, cage_id
			FROM schedule_rules
			WHERE execution_time = $1
		`, currentTime)
		if err != nil {
			log.Printf("Error querying schedule rules: %v", err)
			time.Sleep(1 * time.Minute)
			continue
		}

		for rows.Next() {
			var rule model.ScheduleRule
			var cageID string
			if err := rows.Scan(&rule.ID, &rule.DeviceID, &rule.ExecutionTime, &rule.Days, &rule.Action, &cageID); err != nil {
				log.Printf("Error scanning schedule rule: %v", err)
				continue
			}

			// Check if current day is in rule's days
			for _, day := range rule.Days {
				if day == currentDay {
					// Get user_id for MQTT topic
					var userID string
					err := db.QueryRow(`
						SELECT user_id FROM cages WHERE id = $1
					`, cageID).Scan(&userID)
					if err != nil {
						log.Printf("Error fetching user_id for cage %s: %v", cageID, err)
						continue
					}

					// Update device status
					newStatus := rule.Action
					if rule.Action == "refill" {
						newStatus = "on"
					}
					_, err = db.Exec(`
						UPDATE devices
						SET status = $1, last_status = status, updated_at = $2
						WHERE id = $3 AND cage_id = $4
					`, newStatus, time.Now().Format(time.RFC3339), rule.DeviceID, cageID)
					if err != nil {
						log.Printf("Error updating device %s: %v", rule.DeviceID, err)
					}

					// Update water statistics for refill
					if rule.Action == "refill" {
						if err := database.UpdateWaterStatistic(db, cageID); err != nil {
							log.Printf("Error updating water statistic: %v", err)
						}
					}

					// Publish action to MQTT
					topic := fmt.Sprintf("hamster/%s/%s/device/%s", userID, cageID, rule.DeviceID)
					payload := map[string]interface{}{
						"device_id":   rule.DeviceID,
						"device_type": "unknown",
						"value":       rule.Action,
						"timestamp":   time.Now().Format(time.RFC3339),
					}
					if payloadBytes, err := json.Marshal(payload); err == nil {
						client.Publish(topic, 0, false, payloadBytes)
						log.Printf("Published to %s: %s", topic, string(payloadBytes))
					} else {
						log.Printf("Error marshaling payload: %v", err)
					}
				}
			}
		}
		rows.Close()
		time.Sleep(1 * time.Minute) // Check every minute
	}
}

// SubscribeToMQTT subscribes to MQTT topics
func SubscribeToMQTT(client mqtt.Client) {
	topics := []string{
		"hamster/+/+/sensor/+",
		"hamster/+/+/device/+",
	}
	for _, topic := range topics {
		token := client.Subscribe(topic, 0, MQTTHandler)
		if token.Wait() && token.Error() != nil {
			log.Fatalf("Error subscribing to topic %s: %v", topic, token.Error())
		}
		log.Printf("Subscribed to topic: %s", topic)
	}
}