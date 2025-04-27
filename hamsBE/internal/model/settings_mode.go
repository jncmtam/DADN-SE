package model

import (
	"time"
	"github.com/google/uuid"
)

type Setting struct {
	CageID                uuid.UUID `json:"cage_id"`
	HighWaterUsageThreshold int     `json:"high_water_usage_threshold"`
	CreatedAt             time.Time `json:"created_at"`
	UpdatedAt             time.Time `json:"updated_at"`
}