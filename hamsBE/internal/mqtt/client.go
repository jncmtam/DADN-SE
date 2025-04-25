package mqtt

import (
	"context"
	"fmt"
	//"strings"
	"database/sql"
	//"log"
	//"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

type MQTTClient struct {
	client mqtt.Client
}



func NewMQTTClient(client mqtt.Client) *MQTTClient {
	return &MQTTClient{client: client}
}


func SaveMessageToDB(ctx context.Context, db *sql.DB, payload MessagePayload) error {
    if db == nil {
        return fmt.Errorf("Database connection is nil")
    }

    // Extract values from payload
    // userName := payload.Username
    // cageName := payload.Cagename
    // typeName := payload.Type
    // //sensorID := payload.ID
    // dataName := payload.Dataname
    // value := payload.Value
    // messageTime := payload.Time

    // // Set timestamp - use current time if not provided
    // var timestamp time.Time
    // if messageTime > 0 {
    //     timestamp = time.Unix(0, messageTime*int64(time.Millisecond))
    // } else {
    //     timestamp = time.Now()
    // }

    // Begin a transaction for data consistency
    tx, err := db.BeginTx(ctx, nil)
    if err != nil {
        return fmt.Errorf("Failed to begin transaction: %v", err)
    }
    fmt.Println("Transaction started")
    // Save into database
    // Chua biet lam gi o day
    //
    //
    //
    //
    //
    //
    
    
    // Defer a rollback in case anything fails
    defer func() {
        if err != nil {
            tx.Rollback()
        }
    }()

   
    return nil
}

// Helper function to determine unit based on sensor type
func determineUnit(sensorType string) string {
    switch sensorType {
    case "temperature":
        return "C"
    case "humidity":
        return "%"
    case "light":
        return "lux"
    case "waterlevel":
        return "mm"
    case "infrared":
        return "yes/no"
    default:
        return ""
    }
}