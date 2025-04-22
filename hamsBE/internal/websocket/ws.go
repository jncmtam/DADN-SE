package websocket

import (
    "encoding/json"
    "hamstercare/internal/repository"
    "log"

    "github.com/gorilla/websocket"
)

// NotificationManager handles WebSocket notifications
type NotificationManager struct {
    clients    map[*websocket.Conn]string // Map of connections to user IDs
    broadcast  chan []byte                // Channel for broadcasting messages
    register   chan *websocket.Conn       // Channel for registering new clients
    unregister chan *websocket.Conn       // Channel for unregistering clients
    userRepo   *repository.UserRepository
}

// NewNotificationManager creates a new NotificationManager
func NewNotificationManager(userRepo *repository.UserRepository) *NotificationManager {
    return &NotificationManager{
        clients:    make(map[*websocket.Conn]string),
        broadcast:  make(chan []byte),
        register:   make(chan *websocket.Conn),
        unregister: make(chan *websocket.Conn),
        userRepo:   userRepo,
    }
}

// Run starts the WebSocket manager
func (m *NotificationManager) Run() {
    for {
        select {
        case client := <-m.register:
            m.clients[client] = ""
        case client := <-m.unregister:
            if _, ok := m.clients[client]; ok {
                delete(m.clients, client)
                client.Close()
            }
        case message := <-m.broadcast:
            for client := range m.clients {
                err := client.WriteMessage(websocket.TextMessage, message)
                if err != nil {
                    log.Printf("[ERROR] Error broadcasting message: %v", err)
                    client.Close()
                    delete(m.clients, client)
                }
            }
        }
    }
}

// HandleNotifications handles WebSocket connections for notifications
func (m *NotificationManager) HandleNotifications(ws *websocket.Conn, userID string) {
    m.register <- ws
    m.clients[ws] = userID

    for {
        _, _, err := ws.ReadMessage()
        if err != nil {
            m.unregister <- ws
            break
        }
    }
}

// BroadcastNotification sends a notification to all clients of a user
func (m *NotificationManager) BroadcastNotification(userID, message string) {
    data := map[string]string{"message": message}
    bytes, _ := json.Marshal(data)
    m.broadcast <- bytes
}