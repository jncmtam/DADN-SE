package model

import "time"

type AutomationRule struct {
    ID        string    `json:"id"`
    SensorID  string    `json:"sensor_id"`
    DeviceID  string    `json:"device_id"`
    CageID    string    `json:"cage_id"`
    Condition string    `json:"condition"`
    Threshold float64   `json:"threshold"`
    Unit      string    `json:"unit,omitempty"`
    Action    string    `json:"action"`
    CreatedAt time.Time `json:"created_at"`
    UpdatedAt time.Time `json:"updated_at"`
}

type AutoRuleResByDeviceID struct {
    ID        string  `json:"id"`
    SensorID  string  `json:"sensor_id"`
    Condition string  `json:"condition"`
    Threshold float64 `json:"threshold"`
    Unit      string  `json:"unit,omitempty"`
    Action    string  `json:"action"`
}