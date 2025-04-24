package websocket

import (
	"encoding/json"
	"log"
	"time"

	"github.com/gorilla/websocket"
)

// Hub maintains the set of active clients and broadcasts messages to the clients.
type Hub struct {
	// Registered clients.
	Clients map[*Client]bool

	// Inbound messages from the clients.
	Broadcast chan Message

	// Register requests from the clients.
	Register chan *Client

	// Unregister requests from clients.
	Unregister chan *Client
}

// Client is a websocket client.
type Client struct {
	UserID string
	CageID string
	Conn   *websocket.Conn
	Send   chan []byte
}

// Message is a message to broadcast to clients.
type Message struct {
	CageID string
	Data   interface{}
}

// Notification represents a notification message.
type Notification struct {
	Type    string `json:"type"`
	Message string `json:"message"`
	CageID  string `json:"cage_id"`
	Time    string `json:"time"`
}

// NewHub creates a new WebSocket hub.
func NewHub() *Hub {
	return &Hub{
		Broadcast:  make(chan Message),
		Register:   make(chan *Client),
		Unregister: make(chan *Client),
		Clients:    make(map[*Client]bool),
	}
}

// Run starts the WebSocket hub.
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
				if client.CageID == message.CageID {
					select {
					case client.Send <- marshalMessage(message.Data):
					default:
						close(client.Send)
						delete(h.Clients, client)
					}
				}
			}
		}
	}
}

// marshalMessage converts data to JSON bytes.
func marshalMessage(data interface{}) []byte {
	msg, err := json.Marshal(data)
	if err != nil {
		log.Printf("Error marshaling WebSocket message: %v", err)
		return nil
	}
	return msg
}

// WritePump pumps messages from the hub to the WebSocket connection.
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

// ReadPump pumps messages from the WebSocket connection to the hub.
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