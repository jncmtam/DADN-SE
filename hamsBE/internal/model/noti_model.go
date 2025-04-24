package model

import "time"

// Notification represents a notification stored in the database.
type Notification struct {
    ID        int       `json:"id"`
    UserID    string    `json:"user_id"`
    CageID    string    `json:"cage_id"`
    Type      string    `json:"type"`
    Message   string    `json:"message"`
    IsRead    bool      `json:"is_read"`
    CreatedAt time.Time `json:"created_at"`
}