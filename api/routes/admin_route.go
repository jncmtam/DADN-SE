// api/routes/admin.go
package routes

import (
	"database/sql"
	"net/http"
	"hamstercare/internal/repository"
	"hamstercare/internal/middleware"
	"github.com/gin-gonic/gin"
)

func SetupAdminRoutes(r *gin.RouterGroup, db *sql.DB) {
	userRepo := repository.NewUserRepository(db)

	admin := r.Group("/admin")
	admin.Use(middleware.JWTMiddleware(), authMiddleware("admin"))
	{
		admin.GET("/users/:id", func(c *gin.Context) {
			id := c.Param("id")
			user, err := userRepo.GetUserByID(id)
			if err != nil {
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
				return
			}
			c.JSON(http.StatusOK, user)
		})
	}
}

// authMiddleware kiểm tra role
func authMiddleware(requiredRole string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole := c.GetString("role")
		if userRole != requiredRole {
			c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
			c.Abort()
			return
		}
		c.Next()
	}
}