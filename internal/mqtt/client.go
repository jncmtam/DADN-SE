// internal/mqtt/client.go
package mqtt

import (
    mqtt "github.com/eclipse/paho.mqtt.golang"
    "log"
)

type Client struct {
    client mqtt.Client
}

func NewClient(broker, username, key string) *Client {
    opts := mqtt.NewClientOptions().
        AddBroker(broker).
        SetClientID("hamsBE").
        SetUsername(username). // Adafruit IO username
        SetPassword(key)       // Adafruit IO key

    client := mqtt.NewClient(opts)
    if token := client.Connect(); token.Wait() && token.Error() != nil {
        log.Fatalf("Error connecting to MQTT: %v", token.Error())
    }
    return &Client{client: client}
}

func (c *Client) Subscribe(topic string, handler mqtt.MessageHandler) {
    if token := c.client.Subscribe(topic, 0, handler); token.Wait() && token.Error() != nil {
        log.Printf("Error subscribing to %s: %v", topic, token.Error())
    }
}