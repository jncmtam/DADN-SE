package repository

import (
	"context"
	"database/sql"
	"time"
	"hamstercare/internal/database/queries"
	"hamstercare/internal/model"
)

type OTPRepository struct {
	db *sql.DB
}

func NewOTPRepository(db *sql.DB) *OTPRepository {
	return &OTPRepository{db: db}
}

func (r *OTPRepository) CreateOTPRequest(ctx context.Context, userID, otpCode string, expiresAt time.Time) (*model.OTPRequest, error) {
	otp := &model.OTPRequest{}
	query, err := queries.GetQuery("create_otp_request")
	if err != nil {
		return nil, err
	}
	err = r.db.QueryRowContext(ctx, query, userID, otpCode, expiresAt).Scan(
		&otp.ID, &otp.UserID, &otp.OTPCode, &otp.ExpiresAt, &otp.CreatedAt,
	)
	if err != nil {
		return nil, err
	}
	return otp, nil
}

func (r *OTPRepository) VerifyOTP(ctx context.Context, userID, otpCode string) (*model.OTPRequest, error) {
	otp := &model.OTPRequest{}
	query, err := queries.GetQuery("verify_otp")
	if err != nil {
		return nil, err
	}
	err = r.db.QueryRowContext(ctx, query, userID, otpCode).Scan(
		&otp.ID, &otp.UserID, &otp.OTPCode, &otp.ExpiresAt, &otp.IsUsed,
	)
	if err != nil {
		return nil, err
	}
	return otp, nil
}

func (r *OTPRepository) MarkOTPAsUsed(ctx context.Context, otpID string) (*model.OTPRequest, error) {
	otp := &model.OTPRequest{}
	query, err := queries.GetQuery("mark_otp_as_used")
	if err != nil {
		return nil, err
	}
	err = r.db.QueryRowContext(ctx, query, otpID).Scan(
		&otp.ID, &otp.UserID, &otp.OTPCode, &otp.IsUsed,
	)
	if err != nil {
		return nil, err
	}
	return otp, nil
}

func (r *OTPRepository) DeleteActiveOTPs(ctx context.Context, userID string) error {
	query, err := queries.GetQuery("delete_active_otps")
	if err != nil {
		return err
	}
	_, err = r.db.ExecContext(ctx, query, userID)
	return err
}