package mqtt

import (
    "database/sql"
    "encoding/json"
    "fmt"
    "log"
    "strconv"
    "strings"
    "time"

    mqtt "github.com/eclipse/paho.mqtt.golang"
    "github.com/google/uuid"
    "hamstercare/internal/websocket"
)

type MessagePayload struct {
    Username  string  `json:"username"`
    Cagename  string  `json:"cagename"`
    Type      string  `json:"type"`
    ID        int     `json:"id"`
    Dataname  string  `json:"dataname"`
    Value     string  `json:"value"` // Changed to string
    Time      int64   `json:"time"`
}

func ConnectMQTT(db *sql.DB, wsHub *websocket.Hub) mqtt.Client {
    broker := "tcp://localhost:1883"
    clientID := "hamstercare-mqtt-" + uuid.New().String()
    opts := mqtt.NewClientOptions().
        AddBroker(broker).
        SetClientID(clientID).
        SetDefaultPublishHandler(func(client mqtt.Client, msg mqtt.Message) {
            handleMessage(db, wsHub, msg)
        })

    client := mqtt.NewClient(opts)
    if token := client.Connect(); token.Wait() && token.Error() != nil {
        log.Fatalf("Error connecting to MQTT broker: %v", token.Error())
    }
    log.Println("Connected to MQTT broker")

    if token := client.Subscribe("hamster/#", 0, nil); token.Wait() && token.Error() != nil {
        log.Fatalf("Error subscribing to topic: %v", token.Error())
    }
    log.Println("Subscribed to hamster/#")
    return client
}

func handleMessage(db *sql.DB, wsHub *websocket.Hub, msg mqtt.Message) {
    topic := msg.Topic()
    payload := msg.Payload()
    log.Printf("Received payload: %s", string(payload))

    parts := strings.Split(topic, "/")
    if len(parts) != 5 || parts[0] != "hamster" {
        log.Printf("Invalid topic format: %s", topic)
        return
    }
    typeStr := parts[3]

    var message MessagePayload
    if err := json.Unmarshal(payload, &message); err != nil {
        log.Printf("Failed to unmarshal payload: %v", err)
        return
    }

    var value float64
    var err error
    if typeStr == "device" {
        // For devices, map string actions to float64 for compatibility
        switch message.Value {
        case "turn_on", "refill":
            value = 1.0
        case "turn_off", "lock":
            value = 0.0
        default:
            value, err = strconv.ParseFloat(message.Value, 64)
            if err != nil {
                log.Printf("Failed to parse device value '%s' as float64: %v", message.Value, err)
                return
            }
        }
    } else {
        value, err = strconv.ParseFloat(message.Value, 64)
        if err != nil {
            log.Printf("Failed to parse sensor value '%s' as float64: %v", message.Value, err)
            return
        }
    }

    var userID string
    err = db.QueryRow("SELECT id FROM users WHERE username = $1", message.Username).Scan(&userID)
    if err == sql.ErrNoRows {
        log.Printf("User not found: %s", message.Username)
        return
    } else if err != nil {
        log.Printf("Error querying user: %v", err)
        return
    }

    var cageID string
    err = db.QueryRow("SELECT id FROM cages WHERE name = $1 AND user_id = $2", message.Cagename, userID).Scan(&cageID)
    if err == sql.ErrNoRows {
        log.Printf("Cage not found: %s for user %s", message.Cagename, message.Username)
        return
    } else if err != nil {
        log.Printf("Error querying cage: %v", err)
        return
    }

    timestamp := time.Unix(message.Time, 0)

    if typeStr == "sensor" {
        processSensorData(db, wsHub, userID, cageID, message, value, timestamp)
    } else if typeStr == "device" {
        processDeviceData(db, wsHub, userID, cageID, message, value, timestamp)
    } else {
        log.Printf("Unknown type in topic: %s", typeStr)
    }
}

func processSensorData(db *sql.DB, wsHub *websocket.Hub, userID, cageID string, message MessagePayload, value float64, timestamp time.Time) {
    var sensorID, sensorType string
    err := db.QueryRow(`
        SELECT id, type 
        FROM sensors 
        WHERE (name = $1 OR type = $2) AND cage_id = $3`, 
        message.Dataname, message.Dataname, cageID).Scan(&sensorID, &sensorType)
    if err == sql.ErrNoRows {
        log.Printf("Sensor not found for dataname %s in cage %s", message.Dataname, cageID)
        return
    } else if err != nil {
        log.Printf("Error querying sensor: %v", err)
        return
    }

    _, err = db.Exec(`
        UPDATE sensors 
        SET value = $1, updated_at = $2 
        WHERE id = $3`, 
        value, timestamp, sensorID)
    if err != nil {
        log.Printf("Error updating sensor %s: %v", sensorID, err)
        return
    }

    checkCriticalValues(db, wsHub, userID, cageID, sensorID, sensorType, value, timestamp)
    checkAutomationRules(db, wsHub, userID, cageID, sensorID, sensorType, value, timestamp)
}

func processDeviceData(db *sql.DB, wsHub *websocket.Hub, userID, cageID string, message MessagePayload, value float64, timestamp time.Time) {
    var deviceID, deviceType string
    err := db.QueryRow(`
        SELECT id, type 
        FROM devices 
        WHERE (name = $1 OR type = $2) AND cage_id = $3`, 
        message.Dataname, message.Dataname, cageID).Scan(&deviceID, &deviceType)
    if err == sql.ErrNoRows {
        log.Printf("Device not found for dataname %s in cage %s", message.Dataname, cageID)
        return
    } else if err != nil {
        log.Printf("Error querying device: %v", err)
        return
    }

    status := "off"
    if value > 0 {
        status = "on"
    }

    _, err = db.Exec(`
        UPDATE devices 
        SET status = $1, last_status = status, updated_at = $2 
        WHERE id = $3`, 
        status, timestamp, deviceID)
    if err != nil {
        log.Printf("Error updating device %s: %v", deviceID, err)
        return
    }

    title := fmt.Sprintf("Device %s: Status changed", message.Dataname)
    messageText := fmt.Sprintf("Device %s turned %s", message.Dataname, status)
    createNotification(db, wsHub, userID, cageID, "info", title, messageText, timestamp, value)
}

func checkCriticalValues(db *sql.DB, wsHub *websocket.Hub, userID, cageID, sensorID, sensorType string, value float64, timestamp time.Time) {
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
    case "distance":
        waterLevel := (20.0 - value) / 20.0 * 100
        if waterLevel < 20.0 {
            title = "Cage: Low water level"
            message = fmt.Sprintf("Low water level detected: %.1f%%", waterLevel)
        }
    }

    if title != "" {
        createNotification(db, wsHub, userID, cageID, notificationType, title, message, timestamp, value)
    }
}

func checkAutomationRules(db *sql.DB, wsHub *websocket.Hub, userID, cageID, sensorID, sensorType string, value float64, timestamp time.Time) {
    rows, err := db.Query(`
        SELECT id, device_id, condition, threshold, action 
        FROM automation_rules 
        WHERE sensor_id = $1 AND cage_id = $2`, 
        sensorID, cageID)
    if err != nil {
        log.Printf("Error querying automation rules: %v", err)
        return
    }
    defer rows.Close()

    for rows.Next() {
        var ruleID, deviceID, condition, action string
        var threshold float64
        if err := rows.Scan(&ruleID, &deviceID, &condition, &threshold, &action); err != nil {
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
            _, err = db.Exec(`
                UPDATE devices 
                SET status = $1, last_status = status, updated_at = $2 
                WHERE id = $3`, 
                action, timestamp, deviceID)
            if err != nil {
                log.Printf("Error updating device %s: %v", deviceID, err)
                continue
            }

            title := fmt.Sprintf("Device: Action %s executed", action)
            message := fmt.Sprintf("Automation rule triggered: %s on device", action)
            createNotification(db, wsHub, userID, cageID, "info", title, message, timestamp, value)
        }
    }
}

func createNotification(db *sql.DB, wsHub *websocket.Hub, userID, cageID, notificationType, title, message string, timestamp time.Time, value ...float64) {
    notificationID := uuid.New().String()
    _, err := db.Exec(`
        INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        notificationID, userID, cageID, notificationType, title, message, false, timestamp)
    if err != nil {
        log.Printf("Error creating notification: %v", err)
        return
    }

    var notificationValue float64
    if len(value) > 0 {
        notificationValue = value[0]
    }

    wsHub.Broadcast <- websocket.Message{
        UserID:  userID,
        Type:    notificationType,
        Title:   title,
        Message: message,
        CageID:  cageID,
        Time:    timestamp.Unix(),
        Value:   notificationValue,
    }
}