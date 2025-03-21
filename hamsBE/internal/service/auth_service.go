package service

import (
	"context"
	"crypto/rand"
	"database/sql"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
	"hamstercare/internal/utils"
	"mime/multipart"
	"os"
	"path/filepath"
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

// Login xử lý đăng nhập
func (s *AuthService) Login(ctx context.Context, email, password string) (*model.AuthResponse, error) {
	fmt.Printf("Attempting to find user with email: %s\n", email)
	user, err := s.UserRepo.FindUserByEmail(ctx, email)
	if err != nil {
		fmt.Printf("FindUserByEmail failed for email %s: %v\n", email, err)
		if err == sql.ErrNoRows {
			return nil, errors.New("email not found")
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

	// Generate access and refresh tokens
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

// Logout xử lý đăng xuất
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

// CreateOTP tạo OTP cho user
func (s *AuthService) CreateOTP(ctx context.Context, userID string) (*model.OTPRequest, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	otpCode := generateOTP(6)
	expiresAt := time.Now().Add(5 * time.Minute)

	otp, err := s.OTPRepo.CreateOTPRequest(ctx, userID, otpCode, expiresAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create OTP: %w", err)
	}

	user, err := s.UserRepo.GetUserByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch user: %w", err)
	}

	err = utils.SendEmail(user.Email, "Change Password", "Here is your OTP to change your password:", otp.OTPCode)
	if err != nil {
		return nil, fmt.Errorf("failed to send OTP email: %w", err)
	}

	return otp, nil
}

// CreateOTPByEmail tạo OTP dựa trên email
func (s *AuthService) CreateOTPByEmail(ctx context.Context, email string) (*model.OTPRequest, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	user, err := s.UserRepo.FindUserByEmail(ctx, email)
	if err != nil {
		return nil, err // Trả về lỗi để route xử lý
	}

	otpCode := generateOTP(6)
	expiresAt := time.Now().Add(5 * time.Minute)

	otp, err := s.OTPRepo.CreateOTPRequest(ctx, user.ID, otpCode, expiresAt)
	if err != nil {
		return nil, fmt.Errorf("failed to create OTP: %w", err)
	}

	err = utils.SendEmail(user.Email, "Change Password", "Here is your OTP to reset your password:", otp.OTPCode)
	if err != nil {
		return nil, fmt.Errorf("failed to send OTP email: %w", err)
	}

	return otp, nil
}

// ChangePassword đổi mật khẩu
func (s *AuthService) ChangePassword(ctx context.Context, identifier, otpCode, newPassword string) error {
	if identifier == "" {
		return errors.New("identifier cannot be empty")
	}
	if otpCode == "" {
		return errors.New("OTP code cannot be empty")
	}
	if newPassword == "" {
		return errors.New("new password cannot be empty")
	}

	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	var user *model.User
	var err error

	if strings.Contains(identifier, "@") {
		// identifier là email
		user, err = s.UserRepo.FindUserByEmail(ctx, identifier)
	} else {
		// identifier là userID
		user, err = s.UserRepo.GetUserByID(ctx, identifier)
	}
	if err != nil {
		if err == sql.ErrNoRows {
			return fmt.Errorf("user not found: %w", err)
		}
		return fmt.Errorf("failed to fetch user: %w", err)
	}

	otp, err := s.OTPRepo.VerifyOTP(ctx, user.ID, otpCode)
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

// RefreshToken làm mới access token
func (s *AuthService) RefreshToken(ctx context.Context, refreshToken string) (*model.AuthResponse, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	token, err := jwt.Parse(refreshToken, func(token *jwt.Token) (interface{}, error) {
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
		return nil, fmt.Errorf("failed to parse refresh token: %w", err)
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		userID, ok := claims["user_id"].(string)
		if !ok {
			return nil, fmt.Errorf("invalid refresh token: missing user_id")
		}

		role, ok := claims["role"].(string)
		if !ok {
			return nil, fmt.Errorf("invalid refresh token: missing role")
		}

		newAccessToken, err := GenerateJWT(userID, role, 24*time.Hour)
		if err != nil {
			return nil, fmt.Errorf("failed to generate new access token: %w", err)
		}

		return &model.AuthResponse{
			AccessToken:  newAccessToken,
			RefreshToken: refreshToken,
		}, nil
	}

	return nil, fmt.Errorf("invalid refresh token")
}

// VerifyOTP xác minh OTP
func (s *AuthService) VerifyOTP(ctx context.Context, userID, otpCode string) error {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

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

// GetUserProfile lấy thông tin profile của người dùng
func (s *AuthService) GetUserProfile(ctx context.Context, userID string) (*model.User, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	user, err := s.UserRepo.GetUserByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch user: %w", err)
	}

	// Nếu avatar_url rỗng, trả về ảnh mặc định
	if user.AvatarURL == "" {
		user.AvatarURL = "/avatars/default.jpg"
	}

	// Tạo URL đầy đủ
	baseURL := "http://localhost:8080" // Thay bằng domain thực tế khi triển khai
	user.AvatarURL = baseURL + user.AvatarURL

	return user, nil
}

// UpdateAvatar cập nhật avatar
func (s *AuthService) UpdateAvatar(ctx context.Context, userID string, file *multipart.FileHeader, saveFileFunc func(*multipart.FileHeader, string) error) (*model.User, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	// Kiểm tra kích thước file (giới hạn 5MB)
	if file.Size > 5*1024*1024 {
		return nil, fmt.Errorf("file size exceeds 5MB limit")
	}

	// Chuẩn hóa định dạng về .jpg
	ext := strings.ToLower(filepath.Ext(file.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" {
		return nil, fmt.Errorf("only JPG, JPEG, or PNG files are allowed")
	}
	ext = ".jpg" // Luôn lưu dưới dạng .jpg để nhất quán

	// Tạo tên file và đường dẫn
	avatarDir := "public/avatars/"
	filename := fmt.Sprintf("%s%s", userID, ext)
	filepath := fmt.Sprintf("%s%s", avatarDir, filename)

	// Xóa tất cả tệp avatar cũ liên quan đến userID
	files, err := os.ReadDir(avatarDir)
	if err == nil { // Chỉ chạy nếu thư mục tồn tại
		for _, f := range files {
			if strings.HasPrefix(f.Name(), userID) {
				oldFilePath := avatarDir + f.Name()
				if err := os.Remove(oldFilePath); err != nil && !os.IsNotExist(err) {
					fmt.Printf("Failed to delete old avatar %s: %v\n", oldFilePath, err)
				}
			}
		}
	} else if !os.IsNotExist(err) {
		return nil, fmt.Errorf("failed to read avatars directory: %w", err)
	}

	// Đảm bảo thư mục tồn tại
	if err := os.MkdirAll(avatarDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create avatars directory: %w", err)
	}

	// Lưu file mới
	if err := saveFileFunc(file, filepath); err != nil {
		return nil, fmt.Errorf("failed to save avatar file: %w", err)
	}

	// Cập nhật database với đường dẫn mới
	avatarURL := fmt.Sprintf("/avatars/%s", filename)
	user, err := s.UserRepo.UpdateAvatar(ctx, userID, avatarURL)
	if err != nil {
		return nil, fmt.Errorf("failed to update avatar in database: %w", err)
	}

	// Tạo URL đầy đủ
	baseURL := "http://localhost:8080" // Thay bằng domain thực tế khi triển khai
	user.AvatarURL = baseURL + user.AvatarURL

	return user, nil
}

// GetAvatarPath lấy đường dẫn file avatar
func (s *AuthService) GetAvatarPath(ctx context.Context, userID string) (string, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	user, err := s.UserRepo.GetUserByID(ctx, userID)
	if err != nil {
		return "", fmt.Errorf("failed to fetch user: %w", err)
	}

	avatarPath := "public/avatars/default.jpg"
	if user.AvatarURL != "" {
		avatarPath = "public/" + strings.TrimPrefix(user.AvatarURL, "/")
	}

	if _, err := os.Stat(avatarPath); os.IsNotExist(err) {
		avatarPath = "public/avatars/default.jpg"
	}

	return avatarPath, nil
}

// UpdateUsername cập nhật username
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

	// Kiểm tra username đã tồn tại chưa
	existingUser, err := s.UserRepo.FindUserByUsername(ctx, username)
	if err != nil && err != sql.ErrNoRows {
		return nil, fmt.Errorf("failed to check username availability: %w", err)
	}
	if existingUser != nil && existingUser.ID != userID {
		return nil, fmt.Errorf("username already taken")
	}

	// Cập nhật username
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

// GetAllUsers lấy danh sách tất cả người dùng
func (s *AuthService) GetAllUsers(ctx context.Context) ([]*model.User, error) {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	users, err := s.UserRepo.GetAllUsers(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch all users: %w", err)
	}

	return users, nil
}

// DeleteUser xóa người dùng
func (s *AuthService) DeleteUser(ctx context.Context, userID string) error {
	ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	// Bắt đầu giao dịch
	tx, err := s.UserRepo.DB().BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("failed to start transaction: %w", err)
	}
	defer tx.Rollback()

	// Xóa refresh tokens
	err = s.UserRepo.DeleteRefreshToken(ctx, userID)
	if err != nil {
		fmt.Printf("Failed to delete refresh tokens for user %s: %v\n", userID, err)
		// Tiếp tục dù lỗi này xảy ra
	}

	// Xóa OTPs
	err = s.OTPRepo.DeleteActiveOTPs(ctx, userID)
	if err != nil {
		fmt.Printf("Failed to delete active OTPs for user %s: %v\n", userID, err)
		// Tiếp tục dù lỗi này xảy ra
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

// GenerateJWT tạo JWT token
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

// generateOTP tạo mã OTP
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