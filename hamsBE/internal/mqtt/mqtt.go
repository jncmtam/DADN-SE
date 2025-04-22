package mqtt

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
	"hamstercare/internal/service"
	"log"
	"strings"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

func Init(db *sql.DB) *MQTTClient {
	broker := "tcp://localhost:1883"
	clientID := "hamstercare-backend"

	// Init repositories
	automationRepo := repository.NewAutomationRepository(db)
	deviceRepo := repository.NewDeviceRepository(db)
	statisticRepo := repository.NewStatisticRepository(db)

	// Init service
	cageRepo := repository.NewCageRepository(db)
	userRepo := repository.NewUserRepository(db)
	cageService := service.NewCageService(cageRepo, userRepo)

	// Init MQTT client
	mqttClient := NewMQTTClient(broker, clientID, automationRepo, deviceRepo, statisticRepo, cageService)

	// Connect to MQTT
	if err := mqttClient.Connect(); err != nil {
		log.Fatalf("[MQTT] Connection failed: %v", err)
	}

	// Subscribe to sensor topics
	if err := mqttClient.SubscribeSensors(); err != nil {
		log.Fatalf("[MQTT] Subscription failed: %v", err)
	}

	return mqttClient
}

// MQTTClient manages MQTT connections
type MQTTClient struct {
	client         mqtt.Client
	automationRepo *repository.AutomationRepository
	deviceRepo     *repository.DeviceRepository
	statisticRepo  *repository.StatisticRepository
	cageService    *service.CageService
}

// NewMQTTClient creates a new MQTTClient
func NewMQTTClient(broker, clientID string, automationRepo *repository.AutomationRepository, deviceRepo *repository.DeviceRepository, statisticRepo *repository.StatisticRepository, cageService *service.CageService) *MQTTClient {
	opts := mqtt.NewClientOptions().
		AddBroker(broker).
		SetClientID(clientID).
		SetOnConnectHandler(func(client mqtt.Client) {
			log.Println("[MQTT] ✅ Connected to broker")
		}).
		SetConnectionLostHandler(func(client mqtt.Client, err error) {
			log.Printf("[MQTT] ❌ Connection lost: %v\n", err)
		}).
		SetReconnectingHandler(func(client mqtt.Client, opts *mqtt.ClientOptions) {
			log.Println("[MQTT] 🔄 Reconnecting...")
		})

	client := mqtt.NewClient(opts)
	return &MQTTClient{client, automationRepo, deviceRepo, statisticRepo, cageService}
}

// Connect establishes the MQTT connection
func (m *MQTTClient) Connect() error {
	if token := m.client.Connect(); token.Wait() && token.Error() != nil {
		return token.Error()
	}
	return nil
}

// SubscribeSensors subscribes to sensor topics
func (m *MQTTClient) SubscribeSensors() error {
	topic := "hamster/+/+/sensor/+/+"
	token := m.client.Subscribe(topic, 0, func(client mqtt.Client, msg mqtt.Message) {
		// Parse topic: hamster/:userID/:cageID/sensor/:sensorID/:sensorType
		parts := splitTopic(msg.Topic())
		if len(parts) != 6 {
			log.Printf("[ERROR] Invalid sensor topic: %s", msg.Topic())
			return
		}
		userID, cageID, sensorID, sensorType := parts[1], parts[2], parts[4], parts[5]

		var value float64
		if err := json.Unmarshal(msg.Payload(), &value); err != nil {
			log.Printf("[ERROR] Invalid sensor payload: %v", err)
			return
		}

		// Calculate water level for distance sensor
		if sensorType == "distance" {
			// Assume bottle height (d) is 10cm (configurable)
			d := 10.0
			d1 := value
			waterLeft := (d - d1) / d * 100
			if waterLeft >= 10 && waterLeft <= 90 {
				// Store in sensor_data
				unit := "%"
				conditionMet := fmt.Sprintf("water_level=%v%%", waterLeft)
				data := &model.SensorData{
					SensorID:     sensorID,
					Value:        waterLeft,
					Unit:         unit,
					ConditionMet: conditionMet,
				}
				if err := m.statisticRepo.InsertSensorData(context.Background(), data); err != nil {
					log.Printf("[ERROR] Failed to store sensor data: %v", err)
				}
			}
			value = waterLeft
		}

		// Check automation rules
		rules, err := m.automationRepo.GetRulesBySensorID(context.Background(), sensorID)
		if err != nil {
			log.Printf("[ERROR] Failed to fetch automation rules: %v", err)
			return
		}

		for _, rule := range rules {
			if evaluateCondition(value, rule.Condition, rule.Threshold) {
				// Update device status
				if err := m.deviceRepo.UpdateDeviceStatus(context.Background(), rule.DeviceID, rule.Action); err != nil {
					log.Printf("[ERROR] Failed to update device %s: %v", rule.DeviceID, err)
					continue
				}
				// Publish device command
				deviceTopic := fmt.Sprintf("hamster/%s/%s/device/%s/command", userID, cageID, rule.DeviceID)
				m.client.Publish(deviceTopic, 0, false, rule.Action)
			}
		}
	})
	token.Wait()
	return token.Error()
}

// evaluateCondition checks if a sensor value meets a rule's condition
func evaluateCondition(value float64, condition string, threshold float64) bool {
	switch condition {
	case ">":
		return value > threshold
	case "<":
		return value < threshold
	case "=":
		return value == threshold
	case ">=":
		return value >= threshold
	case "<=":
		return value <= threshold
	}
	return false
}

// splitTopic splits an MQTT topic into parts
func splitTopic(topic string) []string {
	return strings.Split(topic, "/")
}

// PublishDeviceCommand publishes a device command
func (m *MQTTClient) PublishDeviceCommand(userID, cageID, deviceID, command string) {
	topic := fmt.Sprintf("hamster/%s/%s/device/%s/command", userID, cageID, deviceID)
	m.client.Publish(topic, 0, false, command)
}
