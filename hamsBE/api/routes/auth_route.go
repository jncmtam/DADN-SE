package routes

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"hamstercare/internal/repository"
	"hamstercare/internal/service"
	"hamstercare/internal/utils"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"hamstercare/internal/middleware"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
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

			log.Printf("Login attempt for email: %s", req.Email)
			authResponse, err := authService.Login(c.Request.Context(), req.Email, req.Password)
			if err != nil {
				log.Printf("Login failed for email %s: %v", req.Email, err)

				// More specific error messages based on the error type
				switch {
				case errors.Is(err, sql.ErrNoRows):
					c.JSON(http.StatusUnauthorized, gin.H{"error": "Email not found"})
				case strings.Contains(err.Error(), "invalid password"):
					c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid password"})
				case strings.Contains(err.Error(), "JWT secret key"):
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Authentication service configuration error"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Login failed, please try again later"})
				}
				return
			}
			log.Printf("Login successful for email %s", req.Email)
			c.JSON(http.StatusOK, authResponse)
		})

		// Đăng xuất
		auth.POST("/logout", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.GetString("user_id")
			if userID == "" {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			// Extract token from Authorization header
			token := c.GetHeader("Authorization")
			if len(token) <= 7 || strings.ToLower(token[0:6]) != "bearer" {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or missing Authorization header"})
				return
			}
			token = strings.TrimSpace(token[7:])

			err := authService.Logout(c.Request.Context(), userID, token)
			if err != nil {
				log.Printf("Logout failed for user %s: %v", userID, err)
				switch {
				case errors.Is(err, context.DeadlineExceeded):
					c.JSON(http.StatusGatewayTimeout, gin.H{"error": "Logout timeout"})
				case strings.Contains(err.Error(), "user ID") || strings.Contains(err.Error(), "token"):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
				case strings.Contains(err.Error(), "user not found"):
					c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to logout: " + err.Error()})
				}
				return
			}

			// Clear any auth-related cookies
			c.SetCookie("token", "", -1, "/", "", false, true)

			c.JSON(http.StatusOK, gin.H{
				"message":   "Successfully logged out",
				"timestamp": time.Now().UTC(),
			})
		})

		// Đổi mật khẩu (chỉ cần mật khẩu cũ và mật khẩu mới)
		auth.POST("/change-password", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.GetString("user_id")
			if userID == "" {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			var req struct {
				OldPassword string `json:"old_password" binding:"required"`
				NewPassword string `json:"new_password" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			err := authService.ChangePassword(c.Request.Context(), userID, req.OldPassword, req.NewPassword)
			if err != nil {
				log.Printf("Failed to change password for user %s: %v", userID, err)
				if strings.Contains(err.Error(), "invalid old password") {
					c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid old password"})
				} else {
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to change password: " + err.Error()})
				}
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Password changed successfully",
			})
		})

		// Yêu cầu OTP để quên mật khẩu
		auth.POST("/forgot-password", func(c *gin.Context) {
			var req struct {
				Email string `json:"email" binding:"required,email"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			// Look up the user by email to get the userID
			user, err := userRepo.FindUserByEmail(c.Request.Context(), req.Email)
			if err != nil {
				if err == sql.ErrNoRows {
					c.JSON(http.StatusOK, gin.H{"message": "If the email exists, an OTP has been sent"})
					return
				}
				log.Printf("Failed to fetch user by email: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch user: " + err.Error()})
				return
			}

			otp, err := authService.CreateOTP(c.Request.Context(), user.ID)
			if err != nil {
				log.Printf("Failed to create OTP for forgot password: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to initiate password reset: " + err.Error()})
				return
			}

			// Send the OTP to the user's email
			err = utils.SendEmail(user.Email, "Change Password", "Here is your OTP to reset your password:", otp.OTPCode)
			if err != nil {
				log.Printf("Failed to send OTP email: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send OTP email: " + err.Error()})
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
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
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

		// Làm mới access token bằng refresh token
		auth.POST("/refresh", func(c *gin.Context) {
			var req struct {
				RefreshToken string `json:"refresh_token" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
				return
			}

			token, err := jwt.Parse(req.RefreshToken, func(token *jwt.Token) (interface{}, error) {
				if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
				}
				secret := os.Getenv("JWT_SECRET_KEY")
				if secret == "" {
					return nil, fmt.Errorf("JWT_SECRET not configured")
				}
				return []byte(secret), nil
			})

			if err != nil {
				log.Printf("Failed to parse refresh token: %v", err)
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired refresh token"})
				return
			}

			if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
				userID, ok := claims["user_id"].(string)
				if !ok {
					c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid refresh token"})
					return
				}

				role, ok := claims["role"].(string)
				if !ok {
					c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid refresh token"})
					return
				}

				// Generate a new access token
				newAccessToken, err := service.GenerateJWT(userID, role, 24*time.Hour)
				if err != nil {
					log.Printf("Failed to generate new access token: %v", err)
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token: " + err.Error()})
					return
				}

				c.JSON(http.StatusOK, gin.H{
					"access_token":  newAccessToken,
					"refresh_token": req.RefreshToken, // Return the same refresh token
				})
			} else {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid refresh token"})
				return
			}
		})
	}

	// Route OTP
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

	// Nhóm route cho profile
	profile := r.Group("/profile")
	{
		// Xem thông tin profile
		profile.GET("", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.GetString("user_id")
			if userID == "" {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			user, err := userRepo.GetUserByID(c.Request.Context(), userID)
			if err != nil {
				log.Printf("Failed to fetch user: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch user: " + err.Error()})
				return
			}

			// Nếu avatar_url rỗng, trả về ảnh mặc định
			if user.AvatarURL == "" {
				user.AvatarURL = "/avatars/default.jpg"
			}

			// Tạo URL đầy đủ
			baseURL := "http://localhost:8080" // Thay bằng domain của bạn khi triển khai
			user.AvatarURL = baseURL + user.AvatarURL

			c.JSON(http.StatusOK, gin.H{
				"message": "Profile retrieved successfully",
				"user":    user,
			})
		})

		// Đổi avatar
		profile.POST("/avatar", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.GetString("user_id")
			if userID == "" {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			// Lấy thông tin người dùng hiện tại
			_, err := userRepo.GetUserByID(c.Request.Context(), userID)
			if err != nil {
				log.Printf("Failed to fetch user: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch user: " + err.Error()})
				return
			}

			// Xóa tất cả tệp avatar cũ liên quan đến userID
			avatarDir := "public/avatars/"
			files, err := os.ReadDir(avatarDir)
			if err == nil { // Chỉ chạy nếu thư mục tồn tại
				for _, f := range files {
					if strings.HasPrefix(f.Name(), userID) {
						oldFilePath := avatarDir + f.Name()
						if err := os.Remove(oldFilePath); err != nil && !os.IsNotExist(err) {
							log.Printf("Failed to delete old avatar %s: %v", oldFilePath, err)
						}
					}
				}
			} else if !os.IsNotExist(err) {
				log.Printf("Failed to read avatars directory: %v", err)
			}

			// Lấy file từ request
			file, err := c.FormFile("avatar")
			if err != nil {
				log.Printf("Failed to get avatar file: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to get avatar file: " + err.Error()})
				return
			}

			// Kiểm tra kích thước file (giới hạn 5MB)
			if file.Size > 5*1024*1024 {
				c.JSON(http.StatusBadRequest, gin.H{"error": "File size exceeds 5MB limit"})
				return
			}

			// Chuẩn hóa định dạng về .jpg
			ext := strings.ToLower(filepath.Ext(file.Filename))
			if ext != ".jpg" && ext != ".jpeg" && ext != ".png" {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Only JPG, JPEG, or PNG files are allowed"})
				return
			}
			ext = ".jpg" // Luôn lưu dưới dạng .jpg để nhất quán

			// Tạo tên file và đường dẫn
			filename := fmt.Sprintf("%s%s", userID, ext)
			filepath := fmt.Sprintf("%s%s", avatarDir, filename)

			// Đảm bảo thư mục tồn tại
			if err := os.MkdirAll(avatarDir, 0755); err != nil {
				log.Printf("Failed to create avatars directory: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create avatars directory"})
				return
			}

			// Lưu file mới (ghi đè nếu đã tồn tại)
			if err := c.SaveUploadedFile(file, filepath); err != nil {
				log.Printf("Failed to save avatar file: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save avatar file: " + err.Error()})
				return
			}

			// Cập nhật database với đường dẫn mới
			avatarURL := fmt.Sprintf("/avatars/%s", filename)
			user, err := authService.UpdateAvatar(c.Request.Context(), userID, avatarURL)
			if err != nil {
				log.Printf("Failed to update avatar: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update avatar: " + err.Error()})
				return
			}

			// Tạo URL đầy đủ
			baseURL := "http://localhost:8080" // Thay bằng domain thực tế khi triển khai
			user.AvatarURL = baseURL + user.AvatarURL

			c.JSON(http.StatusOK, gin.H{
				"message": "Avatar updated successfully",
				"user":    user,
			})
		})
		profile.GET("/avatar", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.GetString("user_id")
			if userID == "" {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			user, err := userRepo.GetUserByID(c.Request.Context(), userID)
			if err != nil {
				log.Printf("Failed to fetch user: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch user: " + err.Error()})
				return
			}

			avatarPath := "public/avatars/default.jpg"
			if user.AvatarURL != "" {
				avatarPath = "public/" + strings.TrimPrefix(user.AvatarURL, "/")
			}

			if _, err := os.Stat(avatarPath); os.IsNotExist(err) {
				avatarPath = "public/avatars/default.jpg"
			}

			c.File(avatarPath)
		})
		profile.POST("/username", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.GetString("user_id")
			if userID == "" {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			var req struct {
				Username string `json:"username" binding:"required,min=3,max=50"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			// Check if username is already taken
			existingUser, err := userRepo.FindUserByUsername(c.Request.Context(), req.Username)
			if err != nil && err != sql.ErrNoRows {
				log.Printf("Failed to check username availability: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to check username availability"})
				return
			}
			if existingUser != nil && existingUser.ID != userID {
				c.JSON(http.StatusConflict, gin.H{"error": "Username already taken"})
				return
			}

			// Update username
			updatedUser, err := authService.UpdateUsername(c.Request.Context(), userID, req.Username)
			if err != nil {
				log.Printf("Failed to update username: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update username: " + err.Error()})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Username updated successfully",
				"user":    updatedUser,
			})
		})

	}
}