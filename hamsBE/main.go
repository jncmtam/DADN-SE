package main

import (
	"hamstercare/api"
	"hamstercare/internal/database"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/mqtt"
	"hamstercare/internal/websocket"
	"log"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

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

	r := gin.Default()

	// Cấu hình CORS
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:8080", "http://localhost:3000"},
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

	api.SetupRoutes(r, db)
	log.Printf("Starting server on port %s...", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
	// Initialize WebSocket hub
	wsHub := websocket.NewHub()
	go wsHub.Run()

	// Set WebSocket hub for database package
	database.SetWebSocketHub(wsHub)

	// Initialize MQTT client
	mqtt.ConnectMQTT(db, wsHub)
}
