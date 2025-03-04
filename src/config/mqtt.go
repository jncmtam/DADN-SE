package config

import (
	"fmt"
	mqtt "github.com/eclipse/paho.mqtt.golang"
	"os"
)

var MQTT_CLIENT mqtt.Client

func ConnectMQTT() {
	broker := os.Getenv("MQTT_BROKER")
	opts := mqtt.NewClientOptions().AddBroker(broker)
	client := mqtt.NewClient(opts)

	if token := client.Connect(); token.Wait() && token.Error() != nil {
		panic(token.Error())
	}
	MQTT_CLIENT = client
	fmt.Println("Connected to MQTT Broker")
}
