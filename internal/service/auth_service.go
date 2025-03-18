// internal/service/auth_service.go
package service

import (
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

// Login xử lý đăng nhập và trả về JWT
func (s *AuthService) Login(email, password string) (string, error) {
	// Lấy user từ database
	user, err := s.UserRepo.GetUserByEmail(email)
	if err != nil {
		return "", err // Email không tồn tại
	}

	// Kiểm tra mật khẩu
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
	if err != nil {
		return "", err // Mật khẩu không khớp
	}

	// Tạo JWT
	token, err := generateJWT(user.ID, user.Role)
	if err != nil {
		return "", err
	}

	return token, nil
}

func (s *AuthService) CreateOTP(userID string) (*model.OTPRequest, error) {
	otpCode := generateOTP(6)
	otp := s.OTPRepo.NewOTPRequest(userID, otpCode, 5*time.Minute)
	err := s.OTPRepo.CreateOTP(otp)
	if err != nil {
		return nil, err
	}
	return otp, nil
}

// generateJWT tạo token JWT (di chuyển từ api/router.go sang đây)
func generateJWT(userID, role string) (string, error) {
	claims := jwt.MapClaims{
		"user_id": userID,
		"role":    role,
		"exp":     time.Now().Add(time.Hour * 24).Unix(), // Hết hạn sau 24h
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte("your-secret-key"))
}

func generateOTP(length int) string {
	// Placeholder, cần dùng "math/rand" để tạo OTP ngẫu nhiên
	return "123456"
}