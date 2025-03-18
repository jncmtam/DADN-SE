// internal/repository/otp.go
package repository

import (
	"database/sql"
	"github.com/google/uuid"
	"hamstercare/internal/model"
	"time"
)

type OTPRepository struct {
	DB *sql.DB
}

func NewOTPRepository(db *sql.DB) *OTPRepository {
	return &OTPRepository{DB: db}
}

// NewOTPRequest tạo một bản ghi OTP mới với các giá trị mặc định
func (r *OTPRepository) NewOTPRequest(userID, otpCode string, expiresIn time.Duration) *model.OTPRequest {
	return &model.OTPRequest{
		ID:        uuid.New().String(),       // Tạo UUID mới
		UserID:    userID,                    // ID của user
		OTPCode:   otpCode,                   // Mã OTP (6 chữ số)
		ExpiresAt: time.Now().Add(expiresIn), // Thời gian hết hạn
		IsUsed:    false,                     // Mặc định chưa dùng
		CreatedAt: time.Now(),                // Thời gian tạo
	}
}

// CreateOTP lưu bản ghi OTP vào database
func (r *OTPRepository) CreateOTP(otp *model.OTPRequest) error {
	query := `INSERT INTO otp_request (id, user_id, otp_code, expires_at, is_used, created_at) 
             VALUES ($1, $2, $3, $4, $5, $6)`
	_, err := r.DB.Exec(query, otp.ID, otp.UserID, otp.OTPCode, otp.ExpiresAt, otp.IsUsed, otp.CreatedAt)
	return err
}

// GetValidOTP lấy OTP hợp lệ (chưa dùng và chưa hết hạn)
func (r *OTPRepository) GetValidOTP(userID, otpCode string) (*model.OTPRequest, error) {
	var otp model.OTPRequest
	query := `SELECT id, user_id, otp_code, expires_at, is_used, created_at 
             FROM otp_request 
             WHERE user_id = $1 AND otp_code = $2 AND is_used = FALSE AND expires_at > NOW()`
	err := r.DB.QueryRow(query, userID, otpCode).Scan(&otp.ID, &otp.UserID, &otp.OTPCode, &otp.ExpiresAt, &otp.IsUsed, &otp.CreatedAt)
	if err != nil {
		return nil, err
	}
	return &otp, nil
}
