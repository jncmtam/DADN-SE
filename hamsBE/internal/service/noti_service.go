package service

import (
	"context"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
	ws "hamstercare/internal/websocket"
	"log"
)

type NotiService struct {
	CageRepo *repository.CageRepository
	UserRepo *repository.UserRepository
	NotiRepo *repository.NotificationRepository
}

func NewNotiService(cageRepo *repository.CageRepository, UserRepo *repository.UserRepository, NotiRepo *repository.NotificationRepository) *NotiService {
	return &NotiService{CageRepo: cageRepo, UserRepo: UserRepo, NotiRepo: NotiRepo}
}

func (s *NotiService) SendNotificationToUser(ctx context.Context, userID, cageID, title, notifType, message string) error {
	
	// Tạo một thông báo mới
	notification := &model.Notification{
		UserID:    userID,
		CageID:    cageID, 
		Type:      notifType,
		Title:     title,
		Message:   message,
	}

	// Lưu thông báo vào cơ sở dữ liệu và nhận về bản ghi đã lưu
	savedNotification, err := s.NotiRepo.SaveNotification(ctx, notification)
	if err != nil {
		return fmt.Errorf("failed to save notification: %w", err)
	}

	// Gửi thông báo qua WebSocket đến người dùng
	if err := ws.SendNotificationToUser(userID, savedNotification); err != nil {
		log.Printf("[ERROR] Failed to send notification to user %s: %v", userID, err)
		return fmt.Errorf("failed to send notification: %w", err)
	}

	log.Printf("[INFO] Notification sent to user %s", userID)
	return nil
}


func (s *NotiService) SendNotiToUserWithSensorID(ctx context.Context, sensorID, sensorType string, value float64) error {
	// Lấy userID, cageID, sensorName từ sensorID
	userID, cageID, sensorName, err := s.NotiRepo.GetUserCageAndSensorBySensorID(ctx, sensorID)
	if err != nil {
		return fmt.Errorf("failed to get user, cage, and sensor info: %w", err)
	}

	// Nếu thiếu userID hoặc cageID thì không gửi, nhưng cũng không lỗi
	if userID == "" || cageID == "" {
		log.Printf("[INFO] Sensor %s is not linked to a cage or user, skipping notification.", sensorID)
		return nil
	}

	var (
		title     string
		message   string
		notifType string
	)

	// Xử lý theo loại sensor và giá trị đo được
	switch sensorType {
	case "temperature":
		if value > 35 {
			notifType = "warning"
			title = fmt.Sprintf("%s: High temperature detected", sensorName)
			message = fmt.Sprintf("The temperature has reached %.1f°C, which is above the safe threshold.", value)
		}
	case "humidity":
		if value > 80 {
			notifType = "warning"
			title = fmt.Sprintf("%s: High humidity detected", sensorName)
			message = fmt.Sprintf("The humidity level has reached %.1f%%, which is above the safe threshold.", value)
		}
	case "water":
		if value/50.0 *100 < 20 {
			notifType = "warning"
			title = fmt.Sprintf("%s: Water level low", sensorName)
			message = fmt.Sprintf("The water level is critically low at %.1f%%.", value/50.0*100)
		}
	default:
		// Nếu sensor type không hỗ trợ thì bỏ qua
		return nil
	}

	// Nếu không cần gửi thì bỏ qua
	if title == "" || message == "" {
		return nil
	}

	// Tạo một thông báo mới
	notification := &model.Notification{
		UserID:  userID,
		CageID:  cageID,
		Type:    notifType,
		Title:   title,
		Message: message,
	}

	// Lưu thông báo vào cơ sở dữ liệu
	savedNotification, err := s.NotiRepo.SaveNotification(ctx, notification)
	if err != nil {
		return fmt.Errorf("failed to save notification: %w", err)
	}

	// Gửi notification qua WebSocket
	if err := ws.SendNotificationToUser(userID, savedNotification); err != nil {
		log.Printf("[ERROR] Failed to send notification to user %s: %v", userID, err)
		return fmt.Errorf("failed to send notification: %w", err)
	}

	log.Printf("[INFO] Notification sent to user %s", userID)
	return nil
}

