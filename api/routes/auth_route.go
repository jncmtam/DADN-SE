// api/routes/auth.go
package routes

import (
	"database/sql"
	"net/http"
	"hamstercare/internal/repository"
	"hamstercare/internal/service"
	"log"

	"github.com/gin-gonic/gin"
)

func SetupAuthRoutes(r *gin.RouterGroup, db *sql.DB) {
	userRepo := repository.NewUserRepository(db)
	otpRepo := repository.NewOTPRepository(db)
	authService := service.NewAuthService(userRepo, otpRepo)

	auth := r.Group("/auth")
	{
		// Đăng nhập (không yêu cầu quyền admin)
		auth.POST("/login", func(c *gin.Context) {
			var req struct {
				Email    string `json:"email" binding:"required,email"`
				Password string `json:"password" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			token, err := authService.Login(c.Request.Context(), req.Email, req.Password)
			if err != nil {
				log.Printf("Login failed: %v", err)
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid credentials"})
				return
			}
			c.JSON(http.StatusOK, gin.H{"token": token})
		})
	}

	// Các route OTP giữ nguyên
	r.POST("/otp/create", func(c *gin.Context) {
		var req struct {
			UserID string `json:"user_id" binding:"required"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			log.Printf("Invalid request body: %v", err)
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}

		otp, err := authService.CreateOTP(c.Request.Context(), req.UserID)
		if err != nil {
			log.Printf("Failed to create OTP: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create OTP"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"otp_code": otp.OTPCode, "expires_at": otp.ExpiresAt})
	})

	r.POST("/otp/verify", func(c *gin.Context) {
		var req struct {
			UserID  string `json:"user_id" binding:"required"`
			OTPCode string `json:"otp_code" binding:"required"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			log.Printf("Invalid request body: %v", err)
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}

		err := authService.VerifyOTP(c.Request.Context(), req.UserID, req.OTPCode)
		if err != nil {
			log.Printf("OTP verification failed: %v", err)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired OTP"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"message": "Email verified successfully"})
	})
}