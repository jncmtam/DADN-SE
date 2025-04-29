package model

import (
	"time"
)

type Notification struct {
	ID        string `json:"id"`
	UserID    string `json:"user_id"`
	CageID    string `json:"cage_id"`
	Type      string    `json:"type"` // "info", "warning", "high_water_usage"
	Title     string    `json:"title"`
	Message   string    `json:"message"`
	IsRead    bool      `json:"is_read"`
    Time      int64     `json:"time"` 
	CreatedAt time.Time `json:"created_at"`
}

type NotificationWS struct {
	ID        string `json:"id"`
	Type      string    `json:"type"` 
	Title     string    `json:"title"`
	IsRead    bool      `json:"is_read"`
    Time      time.Time  `json:"time"` 
}