package model

import "time"

type Device struct {
	ID         string    `json:"id"`
	Name       string    `json:"name"`
	Type       string    `json:"type"`
	Status     string    `json:"status"`
	LastStatus string    `json:"last_status"`
	CageID     bool      `json:"cage_id"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}

type DeviceResponse struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Status   string `json:"status"`
	Type     string `json:"type"`
	LastMode string `json:"last_mode"`
	Mode     string `json:"mode"`
	CageID   bool   `json:"cage_id"`
	UserID   string `json:"user_id"`
}

type DeviceListResponse struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}
