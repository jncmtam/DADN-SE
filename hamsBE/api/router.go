package api

import (
	"database/sql"
	"hamstercare/api/routes"
	"hamstercare/internal/websocket"
	"net/http"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine, db *sql.DB, wsHub *websocket.Hub, mqttClient mqtt.Client) {
	api := r.Group("/api")

	// Public route
	api.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "pong"})
	})

	// Set up route groups
	routes.SetupAuthRoutes(api, db)
	routes.SetupUserRoutes(api, db, wsHub, mqttClient)
	routes.SetupAdminRoutes(api, db)
}
