package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
)

func ConnectDB() (*sql.DB, error) {
	host := os.Getenv("DB_HOST")
	if host == "" {
		host = "db" // Dùng tên service 'db' trong Docker Compose
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
		log.Println("DB_PASSWORD not set, defaulting to hamster")
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

	// Thử ping với retry để đợi database sẵn sàng
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