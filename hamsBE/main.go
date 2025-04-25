package main

import (
	"dacnpm/be_mqtt/DADN-SE/hamsBE/api"
	"dacnpm/be_mqtt/DADN-SE/hamsBE/internal/database"
	"dacnpm/be_mqtt/DADN-SE/hamsBE/internal/database/queries"
	"dacnpm/be_mqtt/DADN-SE/hamsBE/internal/mqtt"
	"database/sql"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

// readAndExecuteSQL reads SQL files from the specified directory and executes them
func readAndExecuteSQL(db *sql.DB, sqlDir string) error {
	files, err := ioutil.ReadDir(sqlDir)
	if err != nil {
		return err
	}

	for _, file := range files {
		if !file.IsDir() && strings.HasSuffix(file.Name(), ".sql") {
			sqlFilePath := filepath.Join(sqlDir, file.Name())
			log.Printf("Executing SQL file: %s", sqlFilePath)
			
			sqlBytes, err := ioutil.ReadFile(sqlFilePath)
			if err != nil {
				return err
			}
			
			sqlContent := string(sqlBytes)
			_, err = db.Exec(sqlContent)
			if err != nil {
				log.Printf("Error executing SQL file %s: %v", sqlFilePath, err)
				// Continue with other files even if this one fails
				continue
			}
			
			log.Printf("SQL file executed successfully: %s", sqlFilePath)
		}
	}
	
	return nil
}

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Println("Can't find .env file, using default environment variables")
	}

	// Tải các truy vấn SQL
    if err := queries.LoadQueries(); err != nil {
        log.Fatal("Error loading queries:", err)
    }

	db, err := database.ConnectDB()
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.CloseDB(db)
	
	// Read and execute SQL files from the sql directory
	sqlDir := os.Getenv("SQL_DIR")
	if sqlDir == "" {
		sqlDir = "./sql" // Default SQL directory if not specified
	}
	
	if err := readAndExecuteSQL(db, sqlDir); err != nil {
		log.Printf("Warning: Could not execute SQL scripts: %v", err)
		// Continue execution even if SQL scripts fail
	}

	r := gin.Default()

	// Cấu hình CORS
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:8080","http://localhost:3000"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))
	// Check xem server có đang chạy không
	r.GET("/", func(c *gin.Context) {
		port := "8080"
		c.JSON(200, gin.H{
			"message": "Server is running on port " + port,
		})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Println("PORT not set, defaulting to 8080")
	}

	go mqtt.StartMQTTClientSub(db, "localhost:1883")

	api.SetupRoutes(r, db)
	log.Printf("Starting server on port %s...", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
