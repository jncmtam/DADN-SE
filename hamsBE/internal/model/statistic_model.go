package model

import (
	"time"
	"github.com/google/uuid"
)

type Statistic struct {
	ID            uuid.UUID `json:"id"`
	CageID        uuid.UUID `json:"cage_id"`
	WaterRefillSl int       `json:"water_refill_sl"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}