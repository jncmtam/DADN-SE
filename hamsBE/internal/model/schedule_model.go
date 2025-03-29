package model

import "time"

type ScheduleRule struct {
	ID            string    `json:"id"`
	DeviceID      string    `json:"device_id"`
	ExecutionTime string    `json:"execution_time"`
	Days          []string  `json:"days"`
	Action        string    `json:"action"`
	CreatedAt     time.Time `json:"created_at"`
}

type ScheduleResGetByDeviceID struct {
	ID            string    `json:"id"`
	ExecutionTime string    `json:"execution_time"`
	Days          []string  `json:"days"`
	Action        string    `json:"action"`
}