package main

import (
	"hamstercare/api"
	"hamstercare/internal/database"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/mqtt"
	"hamstercare/internal/repository"
	"hamstercare/internal/websocket"
	"log"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("Can't find .env file, using default environment variables")
	}

	// Load SQL queries
	if err := queries.LoadQueries(); err != nil {
		log.Fatal("Error loading queries:", err)
	}

	// Connect to the database
	db, err := database.ConnectDB()
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer database.CloseDB(db)

	// Initialize MQTT client
	mqttClient := mqtt.Init(db)
	_ = mqttClient 

	// Create Gin router
	r := gin.Default()

	// Setup CORS
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:8080", "http://localhost:3000"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	// WebSocket manager
	userRepo := repository.NewUserRepository(db)
	wsManager := websocket.NewNotificationManager(userRepo)
	go wsManager.Run()

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

	// Setup API routes
	api.SetupRoutes(r, db)

	// Get port from env
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Println("PORT not set, defaulting to 8080")
	}

	// Start server
	log.Printf("Starting server on port %s...", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
