package websocket

import (
	"fmt"
	"hamstercare/internal/model"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

// Struct lưu thông tin client đang mở kết nối
type NotificationClient struct {
	UserID string
	Conn   *websocket.Conn
}

// Map userID -> list các websocket connection
var notificationClients = make(map[string][]*NotificationClient)
var notifLock sync.RWMutex

// Hàm để client kết nối WebSocket nhận thông báo
func StreamNotifications(userID string, w http.ResponseWriter, r *http.Request) error {
	log.Printf("[INFO] WebSocket notification connection attempt for userID: %s", userID)

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("[ERROR] Failed to upgrade notification connection: %v", err)
		return fmt.Errorf("failed to upgrade notification connection: %w", err)
	}
	defer conn.Close()

	client := &NotificationClient{
		UserID: userID,
		Conn:   conn,
	}

	// Add client vào danh sách
	addNotificationClient(client)
	defer removeNotificationClient(client)

	log.Printf("[INFO] WebSocket notification connection established for userID: %s", userID)

	// Lắng nghe ping/pong, giữ connection sống
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			log.Printf("[INFO] Notification connection closed for userID: %s", userID)
			break
		}
	}

	return nil
}

// Gửi thông báo tới tất cả connections của 1 user
func SendNotificationToUser(userID string, message *model.NotificationWS) error {
	notifLock.RLock()
	defer notifLock.RUnlock()

	conns := notificationClients[userID]
	if len(conns) == 0 {
		log.Printf("[WARN] No active notification connections for userID: %s", userID)
		return nil
	}

	for _, client := range conns {
		err := client.Conn.WriteJSON(message)
		if err != nil {
			log.Printf("[ERROR] Failed to send notification to userID %s: %v", userID, err)
			// không return lỗi luôn, cứ thử gửi tiếp các conn khác
		}
	}

	log.Printf("[INFO] Notification sent to userID: %s", userID)
	return nil
}

// --- Các hàm phụ trợ ---
func addNotificationClient(client *NotificationClient) {
	notifLock.Lock()
	defer notifLock.Unlock()

	notificationClients[client.UserID] = append(notificationClients[client.UserID], client)
}

func removeNotificationClient(client *NotificationClient) {
	notifLock.Lock()
	defer notifLock.Unlock()

	conns := notificationClients[client.UserID]
	newConns := []*NotificationClient{}
	for _, c := range conns {
		if c.Conn != client.Conn {
			newConns = append(newConns, c)
		}
	}

	if len(newConns) > 0 {
		notificationClients[client.UserID] = newConns
	} else {
		delete(notificationClients, client.UserID)
	}
}
