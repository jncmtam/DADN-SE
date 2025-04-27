package model

// Message represents a WebSocket message for real-time updates
type Message struct {
	UserID   string      `json:"user_id"`   // ID of the user
	Type     string      `json:"type"`      // Message type: "sensor_data", "info", "warning", "high_water_usage", "device_status_change"
	Title    string      `json:"title"`     // Title of the message (for notifications)
	Message  string      `json:"message"`   // Content of the message (for notifications)
	CageID   string      `json:"cage_id"`   // ID of the cage
	SensorID string      `json:"sensor_id"` // Sensor ID (for sensor_data)
	DeviceID string      `json:"device_id"` // Device ID (for info, device_status_change)
	Time     int64       `json:"time"`      // Unix timestamp of the message
	Value    float64     `json:"value"`     // Value associated with the message (e.g., sensor reading)
	Unit     string      `json:"unit"`      // Unit of the value (e.g., °C, %, etc.)
	Status   string      `json:"status"`    // Status of the device (e.g., "on", "off" for device_status_change, info)
}
