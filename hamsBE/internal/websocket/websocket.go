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

func NewHub() *Hub {
    return &Hub{
        Broadcast:  make(chan Message, 1000),
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
            log.Printf("Client registered: userID=%s, cageID=%s", client.UserID, client.CageID)
        case client := <-h.Unregister:
            if _, ok := h.Clients[client]; ok {
                close(client.Send)
                delete(h.Clients, client)
                log.Printf("Client unregistered: userID=%s, cageID=%s", client.UserID, client.CageID)
            }
        case message := <-h.Broadcast:
            data, err := json.Marshal(message)
            if err != nil {
                log.Printf("Error marshaling message: %v", err)
                continue
            }
            for client := range h.Clients {
                if client.UserID == message.UserID && client.CageID == message.CageID && client.Type == message.Type {
                    select {
                    case client.Send <- data:
                        log.Printf("Broadcast message to client: userID=%s, cageID=%s, type=%s", client.UserID, client.CageID, message.Type)
                    default:
                        log.Printf("Client send channel full, closing: userID=%s, cageID=%s", client.UserID, client.CageID)
                        close(client.Send)
                        delete(h.Clients, client)
                    }
                }
            }
        }
    }
}

func (c *Client) WritePump() {
    ticker := time.NewTicker(30 * time.Second)
    defer func() {
        ticker.Stop()
        c.mu.Lock()
        c.Conn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
        c.Conn.Close()
        c.mu.Unlock()
        log.Printf("WritePump stopped for client: userID=%s, cageID=%s", c.UserID, c.CageID)
    }()

    for {
        select {
        case message, ok := <-c.Send:
            c.mu.Lock()
            c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
            if !ok {
                c.Conn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
                c.mu.Unlock()
                return
            }
            w, err := c.Conn.NextWriter(websocket.TextMessage)
            if err != nil {
                log.Printf("Error getting writer for client %s: %v", c.UserID, err)
                c.mu.Unlock()
                return
            }
            if _, err := w.Write(message); err != nil {
                log.Printf("Error writing message for client %s: %v", c.UserID, err)
                c.mu.Unlock()
                return
            }
            if err := w.Close(); err != nil {
                log.Printf("Error closing writer for client %s: %v", c.UserID, err)
                c.mu.Unlock()
                return
            }
            log.Printf("Sent WebSocket message to client %s", c.UserID)
            c.mu.Unlock()
        case <-ticker.C:
            c.mu.Lock()
            c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
            if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
                log.Printf("Error sending ping for client %s: %v", c.UserID, err)
                c.mu.Unlock()
                return
            }
            c.mu.Unlock()
        }
    }
}

func (c *Client) ReadPump(hub *Hub) {
    defer func() {
        hub.Unregister <- c
        c.mu.Lock()
        c.Conn.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
        c.Conn.Close()
        c.mu.Unlock()
        log.Printf("ReadPump stopped for client: userID=%s, cageID=%s", c.UserID, c.CageID)
    }()
    c.Conn.SetReadLimit(512)
    c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
    c.Conn.SetPongHandler(func(string) error {
        c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
        return nil
    })
    for {
        _, _, err := c.Conn.ReadMessage()
        if err != nil {
            if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
                log.Printf("WebSocket error for client %s: %v", c.UserID, err)
            } else {
                log.Printf("WebSocket closed for client %s: %v", c.UserID, err)
            }
            break
        }
    }
}