package mqtt

import (
	"fmt"
	"os"
	"log"
	"time"
	"os/signal"
	"syscall"
	"database/sql"
	"encoding/json"
	"github.com/eclipse/paho.mqtt.golang"
)

type TopicConfig struct {
	Temperature string
	Humidity    string
	Light       string
	WaterLevel  string
	Infrared   	string
	Fan		 	string
	LED 	 	string
	Pump		string
}

func DefaultTopics() TopicConfig {
	return TopicConfig{
		Temperature: "sensor/1/temperature",
		Humidity:    "sensor/2/humidity",
		Light:       "sensor/3/light",
		WaterLevel:  "sensor/4/waterlevel",
		Infrared:    "sensor/5/infrared",
		Fan:         "device/1/fan",
		LED:         "device/2/led",
		Pump:        "device/3/pump",
	}
}

func (tc *TopicConfig) GetAllTopics() []string {
	return []string{
		tc.Temperature,
		tc.Humidity,
		tc.Light,
		tc.WaterLevel,
		tc.Infrared,
		tc.Fan,
		tc.LED,
		tc.Pump,
	}
}

func StartMQTTClientSub(db *sql.DB, broker string) {
	topic := DefaultTopics()

	opts := mqtt.NewClientOptions()
	opts.AddBroker(broker)
	opts.SetClientID("go_mqtt_client")
    opts.SetUsername("user@123")  // Thay bằng username thật
    opts.SetPassword("user@123")  // Thay bằng password thật
	opts.OnConnect = func(client mqtt.Client) {
		fmt.Println("Connected to MQTT broker")
		
		for _, topic := range topic.GetAllTopics() {
			
			topic = "hamster/user1/cage1" + topic 
			if token := client.Subscribe(topic, 1, MqttHandler(db)); token.Wait() && token.Error() != nil {
                fmt.Printf("Error subscribing to topic %s: %v\n", topic, token.Error())
            } else {
                fmt.Printf("Subscribed to topic: %s\n", topic)
            }
		}
	}
	opts.OnConnectionLost = func(client mqtt.Client, err error) {
		fmt.Println("Connection lost: ", err)
	}
	client := mqtt.NewClient(opts)
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		log.Fatal("Error connecting to MQTT broker: ", token.Error())
	}

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	fmt.Println("Disconnecting from MQTT broker")
	client.Disconnect(250)
	fmt.Println("Disconnected from MQTT broker")
}

// func StartMQTTClientPub(broker string, topic string, value int, typename string, id int, dataname string)  {
// 	opts := mqtt.NewClientOptions()
// 	opts.AddBroker (broker)
// 	opts.SetClientID("go_mqtt_client")
// 	opts.SetUsername("user@123") // Thay
// 	opts.SetPassword("user@123")// Thay
// 	client := mqtt.NewClient(opts)
// 	if token := client.Connect(); token.Wait() && token.Error() != nil {
// 		log.Fatal("Error connecting to MQTT broker: ", token.Error())
// 	}
// 	defer client.Disconnect(250)

// 	payload := map[string]interface{}  {
// 		"username": "userl",
// 		"cagename": "cage1",
// 		"type": typename,
// 		"id": id,
// 		"dataname": dataname,
// 		"value": value,
// 		"time": time.Now().UnixNano() / int64(time.Millisecond),
// 	}

// 	jsonPayload, err := json.Marshal(payload)
// 	if err != nil {
// 		log.Fatal("Error marshalling JSON: ", err)
// 	}
	
// 	if token := client.Publish(topic, 0, false, jsonPayload); token.Wait() && token.Error() != nil {
// 		log.Fatal("Error publishing message: ", token.Error())
// 	} else {
// 		fmt.Printf("Published message to topic %s: %s\n", topic, jsonPayload)
// 	}
// }

func StartMQTTClientPub(broker string, topic string, value int, typename string, id int, dataname string) error {
	opts := mqtt.NewClientOptions()
	opts.AddBroker(broker)
	opts.SetClientID("go_mqtt_client")
	opts.SetUsername("user@123") // Thay
	opts.SetPassword("user@123") // Thay
	client := mqtt.NewClient(opts)

	// Kết nối với broker
	if token := client.Connect(); token.Wait() && token.Error() != nil {
		return fmt.Errorf("error connecting to MQTT broker: %v", token.Error())
	}
	defer client.Disconnect(250)

	// Chuẩn bị payload
	payload := map[string]interface{}{
		"username": "userl",
		"cagename": "cage1",
		"type":     typename,
		"id":       id,
		"dataname": dataname,
		"value":    value,
		"time":     time.Now().UnixNano() / int64(time.Millisecond),
	}

	// Marshalling payload thành JSON
	jsonPayload, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("error marshalling JSON: %v", err)
	}

	// Publish message đến topic
	if token := client.Publish(topic, 0, false, jsonPayload); token.Wait() && token.Error() != nil {
		return fmt.Errorf("error publishing message: %v", token.Error())
	} else {
		fmt.Printf("Published message to topic %s: %s\n", topic, jsonPayload)
	}

	return nil
}
