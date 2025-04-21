// api/routes/admin.go
package routes

import (
	"database/sql"
	"errors"
	"dacnpm/be_mqtt/DADN-SE/hamsBE/internal/middleware"
	"dacnpm/be_mqtt/DADN-SE/hamsBE/internal/repository"
	"dacnpm/be_mqtt/DADN-SE/hamsBE/internal/service"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

func SetupAdminRoutes(r *gin.RouterGroup, db *sql.DB) {
	userRepo := repository.NewUserRepository(db)
	otpRepo := repository.NewOTPRepository(db)
	authService := service.NewAuthService(userRepo, otpRepo)
	admin := r.Group("/admin")
	admin.Use(middleware.JWTMiddleware(), authMiddleware("admin"))
	{
		// Lấy thông tin người dùng
		admin.GET("/users/:id", func(c *gin.Context) {
			id := c.Param("id")
			user, err := userRepo.GetUserByID(c.Request.Context(), id)
			if err != nil {
				log.Printf("Failed to get user by ID %s: %v", id, err)
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
				return
			}
			c.JSON(http.StatusOK, user)
		})
		admin.GET("/users", middleware.JWTMiddleware(), func(c *gin.Context) {
			users, err := authService.GetAllUsers(c.Request.Context())
			if err != nil {
				log.Printf("Failed to fetch users: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch users: " + err.Error()})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Users retrieved successfully",
				"users":   users,
			})
		})

		// Đăng ký người dùng mới (chỉ admin)
		admin.POST("/auth/register", func(c *gin.Context) {
			var req struct {
				Username string `json:"username" binding:"required"`
				Email    string `json:"email" binding:"required,email"`
				Password string `json:"password" binding:"required"`
				Role     string `json:"role" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
			if err != nil {
				log.Printf("Failed to hash password: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
				return
			}

			user, err := userRepo.CreateUser(c.Request.Context(), req.Username, req.Email, string(hash), req.Role)
			if err != nil {
				// Kiểm tra lỗi cụ thể từ PostgreSQL
				if pqErr, ok := err.(*pq.Error); ok {
					switch pqErr.Code {
					case "23505": // Unique violation
						if pqErr.Constraint == "users_email_key" {
							log.Printf("Duplicate email: %s, error: %v", req.Email, err)
							c.JSON(http.StatusConflict, gin.H{"error": "Email already exists"})
						} else if pqErr.Constraint == "unique_username" {
							log.Printf("Duplicate username: %s, error: %v", req.Username, err)
							c.JSON(http.StatusConflict, gin.H{"error": "Username already exists"})
						}
						return
					}
				}
				log.Printf("Failed to create user: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
				return
			}
			c.JSON(http.StatusCreated, gin.H{"message": "User registered successfully", "user_id": user.ID})
		})
		admin.DELETE("/users/:user_id", middleware.JWTMiddleware(), func(c *gin.Context) {
            // Kiểm tra quyền admin
            role, exists := c.Get("role")
            if !exists || role != "admin" {
                c.JSON(http.StatusForbidden, gin.H{"error": "Only admins can delete users"})
                return
            }

            userID := c.Param("user_id")
            if userID == "" {
                c.JSON(http.StatusBadRequest, gin.H{"error": "User ID is required"})
                return
            }

            err := authService.DeleteUser(c.Request.Context(), userID)
            if err != nil {
                log.Printf("Failed to delete user %s: %v", userID, err)
                if errors.Is(err, errors.New("user not found")) {
                    c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
                } else {
                    c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete user: " + err.Error()})
                }
                return
            }

            c.JSON(http.StatusOK, gin.H{
                "message":   "User deleted successfully",
                "user_id":   userID,
                "timestamp": time.Now().UTC(),
            })
        })
	}
}

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
