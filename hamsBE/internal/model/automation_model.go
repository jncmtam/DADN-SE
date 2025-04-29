package model

import "time"

type AutomationRule struct {
	ID         string    `json:"id"`
	SensorID   string    `json:"sensor_id"`
	DeviceID   string    `json:"device_id"`
	Condition  string    `json:"condition"`
	Threshold  float64   `json:"threshold"`
	Unit       string    `json:"unit"`
	Action     string    `json:"action"`
	CreatedAt  time.Time `json:"created_at"`
}

type AutoRuleResByDeviceID struct {
	ID         string    `json:"id"`
	SensorID   string    `json:"sensor_id"`
	SensorType string	 `json:"sensor_type"`
	Condition  string    `json:"condition"`
	Threshold  float64   `json:"threshold"`
	Unit       string    `json:"unit"`
	Action     string    `json:"action"`
}

type AutoRuleResBySensorID struct {
    ID          string  `json:"id"`
    UserID      string  `json:"user_id"`
    CageID      string  `json:"cage_id"`
    SensorID    string  `json:"sensor_id"`
    SensorType  string  `json:"sensor_type"`
    Condition   string  `json:"condition"`
    Threshold   float64 `json:"threshold"`
    Unit        string  `json:"unit"`
    Action      string  `json:"action"`
    DeviceType  string  `json:"device_type"`
}
