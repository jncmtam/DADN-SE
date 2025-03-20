// api/routes/user.go
package routes

import (
	"database/sql"
	"net/http"
	"hamstercare/internal/middleware"
	"hamstercare/internal/repository"

	"github.com/gin-gonic/gin"
)

func SetupUserRoutes(r *gin.RouterGroup, db *sql.DB) {
	userRepo := repository.NewUserRepository(db)

	user := r.Group("/user")
	user.Use(middleware.JWTMiddleware())
	{
		user.GET("/:id", func(c *gin.Context) {
			id := c.Param("id")
			user, err := userRepo.GetUserByID(c.Request.Context(), id)
			if err != nil {
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
				return
			}
			c.JSON(http.StatusOK, user)
		})
	}
}