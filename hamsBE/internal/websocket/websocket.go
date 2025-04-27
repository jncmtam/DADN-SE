package websocket

import (
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

type Client struct {
	UserID string
	CageID string
	Type   string
	Conn   *websocket.Conn
	Send   chan []byte
	mu     sync.Mutex // Thêm mutex để bảo vệ ghi
}

type Hub struct {
	Clients    map[*Client]bool
	Broadcast  chan Message
	Register   chan *Client
	Unregister chan *Client
}

type Message struct {
	UserID   string                 `json:"user_id"`
	CageID   string                 `json:"cage_id"`
	Type     string                 `json:"type"`
	Title    string                 `json:"title"`
	SensorID string                 `json:"sensor_id"`
	Unit     string                 `json:"unit"`
	Message  string                 `json:"message"`
	Time     int64                  `json:"time"`
	Value    float64                `json:"value"`
	Data     map[string]interface{} `json:"data"`
}
type NotificationMessage struct {
	ID        string `json:"id"`        // UUID của thông báo
	Title     string `json:"title"`     // Tiêu đề thông báo, ví dụ: "Cage 1: High Temperature Alert"
	Timestamp string `json:"timestamp"` // Thời gian định dạng RFC3339, ví dụ: "2025-01-17T20:30:00Z"
	Type      string `json:"type"`      // Loại thông báo: "warning" hoặc "info"
	Read      bool   `json:"read"`      // Trạng thái đọc: false (chưa đọc) hoặc true (đã đọc)
}
type SensorMessage struct {
	SensorID string             `json:"sensorId"` // Loại cảm biến, ví dụ: "temperature", "water_level"
	Values   map[string]float64 `json:"-"`        // Map chứa cặp { sensorID: value }, không mã hóa trực tiếp vào JSON
}

func NewHub() *Hub {
	return &Hub{
		Broadcast:  make(chan Message, 3000),
		Register:   make(chan *Client),
		Unregister: make(chan *Client),
		Clients:    make(map[*Client]bool),
	}
}
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.Clients[client] = true
			log.Printf("[INFO] Client registered: userID=%s, cageID=%s, type=%s", client.UserID, client.CageID, client.Type)
		case client := <-h.Unregister:
			if _, ok := h.Clients[client]; ok {
				close(client.Send)
				delete(h.Clients, client)
				log.Printf("[INFO] Client unregistered: userID=%s, cageID=%s, type=%s", client.UserID, client.CageID, client.Type)
			}
		case message := <-h.Broadcast:
			if message.Data == nil {
				message.Data = make(map[string]interface{})
			}
			data, err := json.Marshal(message)
			if err != nil {
				log.Printf("[ERROR] Error marshaling message: type=%s, title=%s, err=%v", message.Type, message.Title, err)
				continue
			}
			for client := range h.Clients {
				// Gửi nếu khớp UserID, CageID và Type
				if client.UserID == message.UserID && client.CageID == message.CageID &&
					client.Type == "all" &&
					(message.Type == "warning" || message.Type == "device_status_change" || message.Type == "info" || message.Type == "sensor") {
					select {
					case client.Send <- data:
						log.Printf("[INFO] Broadcast message to client: userID=%s, cageID=%s, type=%s, title=%s", client.UserID, client.CageID, message.Type, message.Title)
					default:
						log.Printf("[WARNING] Client send channel full, closing: userID=%s, cageID=%s", client.UserID, client.CageID)
						close(client.Send)
						delete(h.Clients, client)
					}
				}
			}
		}
	}
}

func (c *Client) WritePump() {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[ERROR] Panic in WritePump: userID=%s, cageID=%s, type=%s, err=%v", c.UserID, c.CageID, c.Type, r)
		}
		c.Conn.Close()
	}()
	ticker := time.NewTicker(60 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case message, ok := <-c.Send:
			if !ok {
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
				log.Printf("[ERROR] Error writing message to client: userID=%s, cageID=%s, type=%s, err=%v", c.UserID, c.CageID, c.Type, err)
				return
			}
		case <-ticker.C:
			log.Printf("[INFO] Client timeout: userID=%s, cageID=%s, type=%s", c.UserID, c.CageID, c.Type)
			return
		}
	}
}

func (c *Client) ReadPump(hub *Hub) {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("[ERROR] Panic in ReadPump: userID=%s, cageID=%s, type=%s, err=%v", c.UserID, c.CageID, c.Type, r)
		}
		hub.Unregister <- c
		c.Conn.Close()
	}()
	for {
		_, _, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("[ERROR] Error reading message: userID=%s, cageID=%s, type=%s, err=%v", c.UserID, c.CageID, c.Type, err)
			}
			break
		}
	}
}
