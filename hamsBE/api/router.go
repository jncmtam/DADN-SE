// api/router.go
package api

import (
	"database/sql"
	"hamstercare/api/routes"
	"hamstercare/internal/websocket"
	"net/http"

	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine, db *sql.DB) {
	api := r.Group("/api")
	// Initialize WebSocket hub
	wsHub := websocket.NewHub()
	go wsHub.Run()
	// Route công khai
	api.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "pong"})
	})

	// Gắn các nhóm route
	routes.SetupAuthRoutes(api, db)
	routes.SetupUserRoutes(api, db, wsHub)
	routes.SetupAdminRoutes(api, db)
}
