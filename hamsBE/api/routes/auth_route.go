package routes

import (
	"database/sql"
	"hamstercare/internal/middleware"
	"hamstercare/internal/repository"
	"hamstercare/internal/service"
	"log"
	"mime/multipart"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

func SetupAuthRoutes(r *gin.RouterGroup, db *sql.DB) {
	userRepo := repository.NewUserRepository(db)
	otpRepo := repository.NewOTPRepository(db)
	authService := service.NewAuthService(userRepo, otpRepo)

	auth := r.Group("/auth")
	{
		// Đăng nhập
		auth.POST("/login", func(c *gin.Context) {
			var req struct {
				Email    string `json:"email" binding:"required,email"`
				Password string `json:"password" binding:"required"`
			}

			middleware.ValidateJSONBody(&req)(c)
			if c.IsAborted() {
				return
			}

			log.Printf("Login attempt for email: %s", req.Email)
			authResponse, err := authService.Login(c.Request.Context(), req.Email, req.Password)
			if err != nil {
				log.Printf("Login failed for email %s: %v", req.Email, err)
				c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
				return
			}
			log.Printf("Login successful for email %s", req.Email)
			c.JSON(http.StatusOK, authResponse)
		})

		// Đăng xuất
		auth.POST("/logout", middleware.JWTMiddleware(), middleware.ValidateUserID(), func(c *gin.Context) {
			userID := c.GetString("user_id")
			token := c.GetHeader("Authorization")
			if len(token) <= 7 || strings.ToLower(token[0:6]) != "bearer" {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or missing Authorization header"})
				return
			}
			token = token[7:]

			err := authService.Logout(c.Request.Context(), userID, token)
			if err != nil {
				log.Printf("Logout failed for user %s: %v", userID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to logout: " + err.Error()})
				return
			}

			c.SetCookie("token", "", -1, "/", "", false, true)
			c.JSON(http.StatusOK, gin.H{
				"message":   "Successfully logged out",
				"timestamp": time.Now().UTC(),
			})
		})

		// Yêu cầu OTP để đổi mật khẩu
		auth.POST("/change-password", middleware.JWTMiddleware(), middleware.ValidateUserID(), func(c *gin.Context) {
			userID := c.GetString("user_id")
			otp, err := authService.CreateOTP(c.Request.Context(), userID)
			if err != nil {
				log.Printf("Failed to create OTP for password change: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to initiate password change: " + err.Error()})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message":    "OTP sent to your email",
				"expires_at": otp.ExpiresAt,
			})
		})

		// Xác minh OTP và đổi mật khẩu
		auth.POST("/change-password/verify", middleware.JWTMiddleware(), middleware.ValidateUserID(), func(c *gin.Context) {
			var req struct {
				OTPCode     string `json:"otp_code" binding:"required"`
				NewPassword string `json:"new_password" binding:"required"`
			}

			middleware.ValidateJSONBody(&req)(c)
			if c.IsAborted() {
				return
			}

			userID := c.GetString("user_id")
			err := authService.ChangePassword(c.Request.Context(), userID, req.OTPCode, req.NewPassword)
			if err != nil {
				log.Printf("Failed to change password for user %s: %v", userID, err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to change password: " + err.Error()})
				return
			}

			c.JSON(http.StatusOK, gin.H{"message": "Password changed successfully"})
		})

		// Yêu cầu OTP để quên mật khẩu
		auth.POST("/forgot-password", func(c *gin.Context) {
			var req struct {
				Email string `json:"email" binding:"required,email"`
			}

			middleware.ValidateJSONBody(&req)(c)
			if c.IsAborted() {
				return
			}

			otp, err := authService.CreateOTPByEmail(c.Request.Context(), req.Email)
			if err != nil {
				if err == sql.ErrNoRows {
					c.JSON(http.StatusOK, gin.H{"message": "If the email exists, an OTP has been sent"})
					return
				}
				log.Printf("Failed to create OTP for forgot password: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to initiate password reset: " + err.Error()})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message":    "OTP sent to your email",
				"expires_at": otp.ExpiresAt,
			})
		})

		// Đặt lại mật khẩu bằng OTP
		auth.POST("/reset-password", func(c *gin.Context) {
			var req struct {
				Email       string `json:"email" binding:"required,email"`
				OTPCode     string `json:"otp_code" binding:"required"`
				NewPassword string `json:"new_password" binding:"required"`
			}

			middleware.ValidateJSONBody(&req)(c)
			if c.IsAborted() {
				return
			}

			err := authService.ChangePassword(c.Request.Context(), req.Email, req.OTPCode, req.NewPassword)
			if err != nil {
				log.Printf("Failed to reset password for email %s: %v", req.Email, err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to reset password: " + err.Error()})
				return
			}

			c.JSON(http.StatusOK, gin.H{"message": "Password reset successfully"})
		})

		// Làm mới access token
		auth.POST("/refresh", func(c *gin.Context) {
			var req struct {
				RefreshToken string `json:"refresh_token" binding:"required"`
			}

			middleware.ValidateJSONBody(&req)(c)
			if c.IsAborted() {
				return
			}

			newTokens, err := authService.RefreshToken(c.Request.Context(), req.RefreshToken)
			if err != nil {
				log.Printf("Failed to refresh token: %v", err)
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired refresh token"})
				return
			}

			c.JSON(http.StatusOK, newTokens)
		})
	}

	// Route OTP
	r.POST("/otp/create", func(c *gin.Context) {
		var req struct {
			UserID string `json:"user_id" binding:"required"`
		}

		middleware.ValidateJSONBody(&req)(c)
		if c.IsAborted() {
			return
		}

		otp, err := authService.CreateOTP(c.Request.Context(), req.UserID)
		if err != nil {
			log.Printf("Failed to create OTP: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create OTP: " + err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{"otp_code": otp.OTPCode, "expires_at": otp.ExpiresAt})
	})

	r.POST("/otp/verify", func(c *gin.Context) {
		var req struct {
			UserID  string `json:"user_id" binding:"required"`
			OTPCode string `json:"otp_code" binding:"required"`
		}

		middleware.ValidateJSONBody(&req)(c)
		if c.IsAborted() {
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

	// Nhóm route cho profile
	profile := r.Group("/profile")
	{
		// Xem thông tin profile
		profile.GET("", middleware.JWTMiddleware(), middleware.ValidateUserID(), func(c *gin.Context) {
			userID := c.GetString("user_id")
			user, err := authService.GetUserProfile(c.Request.Context(), userID)
			if err != nil {
				log.Printf("Failed to fetch user profile: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch user profile: " + err.Error()})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Profile retrieved successfully",
				"user":    user,
			})
		})

		// Đổi avatar
		profile.POST("/avatar", middleware.JWTMiddleware(), middleware.ValidateUserID(), func(c *gin.Context) {
			userID := c.GetString("user_id")
			file, err := c.FormFile("avatar")
			if err != nil {
				log.Printf("Failed to get avatar file: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to get avatar file: " + err.Error()})
				return
			}

			// Truyền hàm SaveUploadedFile từ gin.Context
			saveFileFunc := func(file *multipart.FileHeader, filepath string) error {
				return c.SaveUploadedFile(file, filepath)
			}

			user, err := authService.UpdateAvatar(c.Request.Context(), userID, file, saveFileFunc)
			if err != nil {
				log.Printf("Failed to update avatar: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update avatar: " + err.Error()})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Avatar updated successfully",
				"user":    user,
			})
		})

		// Lấy file avatar
		profile.GET("/avatar", middleware.JWTMiddleware(), middleware.ValidateUserID(), func(c *gin.Context) {
			userID := c.GetString("user_id")
			avatarPath, err := authService.GetAvatarPath(c.Request.Context(), userID)
			if err != nil {
				log.Printf("Failed to get avatar path: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch avatar: " + err.Error()})
				return
			}

			c.File(avatarPath)
		})

		// Cập nhật username
		profile.POST("/username", middleware.JWTMiddleware(), middleware.ValidateUserID(), func(c *gin.Context) {
			var req struct {
				Username string `json:"username" binding:"required,min=3,max=50"`
			}

			middleware.ValidateJSONBody(&req)(c)
			if c.IsAborted() {
				return
			}

			userID := c.GetString("user_id")
			response, err := authService.UpdateUsername(c.Request.Context(), userID, req.Username)
			if err != nil {
				log.Printf("Failed to update username: %v", err)
				if strings.Contains(err.Error(), "username already taken") {
					c.JSON(http.StatusConflict, gin.H{"error": "Username already taken"})
				} else {
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update username: " + err.Error()})
				}
				return
			}

			c.JSON(http.StatusOK, response)
		})
	}
}