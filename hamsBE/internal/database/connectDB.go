package database

import (
    "database/sql"
    "fmt"
    "log"
    "os"
    "time"

    "hamstercare/internal/model"
    "hamstercare/internal/websocket"
    "github.com/golang-migrate/migrate/v4"
    "github.com/golang-migrate/migrate/v4/database/postgres"
    _ "github.com/golang-migrate/migrate/v4/source/file"
    _ "github.com/lib/pq"
    "github.com/google/uuid"
)

var wsHub *websocket.Hub

func SetWebSocketHub(hub *websocket.Hub) {
    wsHub = hub
}

func ConnectDB() (*sql.DB, error) {
    host := os.Getenv("DB_HOST")
    if host == "" {
        host = "db"
        log.Println("DB_HOST not set, defaulting to 'db'")
    }
    port := os.Getenv("DB_PORT")
    if port == "" {
        port = "5432"
        log.Println("DB_PORT not set, defaulting to 5432")
    }
    user := os.Getenv("DB_USER")
    if user == "" {
        user = "postgres"
        log.Println("DB_USER not set, defaulting to postgres")
    }
    password := os.Getenv("DB_PASSWORD")
    if password == "" {
        password = "password"
        log.Println("DB_PASSWORD not set, defaulting to password")
    }
    dbname := os.Getenv("DB_NAME")
    if dbname == "" {
        dbname = "hamstercare"
        log.Println("DB_NAME not set, defaulting to hamstercare")
    }

    psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
        host, port, user, password, dbname)

    db, err := sql.Open("postgres", psqlInfo)
    if err != nil {
        return nil, fmt.Errorf("failed to open database connection: %v", err)
    }

    for i := 0; i < 30; i++ {
        err = db.Ping()
        if err == nil {
            break
        }
        log.Printf("Failed to ping database (attempt %d/30): %v, retrying...", i+1, err)
        time.Sleep(1 * time.Second)
    }
    if err != nil {
        return nil, fmt.Errorf("failed to ping database after retries: %v", err)
    }

    log.Println("Connected to PostgreSQL successfully!")

    err = RunMigrations(db)
    if err != nil {
        return nil, fmt.Errorf("failed to run migrations: %v", err)
    }

    return db, nil
}

func RunMigrations(db *sql.DB) error {
    driver, err := postgres.WithInstance(db, &postgres.Config{})
    if err != nil {
        return fmt.Errorf("failed to create migration driver: %v", err)
    }

    m, err := migrate.NewWithDatabaseInstance(
        "file:internal/database/migrations",
        "postgres", driver)
    if err != nil {
        return fmt.Errorf("failed to create migration instance: %v", err)
    }

    err = m.Up()
    if err == migrate.ErrNoChange {
        log.Println("No migrations to apply")
    } else if err != nil {
        return fmt.Errorf("failed to run migration: %v", err)
    } else {
        log.Println("Migrations applied successfully!")
    }
    return nil
}

func CloseDB(db *sql.DB) {
    if db != nil {
        err := db.Close()
        if err != nil {
            log.Printf("Error closing database connection: %v", err)
        } else {
            log.Println("Database connection closed successfully")
        }
    }
}

func InsertSensorData(db *sql.DB, sensor *model.Sensor) error {
    query := `
        INSERT INTO sensors (id, name, type, value, unit, cage_id)
        VALUES ($1, $2, $3, $4, $5, $6)
    `
    _, err := db.Exec(query, sensor.ID, sensor.Name, sensor.Type, sensor.Value, sensor.Unit, sensor.CageID)
    if err != nil {
        return fmt.Errorf("failed to insert sensor data: %v", err)
    }
    log.Printf("Sensor data inserted: %+v", sensor)
    return nil
}

func UpdateSensorData(db *sql.DB, sensor *model.Sensor) error {
    query := `
        UPDATE sensors
        SET value = $1, unit = $2, updated_at = CURRENT_TIMESTAMP
        WHERE id = $3 AND cage_id = $4
    `
    _, err := db.Exec(query, sensor.Value, sensor.Unit, sensor.ID, sensor.CageID)
    if err != nil {
        return fmt.Errorf("failed to update sensor data: %v", err)
    }
    log.Printf("Sensor data updated: %+v", sensor)
    return nil
}

func InsertDeviceData(db *sql.DB, device *model.Device) error {
    query := `
        INSERT INTO devices (id, name, type, status, last_status, cage_id)
        VALUES ($1, $2, $3, $4, $5, $6)
    `
    _, err := db.Exec(query, device.ID, device.Name, device.Type, device.Status, device.LastStatus, device.CageID)
    if err != nil {
        return fmt.Errorf("failed to insert device data: %v", err)
    }
    log.Printf("Device data inserted: %+v", device)
    return nil
}

func UpdateDeviceData(db *sql.DB, device *model.Device) error {
    query := `
        UPDATE devices
        SET status = $1, last_status = $2, updated_at = CURRENT_TIMESTAMP
        WHERE id = $3 AND cage_id = $4
    `
    _, err := db.Exec(query, device.Status, device.LastStatus, device.ID, device.CageID)
    if err != nil {
        return fmt.Errorf("failed to update device data: %v", err)
    }
    log.Printf("Device data updated: %+v", device)
    return nil
}

func UpdateWaterStatistic(db *sql.DB, cageID string) error {
    currentDate := time.Now().Format("2006-01-02")
    var statisticID string
    var waterRefillSl int
    var userID string

    err := db.QueryRow(`
        SELECT user_id FROM cages WHERE id = $1
    `, cageID).Scan(&userID)
    if err != nil {
        return fmt.Errorf("error fetching user_id for cage %s: %v", cageID, err)
    }

    err = db.QueryRow(`
        SELECT id, water_refill_sl FROM statistic WHERE cage_id = $1 AND created_at::date = $2
    `, cageID, currentDate).Scan(&statisticID, &waterRefillSl)

    if err == sql.ErrNoRows {
        statisticID = uuid.New().String()
        _, err = db.Exec(`
            INSERT INTO statistics (id, cage_id, water_refill_sl, created_at, updated_at)
            VALUES ($1, $2, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        `, statisticID, cageID)
        if err != nil {
            return fmt.Errorf("failed to insert water statistic: %v", err)
        }
        waterRefillSl = 1
    } else if err != nil {
        return fmt.Errorf("error checking statistic: %v", err)
    } else {
        _, err = db.Exec(`
            UPDATE statistics
            SET water_refill_sl = water_refill_sl + 1, updated_at = CURRENT_TIMESTAMP
            WHERE id = $1
        `, statisticID)
        if err != nil {
            return fmt.Errorf("failed to update water statistic: %v", err)
        }
        waterRefillSl++
    }

    // Check settings for high water usage threshold
    var threshold int
    err = db.QueryRow(`
        SELECT high_water_usage_threshold FROM settings WHERE cage_id = $1
    `, cageID).Scan(&threshold)
    if err != nil && err != sql.ErrNoRows {
        log.Printf("Error fetching high water usage threshold for cage %s: %v", cageID, err)
    }
    if err == sql.ErrNoRows {
        threshold = 10 // Default threshold
    }

    if waterRefillSl >= threshold {
        title := "High Water Usage Alert"
        message := fmt.Sprintf("High water usage detected: %d refills today", waterRefillSl)
        wsHub.Broadcast <- websocket.Message{
            UserID:  userID,
            Type:    "high_water_usage",
            Title:   title,
            Message: message,
            CageID:  cageID,
            Time:    time.Now().Unix(),
            Value:   float64(waterRefillSl),
        }

        _, err = db.Exec(`
            INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        `, uuid.New().String(), userID, cageID, "high_water_usage", title, message, false, time.Now())
        if err != nil {
            log.Printf("Error storing high water usage notification: %v", err)
        }
    }

    log.Printf("Water statistic updated for cage %s: %d refills", cageID, waterRefillSl)
    return nil
}