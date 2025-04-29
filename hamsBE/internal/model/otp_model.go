package model

import "time"

type OTPRequest struct{
	ID string `json:"id"`
	UserID string `json:"user_id"`
	OTPCode string `json:"otp_code"`
	ExpiresAt time.Time `json:"expires_at"`
	IsUsed bool `json:"is_used"`
	CreatedAt time.Time `json:"created_at"`
}