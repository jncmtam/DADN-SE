// api/router.go
package api

import (
	"database/sql"
	"net/http"
	"hamstercare/api/routes"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine, db *sql.DB) {
	api := r.Group("/api")

	// Route công khai
	api.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "pong"})
	})

	// Gắn các nhóm route
	routes.SetupAuthRoutes(api, db)
	routes.SetupUserRoutes(api, db)
	routes.SetupAdminRoutes(api, db)
}