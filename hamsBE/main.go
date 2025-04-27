package main

import (
	"fmt"
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
	"golang.org/x/crypto/bcrypt"
)

func main() {
	gin.SetMode(gin.ReleaseMode)
	hashed, _ := bcrypt.GenerateFromPassword([]byte("admin1"), bcrypt.DefaultCost)
	fmt.Println(string(hashed))
	err := godotenv.Load()
	if err != nil {
		log.Println("Can't find .env file, using default environment variables")
	}

	// Load SQL queries
	if err := queries.LoadQueries(); err != nil {
		log.Fatal("Error loading queries:", err)
	}

	// Connect to database
	db, err := database.ConnectDB()
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.CloseDB(db)

	// Initialize WebSocket hub
	wsHub := websocket.NewHub()
	go wsHub.Run()

	// Initialize MQTT client
	mqttClient, err := mqtt.StartMQTTClientSub(
		"tcp://10.28.128.93:1883",
		"hamster/#",
		"user1",
		"cage1",
		"device",
		db,
		wsHub,
	)
	if err != nil {
		log.Fatalf("Failed to start MQTT subscription: %v", err)
	}
	defer mqttClient.Disconnect(250)

	// Existing ConnectMQTT for general subscriptions
	mainMqttClient := mqtt.ConnectMQTT(db, wsHub)
	defer mainMqttClient.Disconnect(250)
	// Set up Gin router
	r := gin.Default()

	// Configure CORS
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:8080", "http://localhost:3000"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// Health check endpoint
	r.GET("/", func(c *gin.Context) {
		port := os.Getenv("PORT")
		if port == "" {
			port = "8080"
		}
		c.JSON(200, gin.H{
			"message": "Server is running on port " + port,
		})
	})

	// Set up API routes
	api.SetupRoutes(r, db, wsHub, mqttClient)

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Println("PORT not set, defaulting to 8080")
	}

	log.Printf("Starting server on port %s...", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
