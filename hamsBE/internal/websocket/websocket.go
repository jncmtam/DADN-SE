package websocket

import (
    "encoding/json"
    "log"
    "time"

    "github.com/gorilla/websocket"
)

type Hub struct {
    Clients    map[*Client]bool
    Broadcast  chan Message
    Register   chan *Client
    Unregister chan *Client
}

type Client struct {
    UserID string
    CageID string
    Conn   *websocket.Conn
    Send   chan []byte
}

type Message struct {
    UserID  string  `json:"user_id"`
    Type    string  `json:"type"`
    Title   string  `json:"title"`
    Message string  `json:"message"` // Fixed typo
    CageID  string  `json:"cage_id"`
    Time    int64   `json:"time"`
    Value   float64 `json:"value"`
}

type Notification struct {
    ID        string    `json:"id"`
    UserID    string    `json:"user_id"`
    Type      string    `json:"type"`
    Title     string    `json:"title"`
    Message   string    `json:"message"`
    CageID    string    `json:"cage_id"`
    Time      int64     `json:"time"`
    IsRead    bool      `json:"is_read"`
    CreatedAt time.Time `json:"created_at"`
}

func NewHub() *Hub {
    return &Hub{
        Broadcast:  make(chan Message, 100), // Buffered channel
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
            log.Printf("Client registered for user %s, cage %s", client.UserID, client.CageID)
        case client := <-h.Unregister:
            if _, ok := h.Clients[client]; ok {
                close(client.Send)
                delete(h.Clients, client)
                log.Printf("Client unregistered for user %s, cage %s", client.UserID, client.CageID)
            }
        case message := <-h.Broadcast:
            for client := range h.Clients {
                // Broadcast to clients with matching CageID or no CageID (for global notifications)
                if client.CageID == message.CageID || client.CageID == "" {
                    msg := marshalMessage(message)
                    if msg == nil {
                        log.Printf("Skipping nil message for client %s", client.UserID)
                        continue
                    }
                    select {
                    case client.Send <- msg:
                    default:
                        close(client.Send)
                        delete(h.Clients, client)
                    }
                }
            }
        }
    }
}

func marshalMessage(data interface{}) []byte {
    msg, err := json.Marshal(data)
    if err != nil {
        log.Printf("Error marshaling WebSocket message: %v", err)
        return nil
    }
    return msg
}

func (c *Client) WritePump() {
    defer func() {
        c.Conn.Close()
    }()
    for {
        select {
        case message, ok := <-c.Send:
            if !ok {
                c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
                return
            }
            c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
            if err := c.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
                log.Printf("Error writing WebSocket message: %v", err)
                return
            }
        }
    }
}

func (c *Client) ReadPump(hub *Hub) {
    defer func() {
        hub.Unregister <- c
        c.Conn.Close()
    }()
    for {
        _, _, err := c.Conn.ReadMessage()
        if err != nil {
            if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
                log.Printf("WebSocket error: %v", err)
            }
            break
        }
        // Handle incoming messages if needed
    }
}