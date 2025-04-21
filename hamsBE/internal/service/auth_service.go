package service

import (
	"context"
	"crypto/rand"
	"database/sql"
	"errors"
	"fmt"
	"dacnpm/be_mqtt/DADN-SE/hamsBE/internal/model"
	"dacnpm/be_mqtt/DADN-SE/hamsBE/internal/repository"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v4"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	UserRepo *repository.UserRepository
	OTPRepo  *repository.OTPRepository
}

func NewAuthService(userRepo *repository.UserRepository, otpRepo *repository.OTPRepository) *AuthService {
	return &AuthService{UserRepo: userRepo, OTPRepo: otpRepo}
}

func (s *AuthService) Login(ctx context.Context, email, password string) (*model.AuthResponse, error) {
	fmt.Printf("Attempting to find user with email: %s\n", email)
	user, err := s.UserRepo.FindUserByEmail(ctx, email)
	if err != nil {
		fmt.Printf("FindUserByEmail failed for email %s: %v\n", email, err)
		if err == sql.ErrNoRows {
			return nil, err
		}
		return nil, fmt.Errorf("failed to find user: %w", err)
	}
	fmt.Printf("User found: %+v\n", user)

	// Verify password
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
	if err != nil {
		fmt.Printf("Password comparison failed for email %s: %v\n", email, err)
		return nil, errors.New("invalid password")
	}
	fmt.Printf("Password comparison successful for email %s\n", email)

	// Get JWT secret key from environment
	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		return nil, errors.New("JWT secret key is not configured")
	}

	accessToken, err := GenerateJWT(user.ID, user.Role, 24*time.Hour)
	if err != nil {
		fmt.Printf("Failed to generate access token for user %s: %v\n", user.ID, err)
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshToken, err := GenerateJWT(user.ID, user.Role, 7*24*time.Hour)
	if err != nil {
		fmt.Printf("Failed to generate refresh token for user %s: %v\n", user.ID, err)
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}
	fmt.Printf("Generated refresh token: %s\n", refreshToken)

	// Store refresh token in database
	tx, err := s.UserRepo.DB().BeginTx(ctx, nil)
	if err != nil {
		fmt.Printf("Failed to start transaction: %v\n", err)
		return nil, fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback()

	// Delete any existing refresh tokens for this user
	err = s.UserRepo.DeleteRefreshToken(ctx, user.ID)
	if err != nil {
		fmt.Printf("Failed to delete existing refresh tokens: %v\n", err)
		// Continue even if deletion fails
	}

	// Store new refresh token
	_, err = s.UserRepo.StoreRefreshToken(ctx, user.ID, refreshToken, time.Now().Add(7*24*time.Hour))
	if err != nil {
		fmt.Printf("Failed to store refresh token: %v\n", err)
		return nil, fmt.Errorf("failed to store refresh token: %w", err)
	}

	if err = tx.Commit(); err != nil {
		fmt.Printf("Failed to commit transaction: %v\n", err)
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	return &model.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
	}, nil
}

func (s *AuthService) Logout(ctx context.Context, userID, token string) error {
	if userID == "" {
		return errors.New("user ID cannot be empty")
	}
	if token == "" {
		return errors.New("token cannot be empty")
	}

	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	_, err := s.UserRepo.GetUserByID(ctx, userID)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("user not found: %w", err)
		}
		return fmt.Errorf("failed to fetch user: %w", err)
	}

	tx, err := s.UserRepo.DB().BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback()

	err = s.UserRepo.DeleteRefreshToken(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to delete refresh tokens: %w", err)
	}

	err = s.OTPRepo.DeleteActiveOTPs(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to delete active OTPs: %w", err)
	}

	if err = tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}

func (s *AuthService) CreateOTP(ctx context.Context, userID string) (*model.OTPRequest, error) {
	otpCode := generateOTP(6)
	expiresAt := time.Now().Add(5 * time.Minute)

	otp, err := s.OTPRepo.CreateOTPRequest(ctx, userID, otpCode, expiresAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create OTP: %w", err)
	}

	return otp, nil
}

func (s *AuthService) VerifyOTP(ctx context.Context, userID, otpCode string) error {
	otp, err := s.OTPRepo.VerifyOTP(ctx, userID, otpCode)
	if err != nil {
		return fmt.Errorf("invalid or expired OTP: %w", err)
	}

	_, err = s.OTPRepo.MarkOTPAsUsed(ctx, otp.ID)
	if err != nil {
		return fmt.Errorf("failed to mark OTP as used: %w", err)
	}

	_, err = s.UserRepo.VerifyEmail(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to verify email: %w", err)
	}

	return nil
}

func GenerateJWT(userID, role string, expiry time.Duration) (string, error) {
	claims := jwt.MapClaims{
		"user_id": userID,
		"role":    role,
		"exp":     time.Now().Add(expiry).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		return "", errors.New("JWT secret key is not configured")
	}
	return token.SignedString([]byte(secretKey))
}

func generateOTP(length int) string {
	const digits = "0123456789"
	b := make([]byte, length)
	_, err := rand.Read(b)
	if err != nil {
		for i := range b {
			b[i] = digits[i%10]
		}
	} else {
		for i := range b {
			b[i] = digits[int(b[i])%10]
		}
	}
	return string(b)
}

// ChangePassword (đổi mật khẩu bằng mật khẩu cũ và mật khẩu mới)
func (s *AuthService) ChangePassword(ctx context.Context, identifier, oldPasswordOrOTP, newPassword string) error {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	var user *model.User
	var err error

	// Kiểm tra identifier là userID hay email
	if strings.Contains(identifier, "@") {
		// identifier là email (dùng cho forgot-password)
		user, err = s.UserRepo.FindUserByEmail(ctx, identifier)
		if err != nil {
			if err == sql.ErrNoRows {
				return fmt.Errorf("user not found: %w", err)
			}
			return fmt.Errorf("failed to fetch user by email: %w", err)
		}

		// Xác minh OTP (dùng cho forgot-password)
		otp, err := s.OTPRepo.VerifyOTP(ctx, user.ID, oldPasswordOrOTP)
		if err != nil {
			return fmt.Errorf("invalid or expired OTP: %w", err)
		}

		tx, err := s.UserRepo.DB().BeginTx(ctx, nil)
		if err != nil {
			return fmt.Errorf("failed to start transaction: %w", err)
		}
		defer tx.Rollback()

		_, err = s.OTPRepo.MarkOTPAsUsed(ctx, otp.ID)
		if err != nil {
			return fmt.Errorf("failed to mark OTP as used: %w", err)
		}

		newPasswordHash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
		if err != nil {
			return fmt.Errorf("failed to hash new password: %w", err)
		}

		_, err = s.UserRepo.UpdatePassword(ctx, user.ID, string(newPasswordHash))
		if err != nil {
			return fmt.Errorf("failed to update password: %w", err)
		}

		if err = tx.Commit(); err != nil {
			return fmt.Errorf("failed to commit transaction: %w", err)
		}

		return nil
	}

	// identifier là userID (dùng cho change-password)
	user, err = s.UserRepo.GetUserByID(ctx, identifier)
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("user not found: %w", err)
		}
		return fmt.Errorf("failed to fetch user: %w", err)
	}

	// Xác minh mật khẩu cũ
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(oldPasswordOrOTP))
	if err != nil {
		return errors.New("invalid old password")
	}

	// Hash mật khẩu mới
	newPasswordHash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash new password: %w", err)
	}

	// Cập nhật mật khẩu mới
	_, err = s.UserRepo.UpdatePassword(ctx, user.ID, string(newPasswordHash))
	if err != nil {
		return fmt.Errorf("failed to update password: %w", err)
	}

	return nil
}

func (s *AuthService) UpdateAvatar(ctx context.Context, userID, avatarURL string) (*model.User, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	user, err := s.UserRepo.UpdateAvatar(ctx, userID, avatarURL)
	if err != nil {
		return nil, fmt.Errorf("failed to update avatar: %w", err)
	}

	return user, nil
}

// GetAllUsers
func (s *AuthService) GetAllUsers(ctx context.Context) ([]*model.User, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	users, err := s.UserRepo.GetAllUsers(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch all users: %w", err)
	}

	return users, nil
}

type ChangeUsernameResponse struct {
	Message string `json:"message"`
	User    struct {
		ID       string `json:"id"`
		Username string `json:"username"`
		Email    string `json:"email"`
	} `json:"user"`
}

func (s *AuthService) UpdateUsername(ctx context.Context, userID, username string) (*ChangeUsernameResponse, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	user, err := s.UserRepo.UpdateUsername(ctx, userID, username)
	if err != nil {
		return nil, fmt.Errorf("failed to update username: %w", err)
	}

	response := &ChangeUsernameResponse{
		Message: "Username changed successfully!",
		User: struct {
			ID       string `json:"id"`
			Username string `json:"username"`
			Email    string `json:"email"`
		}{
			ID:       user.ID,
			Username: user.Username,
			Email:    user.Email,
		},
	}

	return response, nil
}

func (s *AuthService) DeleteUser(ctx context.Context, userID string) error {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	tx, err := s.UserRepo.DB().BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback()

	// Xóa refresh tokens của người dùng
	err = s.UserRepo.DeleteRefreshToken(ctx, userID)
	if err != nil {
		fmt.Printf("Failed to delete refresh tokens for user %s: %v\n", userID, err)
		// Tiếp tục dù lỗi này xảy ra (tùy yêu cầu)
	}

	// Xóa OTPs của người dùng
	err = s.OTPRepo.DeleteActiveOTPs(ctx, userID)
	if err != nil {
		fmt.Printf("Failed to delete active OTPs for user %s: %v\n", userID, err)
		// Tiếp tục dù lỗi này xảy ra (tùy yêu cầu)
	}

	// Xóa người dùng
	err = s.UserRepo.DeleteUser(ctx, userID)
	if err != nil {
		if err == sql.ErrNoRows {
			return errors.New("user not found")
		}
		return fmt.Errorf("failed to delete user: %w", err)
	}

	// Commit giao dịch
	if err = tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	fmt.Printf("User %s deleted successfully\n", userID)
	return nil
}