package websocket

import (
	"context"
	"fmt"
	"hamstercare/internal/repository"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

// Upgrader config cho WebSocket
var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		origin := r.Header.Get("Origin")
		log.Printf("[INFO] WebSocket connection origin: %s", origin)
		// Đảm bảo rằng chỉ các origin hợp lệ mới được chấp nhận
		return true 
	},
}


// Hàm nhận cageID và connection, gửi dữ liệu cảm biến
func StreamSensorData(sensorRepo *repository.SensorRepository, cageID string, w http.ResponseWriter, r *http.Request) error {
	log.Printf("[INFO] WebSocket connection attempt for cageID: %s from %s", cageID, r.RemoteAddr)
	
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("[ERROR] Failed to upgrade connection: %v", err) 
		return fmt.Errorf("failed to upgrade connection: %w", err)
	}
	defer conn.Close()
	
	log.Printf("[INFO] WebSocket connection established for cageID: %s", cageID)
	
	// Tiến hành gửi dữ liệu cảm biến
	for {
		sensorData, err := getSensorData(sensorRepo, cageID)
		if err != nil {
			log.Printf("[ERROR] Failed to fetch sensor data for cageID %s: %v", cageID, err)
			return fmt.Errorf("failed to fetch sensor data: %w", err)
		}

		log.Printf("[INFO] Sending sensor data for cageID %s: %v", cageID, sensorData)

		if err := conn.WriteJSON(sensorData); err != nil {
			log.Printf("[ERROR] Failed to send sensor data for cageID %s: %v", cageID, err)
			return fmt.Errorf("failed to send sensor data: %w", err)
		}

		log.Printf("[INFO] Sensor data sent for cageID %s", cageID)

		// Chờ 5 giây trước khi gửi dữ liệu tiếp theo
		time.Sleep(5 * time.Second)
	}
}


// Phương thức lấy dữ liệu cảm biến từ SensorRepository
func getSensorData(sensorRepo *repository.SensorRepository, cageID string) (map[string]float64, error) {
	// Lấy dữ liệu cảm biến từ repository dựa trên cageID
	sensorData, err := sensorRepo.GetSensorsValuesByCage(context.Background(), cageID)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch sensor data from repository: %w", err)
	}

	return sensorData, nil
}

