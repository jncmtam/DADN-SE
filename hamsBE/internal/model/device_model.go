package model

import "time"

type Device struct {
	ID         string    `json:"id"`
	Name       string    `json:"name"`
	Type       string    `json:"type"`
	Status     string    `json:"status"`
	LastStatus string    `json:"last_status"`
	CageID     string    `json:"cage_id"`
	CreatedAt  time.Time `json:"created_at"`
	UpdatedAt  time.Time `json:"updated_at"`
}
type DeviceControl struct {
	Value string `json:"value"`
}
type DeviceResponse struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	CageID string `json:"cage_id"`
	Status string `json:"status"`
	Type   string `json:"type"`
}

type DeviceListResponse struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}
