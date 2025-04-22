package mqtt

import (
	"context"
	"encoding/json"
	"log"
	"database/sql"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

type MessagePayload struct {
	Username string 	`json:"username"`
	Cagename string 	`json:"cagename"`
	Type   	 string 	`json:"type"`
	id	     int 	    `json:"id"`
	Dataname string 	`json:"dataname"`
	Value    float64 	`json:"value"`
	Time 	 int64 		`json:"time"`
}

func MqttHandler(db *sql.DB) mqtt.MessageHandler {
	return func(client mqtt.Client, msg mqtt.Message) {
		log.Printf("Received message: %s -> %s\n", msg.Topic(), msg.Payload())


		var payload MessagePayload
		if err := json.Unmarshal(msg.Payload(), &payload); err != nil {
            log.Printf("Failed to parse JSON payload: %v", err)
            return
        }

		
		// Save the message to the database
		ctx := context.Background()
		err := SaveMessageToDB(ctx, db, payload)
		if err != nil {
			log.Printf("Database insert error: %v", err)
		} else {
			log.Println("Data saved to database successfully")
		}
	}
}
