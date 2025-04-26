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
	api.GET("/debug/routes", func(c *gin.Context) {
		routes := r.Routes()
		routeInfos := make([]gin.RouteInfo, 0, len(routes))
		for _, route := range routes {
			routeInfos = append(routeInfos, gin.RouteInfo{
				Method:      route.Method,
				Path:        route.Path,
				Handler:     route.Handler,
				HandlerFunc: route.HandlerFunc,
			})
		}
		c.JSON(http.StatusOK, gin.H{"routes": routeInfos})
	})
	// Set up route groups
	routes.SetupAuthRoutes(api, db)
	routes.SetupUserRoutes(api, db, wsHub, mqttClient)
	routes.SetupAdminRoutes(api, db)
}
