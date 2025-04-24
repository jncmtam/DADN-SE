package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	"hamstercare/internal/model"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
)

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
		dbname = "hamster"
		log.Println("DB_NAME not set, defaulting to hamster")
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
	if err != nil && err != migrate.ErrNoChange {
		return fmt.Errorf("failed to run migration: %v", err)
	}
	log.Println("Migrations ran successfully!")
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

// InsertSensorData inserts a new sensor record
func InsertSensorData(db *sql.DB, sensor *model.Sensor) error {
	query := `
		INSERT INTO sensors (id, name, type, value, unit, cage_id, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err := db.Exec(query, sensor.ID, sensor.Name, sensor.Type, sensor.Value, sensor.Unit, sensor.CageID, sensor.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to insert sensor data: %v", err)
	}
	log.Printf("Sensor data inserted: %+v", sensor)
	return nil
}

// UpdateSensorData updates an existing sensor record
func UpdateSensorData(db *sql.DB, sensor *model.Sensor) error {
	query := `
		UPDATE sensors
		SET value = $1, unit = $2, updated_at = $3
		WHERE id = $4 AND cage_id = $5
	`
	_, err := db.Exec(query, sensor.Value, sensor.Unit, time.Now(), sensor.ID, sensor.CageID)
	if err != nil {
		return fmt.Errorf("failed to update sensor data: %v", err)
	}
	log.Printf("Sensor data updated: %+v", sensor)
	return nil
}

// InsertDeviceData inserts a new device record
func InsertDeviceData(db *sql.DB, device *model.Device) error {
	query := `
		INSERT INTO devices (id, name, type, status, last_status, cage_id, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err := db.Exec(query, device.ID, device.Name, device.Type, device.Status, device.LastStatus, device.CageID, device.CreatedAt, device.UpdatedAt)
	if err != nil {
		return fmt.Errorf("failed to insert device data: %v", err)
	}
	log.Printf("Device data inserted: %+v", device)
	return nil
}

// UpdateDeviceData updates an existing device record
func UpdateDeviceData(db *sql.DB, device *model.Device) error {
	query := `
		UPDATE devices
		SET status = $1, last_status = $2, updated_at = $3
		WHERE id = $4 AND cage_id = $5
	`
	_, err := db.Exec(query, device.Status, device.LastStatus, time.Now(), device.ID, device.CageID)
	if err != nil {
		return fmt.Errorf("failed to update device data: %v", err)
	}
	log.Printf("Device data updated: %+v", device)
	return nil
}

// UpdateWaterStatistic increments water_refill_sl for a cage
func UpdateWaterStatistic(db *sql.DB, cageID string) error {
	currentDate := time.Now().Format("2006-01-02")
	var statisticID string
	err := db.QueryRow(`
		SELECT id FROM statistic WHERE cage_id = $1 AND created_at::date = $2
	`, cageID, currentDate).Scan(&statisticID)

	if err == sql.ErrNoRows {
		_, err = db.Exec(`
			INSERT INTO statistic (cage_id, water_refill_sl, created_at)
			VALUES ($1, 1, $2)
		`, cageID, currentDate)
		if err != nil {
			return fmt.Errorf("failed to insert water statistic: %v", err)
		}
	} else if err != nil {
		return fmt.Errorf("error checking statistic: %v", err)
	} else {
		_, err = db.Exec(`
			UPDATE statistic
			SET water_refill_sl = water_refill_sl + 1
			WHERE id = $1
		`, statisticID)
		if err != nil {
			return fmt.Errorf("failed to update water statistic: %v", err)
		}
	}
	log.Printf("Water statistic updated for cage %s", cageID)
	return nil
}
