// api/routes/auth.go
package routes

import (
	"database/sql"
	"net/http"
	"hamstercare/internal/repository"
	"hamstercare/internal/service"
	"hamstercare/internal/model"
	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

func SetupAuthRoutes(r *gin.RouterGroup, db *sql.DB) {
	userRepo := repository.NewUserRepository(db)
	otpRepo := repository.NewOTPRepository(db)
	authService := service.NewAuthService(userRepo, otpRepo)

	auth := r.Group("/auth")
	{
		// Đăng ký
		auth.POST("/register", func(c *gin.Context) {
			var req struct {
				Username string `json:"username" binding:"required"`
				Email    string `json:"email" binding:"required,email"`
				Password string `json:"password" binding:"required"`
				Role     string `json:"role" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				return
			}

			hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
				return
			}

			user := &model.User{
				Username:     req.Username,
				Email:        req.Email,
				PasswordHash: string(hash),
				Role:         req.Role,
			}
			err = userRepo.CreateUser(user)
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
				return
			}
			c.JSON(http.StatusCreated, gin.H{"message": "User registered successfully"})
		})

		// Đăng nhập
		auth.POST("/login", func(c *gin.Context) {
			var req struct {
				Email    string `json:"email" binding:"required,email"`
				Password string `json:"password" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				return
			}

			token, err := authService.Login(req.Email, req.Password)
			if err != nil {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
				return
			}
			c.JSON(http.StatusOK, gin.H{"token": token})
		})
	}

	// OTP route (có thể đặt trong auth vì liên quan đến xác thực)
	r.POST("/otp/create", func(c *gin.Context) {
		var req struct {
			UserID string `json:"user_id"`
		}
		if err := c.BindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}
		otp, err := authService.CreateOTP(req.UserID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create OTP"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"otp_code": otp.OTPCode})
	})
}