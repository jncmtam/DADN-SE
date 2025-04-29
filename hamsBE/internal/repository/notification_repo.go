package repository

import (
	"context"
	"database/sql"
	"fmt"
	"hamstercare/internal/model"
)

type NotificationRepository struct{
	db *sql.DB
}

func NewNotificationRepository(db *sql.DB) *NotificationRepository {
	return &NotificationRepository{db: db}
}


// SaveNotification lưu thông báo vào cơ sở dữ liệu và trả về notification đã lưu (kiểu NotificationWS)
func (r *NotificationRepository) SaveNotification(ctx context.Context, notification *model.Notification) (*model.NotificationWS, error) {
	query := `
		INSERT INTO notifications (user_id, cage_id, type, title, message)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, type, title, is_read, created_at
	`

	savedNotification := &model.NotificationWS{}
	err := r.db.QueryRowContext(
		ctx,
		query,
		notification.UserID,
		notification.CageID,
		notification.Type,
		notification.Title,
		notification.Message,
	).Scan(
		&savedNotification.ID,
		&savedNotification.Type,
		&savedNotification.Title,
		&savedNotification.IsRead,
		&savedNotification.Time,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to save notification: %w", err)
	}

	return savedNotification, nil
}

func (r *NotificationRepository) GetUserCageAndSensorBySensorID(ctx context.Context, sensorID string) (userID, cageID, sensorName string, err error) {
	query := `
		SELECT u.id, c.id, s.name
		FROM sensors s
		INNER JOIN cages c ON s.cage_id = c.id
		INNER JOIN users u ON c.user_id = u.id
		WHERE s.id = $1
	`

	row := r.db.QueryRowContext(ctx, query, sensorID)
	err = row.Scan(&userID, &cageID, &sensorName)
	if err != nil {
		if err == sql.ErrNoRows {
			return "", "", "", nil // Không tìm thấy hoặc sensor không có cage => trả về rỗng
		}
		return "", "", "", fmt.Errorf("failed to get user, cage and sensor by sensorID: %w", err)
	}

	return userID, cageID, sensorName, nil
}
