package repository

import (
	"context"
	"database/sql"
	"fmt"
	"hamstercare/internal/model"
	// "time"
)

type NotificationRepository struct {
	db *sql.DB
}

func NewNotificationRepository(db *sql.DB) *NotificationRepository {
	return &NotificationRepository{db: db}
}

func (r *NotificationRepository) CreateNotification(ctx context.Context, n *model.Notification) error {
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO notifications (id, user_id, type, title, message, cage_id, time, is_read, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`,  n.ID, n.UserID, n.Type, n.Title, n.Message, n.CageID, n.Time, n.IsRead, n.CreatedAt)
	if err != nil {
		return fmt.Errorf("failed to create notification: %w", err)
	}
	return nil
}
func (r *NotificationRepository) GetNotifications(ctx context.Context, userID, cageID string, isRead *bool, limit, offset int) ([]*model.Notification, error) {
	query := `
		SELECT id, user_id, cage_id, message, type, is_read, created_at
		FROM notifications
		WHERE user_id = $1
	`
	args := []interface{}{userID}
	argCount := 2

	if cageID != "" {
		query += fmt.Sprintf(" AND cage_id = $%d", argCount)
		args = append(args, cageID)
		argCount++
	}
	if isRead != nil {
		query += fmt.Sprintf(" AND is_read = $%d", argCount)
		args = append(args, *isRead)
		argCount++
	}

	query += fmt.Sprintf(" ORDER BY created_at DESC LIMIT $%d OFFSET $%d", argCount, argCount+1)
	args = append(args, limit, offset)

	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to query notifications: %w", err)
	}
	defer rows.Close()

	var notifications []*model.Notification
	for rows.Next() {
		var n model.Notification
		if err := rows.Scan(&n.ID, &n.UserID, &n.CageID, &n.Message, &n.Type, &n.IsRead, &n.CreatedAt); err != nil {
			continue
		}
		notifications = append(notifications, &n)
	}

	return notifications, nil
}
// GetByUserID retrieves notifications for a user
func (r *NotificationRepository) GetByUserID(ctx context.Context, userID string, isRead *bool) ([]*model.Notification, error) {
	query := `
		SELECT id, user_id, type, title, message, cage_id, time, is_read, created_at
		FROM notifications
		WHERE user_id = $1
	`
	args := []interface{}{userID}
	if isRead != nil {
		query += " AND is_read = $2"
		args = append(args, *isRead)
	}
	query += " ORDER BY created_at DESC"

	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var notifications []*model.Notification
	for rows.Next() {
		n := &model.Notification{}
		if err := rows.Scan(&n.ID, &n.UserID, &n.Type, &n.Title, &n.Message, &n.CageID, &n.Time, &n.IsRead, &n.CreatedAt); err != nil {
			return nil, err
		}
		notifications = append(notifications, n)
	}
	return notifications, nil
}

func (r *NotificationRepository) MarkAsRead(ctx context.Context, notificationID, userID string) error {
	result, err := r.db.ExecContext(ctx, `
		UPDATE notifications
		SET is_read = true
		WHERE id = $1 AND user_id = $2
	`, notificationID, userID)
	if err != nil {
		return fmt.Errorf("failed to mark notification as read: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("error checking rows affected: %w", err)
	}
	if rowsAffected == 0 {
		return fmt.Errorf("notification not found or not owned by user")
	}

	return nil
}