// internal/service/auth_service.go
package service

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"time"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"

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

func (s *AuthService) Login(ctx context.Context, email, password string) (string, error) {
	user, err := s.UserRepo.FindUserByEmail(ctx, email)
	if err != nil {
		return "", fmt.Errorf("email not found: %w", err)
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
	if err != nil {
		return "", errors.New("invalid password")
	}

	token, err := generateJWT(user.ID, user.Role)
	if err != nil {
		return "", fmt.Errorf("failed to generate JWT: %w", err)
	}

	return token, nil
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

func generateJWT(userID, role string) (string, error) {
	claims := jwt.MapClaims{
		"user_id": userID,
		"role":    role,
		"exp":     time.Now().Add(time.Hour * 24).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	secretKey := []byte("your-secret-key") // Nên lấy từ biến môi trường
	return token.SignedString(secretKey)
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