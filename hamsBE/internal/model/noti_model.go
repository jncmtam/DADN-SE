package model

import (
	"time"
	"github.com/google/uuid"
)

type Notification struct {
	ID        uuid.UUID `json:"id"`
	UserID    uuid.UUID `json:"user_id"`
	CageID    uuid.UUID `json:"cage_id"`
	Type      string    `json:"type"` // "info", "warning", "high_water_usage"
	Title     string    `json:"title"`
	Message   string    `json:"message"`
	IsRead    bool      `json:"is_read"`
    Time      int64     `json:"time"` 
	CreatedAt time.Time `json:"created_at"`
}