package mqtt

import (
	"context"
	"fmt"
	"strings"
	"database/sql"
	"log"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

type MQTTClient struct {
	client mqtt.Client
}


type MessagePayload struct {
	Username string 	`json:"username"`
	Cagename string 	`json:"cagename"`
	Type   	 string 	`json:"type"`
	ID	     int 	    `json:"id"`
	Dataname string 	`json:"dataname"`
	Value    float64 	`json:"value"`
	Time 	 int64 		`json:"time"`
}

func NewMQTTClient(client mqtt.Client) *MQTTClient {
	return &MQTTClient{client: client}
}


func SaveMessageToDB(ctx context.Context, db *sql.DB, payload MessagePayload) error {
    if db == nil {
        return fmt.Errorf("❌ database connection is nil")
    }

    // Extract values from payload
    userName := payload.Username
    cageName := payload.Cagename
    typeName := payload.Type
    sensorID := payload.ID
    dataName := payload.Dataname
    value := payload.Value
    messageTime := payload.Time

    // Set timestamp - use current time if not provided
    var timestamp time.Time
    if messageTime > 0 {
        timestamp = time.Unix(0, messageTime*int64(time.Millisecond))
    } else {
        timestamp = time.Now()
    }

    // Begin a transaction for data consistency
    tx, err := db.BeginTx(ctx, nil)
    if err != nil {
        return fmt.Errorf("❌ failed to begin transaction: %v", err)
    }
    
    // Defer a rollback in case anything fails
    defer func() {
        if err != nil {
            tx.Rollback()
        }
    }()

    // 1. Find or create user
    var userID string
    err = tx.QueryRowContext(ctx,
        "SELECT id FROM users WHERE name = $1", userName).Scan(&userID)
    
    if err != nil {
        // User doesn't exist, create a new one
        err = tx.QueryRowContext(ctx,
            `INSERT INTO users (id, name, email, password, role, created_at, updated_at) 
             VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6) RETURNING id`,
            userName, userName+"@example.com", "password", "user", timestamp, timestamp).Scan(&userID)
        
        if err != nil {
            return fmt.Errorf("❌ failed to create user: %v", err)
        }
        log.Printf("👤 Created new user: %s (%s)", userName, userID)
    }

    // 2. Find or create cage
    var cageID string
    err = tx.QueryRowContext(ctx,
        "SELECT id FROM cages WHERE name = $1 AND user_id = $2",
        cageName, userID).Scan(&cageID)
    
    if err != nil {
        // Cage doesn't exist, create a new one
        err = tx.QueryRowContext(ctx,
            `INSERT INTO cages (id, name, user_id, status, created_at, updated_at) 
             VALUES (gen_random_uuid(), $1, $2, $3, $4, $5) RETURNING id`,
            cageName, userID, "on", timestamp, timestamp).Scan(&cageID)
        
        if err != nil {
            return fmt.Errorf("❌ failed to create cage: %v", err)
        }
        log.Printf("🏠 Created new cage: %s (%s)", cageName, cageID)
    }

    // 3. Determine if it's a sensor or device based on dataName
    if strings.Contains("device", typeName) {
        // It's a device
        // Check if the device exists
        var deviceID string
        err = tx.QueryRowContext(ctx,
            "SELECT id FROM devices WHERE type = $1 AND cage_id = $2",
            dataName, cageID).Scan(&deviceID)
        
        if err != nil {
            // Device doesn't exist, create a new one
            deviceStatus := "off"
            if value > 0 {
                deviceStatus = "on"
            }
            
            err = tx.QueryRowContext(ctx,
                `INSERT INTO devices (id, name, type, status, last_status, cage_id, created_at, updated_at) 
                 VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7) RETURNING id`,
                dataName, dataName, deviceStatus, deviceStatus, cageID, timestamp, timestamp).Scan(&deviceID)
            
            if err != nil {
                return fmt.Errorf("❌ failed to create device: %v", err)
            }
            log.Printf("🔌 Created new device: %s for cage %s", dataName, cageName)
        } else {
            // Update existing device
            deviceStatus := "off"
            if value > 0 {
                deviceStatus = "on"
            }
            
            _, err = tx.ExecContext(ctx,
                `UPDATE devices SET status = $1, updated_at = $2 
                 WHERE id = $3`,
                deviceStatus, timestamp, deviceID)
            
            if err != nil {
                return fmt.Errorf("❌ failed to update device: %v", err)
            }
            log.Printf("🔌 Updated device %s status to %s", dataName, deviceStatus)
        }
    } else {
        // It's a sensor
        // Valid sensor types from ERD: temperature, humidity, light, distance, weight
        sensorType := dataName
        
        // Determine unit based on sensor type
        unit := determineUnit(sensorType)
        
        // Check if sensor exists
        var sensorDBID string
        err = tx.QueryRowContext(ctx,
            "SELECT id FROM sensors WHERE type = $1 AND cage_id = $2",
            sensorType, cageID).Scan(&sensorDBID)
        
        if err != nil {
            // Sensor doesn't exist, create it
            err = tx.QueryRowContext(ctx,
                `INSERT INTO sensors (id, name, type, value, unit, cage_id, created_at) 
                 VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6) RETURNING id`,
                sensorType, sensorType, value, unit, cageID, timestamp).Scan(&sensorDBID)
            
            if err != nil {
                return fmt.Errorf("❌ failed to create sensor: %v", err)
            }
            log.Printf("📊 Created new sensor: %s = %.2f %s", sensorType, value, unit)
        } else {
            // Update existing sensor
            _, err = tx.ExecContext(ctx,
                "UPDATE sensors SET value = $1, updated_at = $2 WHERE id = $3",
                value, timestamp, sensorDBID)
            
            if err != nil {
                return fmt.Errorf("❌ failed to update sensor: %v", err)
            }
            log.Printf("📊 Updated sensor %s to %.2f %s", sensorType, value, unit)
        }
    }

    // Commit the transaction
    if err = tx.Commit(); err != nil {
        return fmt.Errorf("❌ failed to commit transaction: %v", err)
    }

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