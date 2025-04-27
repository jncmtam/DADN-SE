package service

import (
	"context"
	"errors"
	"fmt"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
)

type NotificationService struct {
	NotificationRepo *repository.NotificationRepository
}

func NewNotificationService(notificationRepo *repository.NotificationRepository) *NotificationService {
	return &NotificationService{NotificationRepo: notificationRepo}
}

func (s *NotificationService) GetNotifications(ctx context.Context, userID, cageID string, isRead *bool, page, pageSize int) ([]*model.Notification, error) {
	if userID == "" {
		return nil, errors.New("userID is required")
	}
	if page < 1 || pageSize < 1 {
		return nil, errors.New("invalid page or pageSize")
	}

	limit := pageSize
	offset := (page - 1) * pageSize

	notifications, err := s.NotificationRepo.GetNotifications(ctx, userID, cageID, isRead, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get notifications: %w", err)
	}

	return notifications, nil
}

func (s *NotificationService) MarkAsRead(ctx context.Context, notificationID, userID string) error {
	if notificationID == "" || userID == "" {
		return errors.New("notificationID and userID are required")
	}

	return s.NotificationRepo.MarkAsRead(ctx, notificationID, userID)
}