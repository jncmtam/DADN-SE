package model

import "time"

type User struct {
	ID              string    `json:"id"`
	Username        string    `json:"username"`
	Email           string    `json:"email"`
	PasswordHash    string    `json:""`
	OTPSecret       string    `json:""`
	IsEmailVerified bool      `json:"is_email_verified"`
	Role            string    `json:"role"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}
