// websocket/websocket.go
package websocket

import (
    "encoding/json"
    "log"
    "time"
    "github.com/gorilla/websocket"
)

type Client struct {
    UserID string
    CageID string
    Type   string // "sensor" or "notification"
    Conn   *websocket.Conn
    Send   chan []byte
}

type Message struct {
    UserID  string  `json:"user_id"`
    CageID  string  `json:"cage_id"`
    Type    string  `json:"type"`
    Title   string  `json:"title"`
    Message string  `json:"message"`
    Time    int64   `json:"time"`
    Value   float64 `json:"value"`
}

type Hub struct {
    Clients    map[*Client]bool
    Broadcast  chan Message
    Register   chan *Client
    Unregister chan *Client
}

func NewHub() *Hub {
    return &Hub{
        Clients:    make(map[*Client]bool),
        Broadcast:  make(chan Message),
        Register:   make(chan *Client),
        Unregister: make(chan *Client),
    }
}

func (h *Hub) Run() {
    for {
        select {
        case client := <-h.Register:
            h.Clients[client] = true
            log.Printf("Client registered: UserID=%s, CageID=%s, Type=%s", client.UserID, client.CageID, client.Type)
        case client := <-h.Unregister:
            if _, ok := h.Clients[client]; ok {
                close(client.Send)
                delete(h.Clients, client)
                log.Printf("Client unregistered: UserID=%s, CageID=%s, Type=%s", client.UserID, client.CageID, client.Type)
            }
        case message := <-h.Broadcast:
            for client := range h.Clients {
                if client.UserID == message.UserID && (client.CageID == message.CageID || client.CageID == "") {
                    if (client.Type == "notification" && message.Type != "sensor_data") ||
                        (client.Type == "sensor" && message.Type == "sensor_data") {
                        data, _ := json.Marshal(message)
                        select {
                        case client.Send <- data:
                        default:
                            close(client.Send)
                            delete(h.Clients, client)
                        }
                    }
                }
            }
        }
    }
}

func (c *Client) WritePump() {
    ticker := time.NewTicker(10 * time.Second)
    defer func() {
        ticker.Stop()
        c.Conn.Close()
    }()
    for {
        select {
        case message, ok := <-c.Send:
            c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
            if !ok {
                c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
                return
            }
            if err := c.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
                return
            }
        case <-ticker.C:
            c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
            if err := c.Conn.WriteMessage(websocket.PingMessage, nil); err != nil {
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
            break
        }
    }
}