package routes

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"hamstercare/internal/middleware"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
	"hamstercare/internal/service"
	"hamstercare/internal/websocket"
	"log"
	"net/http"
	"strconv"
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	gorillawebsocket "github.com/gorilla/websocket"
)

func SetWebsocketRoutes(r *gin.RouterGroup, db *sql.DB, wsHub *websocket.Hub, mqttClient mqtt.Client) {
	r.Use(middleware.JWTMiddleware())
	{
		cageRepo := repository.NewCageRepository(db)
		// Middleware xác thực JWT qua query parameter token
		authMiddleware := func(c *gin.Context) {
			tokenStr := c.Query("token")
			if tokenStr == "" {
				log.Printf("[ERROR] Missing token in query parameter")
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Missing token"})
				return
			}

			token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
				if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
				}
				return []byte("your-secret-key"), nil // Thay bằng secret key thực tế
			})
			if err != nil {
				log.Printf("[ERROR] Invalid token: %v", err)
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
				return
			}

			if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
				userID, ok := claims["user_id"].(string)
				if !ok {
					log.Printf("[ERROR] user_id not found in token")
					c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
					return
				}
				c.Set("user_id", userID)
				c.Next()
			} else {
				log.Printf("[ERROR] Invalid token claims")
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
				return
			}
		}

		// Route cho endpoint thông báo: /ws/notifications
		r.GET("/notifications", authMiddleware, func(c *gin.Context) {
			userID, _ := c.Get("user_id")
			upgrader := websocket.Upgrader{
				ReadBufferSize:  1024,
				WriteBufferSize: 1024,
				CheckOrigin:     func(r *http.Request) bool { return true }, // Cho phép tất cả origin (có thể hạn chế trong production)
			}

			ws, err := upgrader.Upgrade(c.Writer, c.Request, nil)
			if err != nil {
				log.Printf("[ERROR] Error upgrading to WebSocket for /ws/notifications: %v", err)
				c.AbortWithStatus(http.StatusInternalServerError)
				return
			}

			client := &websocket.Client{
				UserID: userID.(string),
				CageID: "", // Không cần CageID cho thông báo
				Type:   "notification",
				Conn:   ws,
				Send:   make(chan []byte, 256),
			}
			wsHub.Register <- client
			log.Printf("[INFO] WebSocket client registered: userID=%s, type=notification", userID.(string))

			go client.WritePump()
			go client.ReadPump(wsHub)
		})

		// Route cho endpoint dữ liệu cảm biến: /ws/cages/:cageID/sensors-data
		api.GET("/cages/:cageID/sensors-data", authMiddleware, ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
			userID, _ := c.Get("user_id")
			cageID := c.Param("cageID")
			upgrader := websocket.Upgrader{
				ReadBufferSize:  1024,
				WriteBufferSize: 1024,
				CheckOrigin:     func(r *http.Request) bool { return true }, // Cho phép tất cả origin
			}

			ws, err := upgrader.Upgrade(c.Writer, c.Request, nil)
			if err != nil {
				log.Printf("[ERROR] Error upgrading to WebSocket for /ws/cages/%s/sensors-data: %v", cageID, err)
				c.AbortWithStatus(http.StatusInternalServerError)
				return
			}

			client := &websocket.Client{
				UserID: userID.(string),
				CageID: cageID,
				Type:   "sensor",
				Conn:   ws,
				Send:   make(chan []byte, 256),
			}
			wsHub.Register <- client
			log.Printf("[INFO] WebSocket client registered: userID=%s, cageID=%s, type=sensor", userID.(string), cageID)

			go client.WritePump()
			go client.ReadPump(wsHub)
		})
	}
}
func SetupUserRoutes(r *gin.RouterGroup, db *sql.DB, wsHub *websocket.Hub, mqttClient mqtt.Client) {
	userRepo := repository.NewUserRepository(db)
	cageRepo := repository.NewCageRepository(db)
	cageService := service.NewCageService(cageRepo, userRepo)
	deviceRepo := repository.NewDeviceRepository(db)
	deviceService := service.NewDeviceService(deviceRepo, cageRepo)
	sensorRepo := repository.NewSensorRepository(db)
	sensorService := service.NewSensorService(sensorRepo, cageRepo)
	automationRepo := repository.NewAutomationRepository(db)
	automationService := service.NewAutomationService(automationRepo)

	r.Use(middleware.JWTMiddleware())
	{
		r.GET("/:id", func(c *gin.Context) {
			id := c.Param("id")
			user, err := userRepo.GetUserByID(c.Request.Context(), id)
			if err != nil {
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
				return
			}
			c.JSON(http.StatusOK, user)
		})

		r.GET("/cages", func(c *gin.Context) {
			userID, exists := c.Get("user_id")
			if !exists {
				log.Printf("[ERROR] user_id not found in context")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			cages, err := cageService.GetCagesByUserID(c.Request.Context(), userID.(string))
			if err != nil {
				log.Printf("[ERROR] Error fetching cages for user %s: %v", userID, err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			cageRes := []map[string]interface{}{}
			for _, cage := range cages {
				// Lấy danh sách sensors
				sensors, err := sensorService.GetSensorsByCageID(c.Request.Context(), cage.ID)
				if err != nil {
					log.Printf("[ERROR] Error fetching sensors for cage %s: %v", cage.ID, err.Error())
					continue
				}

				// Lấy danh sách devices
				devices, err := deviceService.GetDevicesByCageID(c.Request.Context(), cage.ID)
				if err != nil {
					log.Printf("[ERROR] Error fetching devices for cage %s: %v", cage.ID, err.Error())
					continue
				}

				cageMap := map[string]interface{}{
					"id":         cage.ID,
					"name":       cage.Name,
					"num_sensor": cage.NumSensor,
					"num_device": cage.NumDevice,
					"status":     cage.Status,
					"sensors":    sensors,
					"devices":    devices,
				}
				cageRes = append(cageRes, cageMap)
			}

			c.JSON(http.StatusOK, cageRes)
		})

		r.GET("/cages/general-info", func(c *gin.Context) {
			userID, exists := c.Get("user_id")
			if !exists {
				log.Printf("[ERROR] user_id not found in context")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			count, err := deviceService.CountActiveDevicesByUserID(c.Request.Context(), userID.(string))
			if err != nil {
				log.Printf("[ERROR] Failed to count active devices for user %s: %v", userID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			c.JSON(http.StatusOK, gin.H{"active_devices": count})
		})

		r.GET("/cages/:cageID/sensors", ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
			cageID := c.Param("cageID")

			sensors, err := sensorService.GetSensorsByCageID(c.Request.Context(), cageID)
			if err != nil {
				log.Printf("[ERROR] Error fetching sensors for cage %s: %v", cageID, err.Error())
				c.JSON(http.StatusNotFound, gin.H{"error": "Internal Server Error"})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"sensors": sensors,
			})
		})

		r.GET("/cages/:cageID/sensors-data", ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
			cageID := c.Param("cageID")

			rows, err := db.QueryContext(c.Request.Context(), `
                SELECT id, type, value, unit, created_at
                FROM sensors
                WHERE cage_id = $1
                ORDER BY created_at DESC
                LIMIT 4
            `, cageID)
			if err != nil {
				log.Printf("[ERROR] Error querying sensor data for cage %s: %v", cageID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}
			defer rows.Close()

			sensorData := make(map[string]interface{})
			for rows.Next() {
				var id, sensorType, unit string
				var value float64
				var createdAt time.Time
				if err := rows.Scan(&id, &sensorType, &value, &unit, &createdAt); err != nil {
					log.Printf("[ERROR] Error scanning sensor data: %v", err)
					continue
				}
				sensorData[sensorType] = map[string]interface{}{
					"id":        id,
					"value":     value,
					"unit":      unit,
					"timestamp": createdAt.Unix(),
				}
			}

			c.JSON(http.StatusOK, sensorData)
		})

		r.GET("/cages/:cageID/statistics", ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
			cageID := c.Param("cageID")
			rangeType := c.Query("range")
			startDate := c.Query("start_date")
			endDate := c.Query("end_date")

			var query string
			var args []interface{}
			args = append(args, cageID)

			switch rangeType {
			case "monthly":
				query = `
                    SELECT created_at::date, SUM(water_refill_sl) as water_refill_sl
                    FROM statistic
                    WHERE cage_id = $1 AND created_at::date >= NOW() - INTERVAL '30 days'
                    GROUP BY created_at::date
                    ORDER BY created_at::date DESC
                `
			case "daily", "":
				query = `
                    SELECT created_at::date, water_refill_sl
                    FROM statistic
                    WHERE cage_id = $1 AND created_at::date >= NOW() - INTERVAL '7 days'
                    ORDER BY created_at::date DESC
                `
			default:
				if startDate != "" && endDate != "" {
					query = `
                        SELECT created_at::date, SUM(water_refill_sl) as water_refill_sl
                        FROM statistic
                        WHERE cage_id = $1 AND created_at::date BETWEEN $2 AND $3
                        GROUP BY created_at::date
                        ORDER BY created_at::date DESC
                    `
					args = append(args, startDate, endDate)
				} else {
					query = `
                        SELECT created_at::date, water_refill_sl
                        FROM statistic
                        WHERE cage_id = $1 AND created_at::date >= NOW() - INTERVAL '7 days'
                        ORDER BY created_at::date DESC
                    `
				}
			}

			rows, err := db.QueryContext(c.Request.Context(), query, args...)
			if err != nil {
				log.Printf("[ERROR] Error querying statistics for cage %s: %v", cageID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}
			defer rows.Close()

			statistics := []map[string]interface{}{}
			totalRefills := 0
			countDays := 0
			for rows.Next() {
				var date string
				var waterRefillSl int
				if err := rows.Scan(&date, &waterRefillSl); err != nil {
					log.Printf("[ERROR] Error scanning statistics: %v", err)
					continue
				}
				statistics = append(statistics, map[string]interface{}{
					"date":            date,
					"water_refill_sl": waterRefillSl,
				})
				totalRefills += waterRefillSl
				countDays++
			}

			summary := map[string]interface{}{
				"total_refills": totalRefills,
			}
			if countDays > 0 {
				summary["average_per_day"] = float64(totalRefills) / float64(countDays)
			} else {
				summary["average_per_day"] = 0
			}

			c.JSON(http.StatusOK, gin.H{
				"statistics": statistics,
				"summary":    summary,
			})
		})
		r.DELETE("/automations/:ruleID", func(c *gin.Context) {
			ruleID := c.Param("ruleID")
			userID, exists := c.Get("user_id")
			if !exists {
				log.Printf("[ERROR] user_id not found in context")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			// Verify ownership and existence
			var cageID, ownerID string
			err := db.QueryRowContext(c.Request.Context(), `
				SELECT c.id, c.user_id
				FROM automation_rules ar
				JOIN cages c ON ar.cage_id = c.id
				WHERE ar.id = $1
			`, ruleID).Scan(&cageID, &ownerID)
			if err != nil {
				if err == sql.ErrNoRows {
					c.JSON(http.StatusNotFound, gin.H{"error": "Automation rule not found"})
					return
				}
				log.Printf("[ERROR] Error checking automation rule ownership: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			if ownerID != userID.(string) {
				c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
				return
			}

			// Delete the rule
			_, err = db.ExecContext(c.Request.Context(), `
				DELETE FROM automation_rules WHERE id = $1
			`, ruleID)
			if err != nil {
				log.Printf("[ERROR] Error deleting automation rule %s: %v", ruleID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}
			// Send WebSocket notification
			title := "Automation Rule Deleted"
			message := fmt.Sprintf("Automation rule %s has been deleted", ruleID)
			wsMsg := websocket.Message{
				UserID:  userID.(string),
				Type:    "info",
				Title:   title,
				Message: message,
				CageID:  cageID,
				Time:    time.Now().Unix(),
				Value:   0.0,
			}
			select {
			case wsHub.Broadcast <- wsMsg:
				log.Printf("[INFO] Sent WebSocket notification: %s", message)
			default:
				log.Printf("[WARN] WebSocket broadcast channel full, dropping notification: %s", message)
			}

			// Store notification
			_, err = db.ExecContext(c.Request.Context(), `
				INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
				VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
			`, uuid.New().String(), userID.(string), cageID, "info", title, message, false, time.Now())
			if err != nil {
				log.Printf("[ERROR] Error storing notification: %v", err)
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Automation rule deleted successfully",
			})
		})
		r.GET("/notifications", func(c *gin.Context) {
			userID, exists := c.Get("user_id")
			if !exists {
				log.Printf("[ERROR] user_id not found in context")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			limitStr := c.Query("limit")
			offsetStr := c.Query("offset")
			limit, err := strconv.Atoi(limitStr)
			if err != nil || limit <= 0 {
				limit = 10 // Default limit
			}
			offset, err := strconv.Atoi(offsetStr)
			if err != nil || offset < 0 {
				offset = 0 // Default offset
			}

			rows, err := db.QueryContext(c.Request.Context(), `
				SELECT id, cage_id, type, title, message, is_read, created_at
				FROM notifications
				WHERE user_id = $1
				ORDER BY created_at DESC
				LIMIT $2 OFFSET $3
			`, userID.(string), limit, offset)
			if err != nil {
				log.Printf("[ERROR] Error querying notifications: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}
			defer rows.Close()

			notifications := []map[string]interface{}{}
			for rows.Next() {
				var n struct {
					ID        string
					CageID    string
					Type      string
					Title     string
					Message   string
					IsRead    bool
					CreatedAt time.Time
				}
				if err := rows.Scan(&n.ID, &n.CageID, &n.Type, &n.Title, &n.Message, &n.IsRead, &n.CreatedAt); err != nil {
					log.Printf("[ERROR] Error scanning notification: %v", err)
					continue
				}
				notifications = append(notifications, map[string]interface{}{
					"id":         n.ID,
					"cage_id":    n.CageID,
					"type":       n.Type,
					"title":      n.Title,
					"message":    n.Message,
					"is_read":    n.IsRead,
					"created_at": n.CreatedAt.Format(time.RFC3339),
				})
			}

			c.JSON(http.StatusOK, gin.H{
				"notifications": notifications,
				"count":         len(notifications),
			})
		})
		r.PUT("/cages/:cageID/settings", ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
			cageID := c.Param("cageID")

			var req struct {
				HighWaterUsageThreshold int `json:"high_water_usage_threshold" binding:"required,min=1"`
			}

			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			_, err := db.ExecContext(c.Request.Context(), `
                INSERT INTO settings (cage_id, high_water_usage_threshold)
                VALUES ($1, $2)
                ON CONFLICT (cage_id)
                DO UPDATE SET high_water_usage_threshold = $2, updated_at = $3
            `, cageID, req.HighWaterUsageThreshold, time.Now())
			if err != nil {
				log.Printf("[ERROR] Error updating settings for cage %s: %v", cageID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Settings updated successfully",
			})
		})

		r.GET("/cages/:cageID/sensors-data/ws", ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
			cageID := c.Param("cageID")
			userID, exists := c.Get("user_id")
			if !exists {
				log.Printf("[ERROR] user_id not found in context")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			upgrader := gorillawebsocket.Upgrader{
				ReadBufferSize:  1024,
				WriteBufferSize: 1024,
				CheckOrigin: func(r *http.Request) bool {
					return true
				},
			}
			ws, err := upgrader.Upgrade(c.Writer, c.Request, nil)
			if err != nil {
				log.Printf("[ERROR] Error upgrading to WebSocket: %v", err)
				return
			}

			client := &websocket.Client{
				UserID: userID.(string),
				CageID: cageID,
				Type:   "sensor",
				Conn:   ws,
				Send:   make(chan []byte),
			}
			wsHub.Register <- client

			go client.WritePump()
			go client.ReadPump(wsHub)
		})
		r.POST("/devices/:deviceID/control", ownershipMiddleware(deviceRepo, "deviceID"), func(c *gin.Context) {
			deviceID := c.Param("deviceID")
			userID, exists := c.Get("user_id")
			if !exists {
				log.Printf("[ERROR] user_id not found in context")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			var req struct {
				Action string `json:"action" binding:"required,oneof=turn_on turn_off refill lock auto"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			var currentStatus, deviceName, deviceType string
			var cageID string
			err := db.QueryRowContext(c.Request.Context(), `
				SELECT status, name, type, cage_id FROM devices WHERE id = $1
			`, deviceID).Scan(&currentStatus, &deviceName, &deviceType, &cageID)
			if err != nil {
				log.Printf("[ERROR] Error fetching device %s: %v", deviceID, err)
				c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
				return
			}

			// Validate action based on device type
			validActions := map[string][]string{
				"fan":   {"turn_on", "turn_off", "auto"},
				"light": {"turn_on", "turn_off", "auto"},
				"pump":  {"refill", "auto"},
				"lock":  {"lock", "auto"},
			}
			allowedActions, ok := validActions[deviceType]
			if !ok || !contains(allowedActions, req.Action) {
				c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Action '%s' not allowed for device type '%s'", req.Action, deviceType)})
				return
			}

			// Map action to new status
			actionToStatus := map[string]string{
				"turn_on":  "on",
				"turn_off": "off",
				"refill":   "on",
				"lock":     "locked",
				"auto":     "auto",
			}
			newStatus := actionToStatus[req.Action]

			if currentStatus == newStatus {
				c.JSON(http.StatusOK, gin.H{"message": fmt.Sprintf("Device %s already %s", deviceName, newStatus)})
				return
			}

			tx, err := db.BeginTx(c.Request.Context(), nil)
			if err != nil {
				log.Printf("[ERROR] Error starting transaction: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}
			defer tx.Rollback()

			// Update device status
			_, err = tx.ExecContext(c.Request.Context(), `
				UPDATE devices
				SET status = $1, last_status = status, updated_at = $2
				WHERE id = $3
			`, newStatus, time.Now(), deviceID)
			if err != nil {
				log.Printf("[ERROR] Error updating device %s status: %v", deviceID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			var username, cagename string
			err = tx.QueryRowContext(c.Request.Context(), `
				SELECT u.username, c.name
				FROM users u
				JOIN cages c ON c.user_id = u.id
				WHERE c.id = $1
			`, cageID).Scan(&username, &cagename)
			if err != nil {
				log.Printf("[ERROR] Error fetching username and cagename: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			// Send MQTT message
			// Send MQTT message
			if req.Action != "auto" {
				topic := fmt.Sprintf("hamster/%s/%s/device/%s/%s", username, cagename, deviceID, deviceName)

				// 🌟 Convert action -> value float64
				var valueFloat float64
				switch req.Action {
				case "turn_on", "refill", "lock":
					valueFloat = 1.0
				case "turn_off":
					valueFloat = 0.0
				default:
					valueFloat = 0.0
				}

				payload := map[string]interface{}{
					"username": username,
					"cagename": cagename,
					"type":     "device",
					"id":       deviceID,
					"dataname": deviceName,
					"value":    valueFloat, // ✅ đúng chuẩn float64
					"time":     time.Now().Unix() * 1000,
				}
				payloadBytes, err := json.Marshal(payload)
				if err != nil {
					log.Printf("[ERROR] Error marshaling MQTT payload: %v", err)
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
					return
				}
				if token := mqttClient.Publish(topic, 0, false, payloadBytes); token.Wait() && token.Error() != nil {
					log.Printf("[ERROR] Error publishing to %s: %v", topic, token.Error())
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to publish MQTT message"})
					return
				}
				log.Printf("[INFO] Published to MQTT topic %s: %s", topic, string(payloadBytes))
			}

			// Send WebSocket notification
			title := fmt.Sprintf("Device %s: Action %s", deviceName, req.Action)
			messageText := fmt.Sprintf("Device %s set to %s", deviceName, newStatus)
			wsMsg := websocket.Message{
				UserID:  userID.(string),
				Type:    "notification",
				Title:   title,
				Message: messageText,
				CageID:  cageID,
				Time:    time.Now().Unix(),
				Value:   0.0,
			}
			select {
			case wsHub.Broadcast <- wsMsg:
				log.Printf("[INFO] Sent WebSocket notification: %s", messageText)
			default:
				log.Printf("[WARN] WebSocket broadcast channel full, dropping notification: %s", messageText)
			}

			// Store notification
			_, err = tx.ExecContext(c.Request.Context(), `
				INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
				VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
			`, uuid.New().String(), userID.(string), cageID, "info", title, messageText, false, time.Now())
			if err != nil {
				log.Printf("[ERROR] Error storing notification: %v", err)
			}

			// Handle pump auto-off
			if deviceType == "pump" && req.Action == "refill" {
				go func() {
					time.Sleep(2 * time.Second)
					newTx, err := db.BeginTx(context.Background(), nil)
					if err != nil {
						log.Printf("[ERROR] Error starting transaction for pump turn_off: %v", err)
						return
					}
					defer newTx.Rollback()

					_, err = newTx.ExecContext(context.Background(), `
						UPDATE devices 
						SET status = 'off', last_status = 'on', updated_at = $1 
						WHERE id = $2
					`, time.Now(), deviceID)
					if err != nil {
						log.Printf("[ERROR] Error turning off pump %s: %v", deviceID, err)
						return
					}

					topic := fmt.Sprintf("hamster/%s/%s/device/%s/%s", username, cagename, deviceID, deviceName)
					payload := map[string]interface{}{
						"username": username,
						"cagename": cagename,
						"type":     "device",
						"id":       deviceID,
						"dataname": deviceName,
						"value":    "turn_off",
						"time":     time.Now().Unix() * 1000,
					}
					payloadBytes, _ := json.Marshal(payload)
					if token := mqttClient.Publish(topic, 0, false, payloadBytes); token.Wait() && token.Error() != nil {
						log.Printf("[ERROR] Error publishing pump turn_off: %v", token.Error())
					}

					title := "Device: Pump Stopped"
					message := "Pump turned off after 2-second refill"
					wsMsg := websocket.Message{
						UserID:  userID.(string),
						Type:    "info",
						Title:   title,
						Message: message,
						CageID:  cageID,
						Time:    time.Now().Unix(),
						Value:   0.0,
					}
					select {
					case wsHub.Broadcast <- wsMsg:
						log.Printf("[INFO] Sent WebSocket notification: %s", message)
					default:
						log.Printf("[WARN] WebSocket broadcast channel full, dropping notification: %s", message)
					}

					_, err = newTx.ExecContext(context.Background(), `
						INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
						VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
					`, uuid.New().String(), userID.(string), cageID, "info", title, message, false, time.Now())
					if err != nil {
						log.Printf("[ERROR] Error storing pump stop notification: %v", err)
					}

					if err := newTx.Commit(); err != nil {
						log.Printf("[ERROR] Error committing pump turn_off transaction: %v", err)
					}
				}()
			}

			if err := tx.Commit(); err != nil {
				log.Printf("[ERROR] Error committing transaction: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Device action executed successfully",
			})
		})

		r.GET("/cages/:cageID", ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
			cageID := c.Param("cageID")

			cage, err := cageService.GetACageByCageID(c.Request.Context(), cageID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrInvalidUUID):
					log.Printf("[ERROR] Invalid UUID format for cageID: %s", cageID)
					c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
				case errors.Is(err, service.ErrCageNotFound):
					log.Printf("[ERROR] Cage not found: %s", cageID)
					c.JSON(http.StatusNotFound, gin.H{"error": "Cage not found"})
				default:
					log.Printf("[ERROR] Error fetching cage %s: %v", cageID, err)
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				}
				return
			}

			sensors, err := sensorService.GetSensorsByCageID(c.Request.Context(), cageID)
			if err != nil {
				log.Printf("[ERROR] Error fetching sensors for cage %s: %v", cageID, err.Error())
				c.JSON(http.StatusNotFound, gin.H{"error": "Internal Server Error"})
				return
			}

			devices, err := deviceService.GetDevicesByCageID(c.Request.Context(), cageID)
			if err != nil {
				log.Printf("[ERROR] Error fetching devices for cage %s: %v", cageID, err.Error())
				c.JSON(http.StatusNotFound, gin.H{"error": "Internal Server Error"})
				return
			}

			devicesWithActionType := []map[string]interface{}{}
			for _, device := range devices {
				deviceMap := map[string]interface{}{
					"id":     device.ID,
					"name":   device.Name,
					"status": device.Status,
				}
				if device.Type == "pump" {
					deviceMap["action_type"] = "refill"
				} else {
					deviceMap["action_type"] = "on_off"
				}
				devicesWithActionType = append(devicesWithActionType, deviceMap)
			}

			c.JSON(http.StatusOK, gin.H{
				"id":      cage.ID,
				"name":    cage.Name,
				"status":  cage.Status,
				"sensors": sensors,
				"devices": devicesWithActionType,
			})
		})
		r.GET("/sensors/:sensorID", ownershipMiddleware(sensorRepo, "sensorID"), func(c *gin.Context) {
			sensorID := c.Param("sensorID")

			sensor, err := sensorService.GetSensorByID(c.Request.Context(), sensorID)
			if err != nil {
				log.Printf("[ERROR] Error fetching sensor %s: %v", sensorID, err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"id":      sensor.ID,
				"name":    sensor.Name,
				"type":    sensor.Type,
				"value":   sensor.Value,
				"unit":    sensor.Unit,
				"cage_id": sensor.CageID,
			})
		})

		r.GET("/devices/:deviceID", ownershipMiddleware(deviceRepo, "deviceID"), func(c *gin.Context) {
			deviceID := c.Param("deviceID")

			device, err := deviceService.GetDeviceByID(c.Request.Context(), deviceID)
			if err != nil {
				log.Printf("[ERROR] Error fetching device %s: %v", deviceID, err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			automationRules, err := automationService.GetRulesByDeviceID(c.Request.Context(), deviceID)
			if err != nil {
				log.Printf("[ERROR] Error fetching automation rules for device %s: %v", deviceID, err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			var actionType string = "on_off"
			if device.Type == "pump" {
				actionType = "refill"
			}

			automationRulesRes := []map[string]interface{}{}
			for _, rule := range automationRules {
				automationRulesRes = append(automationRulesRes, map[string]interface{}{
					"id":          rule.ID,
					"sensor_id":   rule.SensorID,
					"sensor_type": rule.SensorType,
					"condition":   rule.Condition,
					"threshold":   rule.Threshold,
					"unit":        rule.Unit,
					"action":      rule.Action,
				})
			}

			c.JSON(http.StatusOK, gin.H{
				"id":              device.ID,
				"name":            device.Name,
				"status":          device.Status,
				"type":            actionType,
				"automation_rule": automationRulesRes,
			})
		})

		r.POST("/devices/:deviceID/automations", ownershipMiddleware(deviceRepo, "deviceID"), func(c *gin.Context) {
			deviceID := c.Param("deviceID")
			userID, exists := c.Get("user_id")
			if !exists {
				log.Printf("[ERROR] user_id not found in context")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			var req struct {
				SensorID  string  `json:"sensor_id" binding:"required,uuid"`
				Condition string  `json:"condition" binding:"required,oneof=> < ="`
				Threshold float64 `json:"threshold" binding:"required"`
				Action    string  `json:"action" binding:"required,oneof=turn_on turn_off refill"`
			}

			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid request body: %v", err)})
				return
			}

			var cageID string
			err := db.QueryRowContext(c.Request.Context(), `
                SELECT cage_id FROM devices WHERE id = $1
            `, deviceID).Scan(&cageID)
			if err != nil {
				log.Printf("[ERROR] Error fetching device %s: %v", deviceID, err)
				c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
				return
			}

			var sensorUnit string
			err = db.QueryRowContext(c.Request.Context(), `
                SELECT unit FROM sensors WHERE id = $1 AND cage_id = $2
            `, req.SensorID, cageID).Scan(&sensorUnit)
			if err != nil {
				log.Printf("[ERROR] Error fetching sensor %s: %v", req.SensorID, err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Sensor not found or not in same cage"})
				return
			}

			var owned bool
			err = db.QueryRowContext(c.Request.Context(), `
                SELECT EXISTS (
                    SELECT 1 FROM cages WHERE id = $1 AND user_id = $2
                )
            `, cageID, userID).Scan(&owned)
			if err != nil || !owned {
				log.Printf("[ERROR] Unauthorized access to cage %s by user %s: %v", cageID, userID, err)
				c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
				return
			}

			rule := &model.AutomationRule{
				SensorID:  req.SensorID,
				DeviceID:  deviceID,
				CageID:    cageID,
				Condition: req.Condition,
				Threshold: req.Threshold,
				Unit:      sensorUnit,
				Action:    req.Action,
			}
			createdRule, err := automationService.AddAutomationRule(c.Request.Context(), rule, cageService)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrDifferentCage):
					log.Printf("[ERROR] Sensor %s and device %s are not in the same cage", req.SensorID, deviceID)
					c.JSON(http.StatusBadRequest, gin.H{"error": "Sensor and device are not in the same cage"})
				default:
					log.Printf("[ERROR] Failed to create automation rule: %v", err)
					c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("Failed to create automation rule: %v", err)})
				}
				return
			}

			c.JSON(http.StatusCreated, gin.H{
				"message": "Automation rule created successfully",
				"automation_rule": map[string]interface{}{
					"id":          createdRule.ID,
					"sensor_id":   createdRule.SensorID,
					"sensor_type": createdRule.SensorType, // Add sensor type from sensors table
					"condition":   createdRule.Condition,
					"threshold":   createdRule.Threshold,
					"unit":        createdRule.Unit,
					"action":      createdRule.Action,
				},
			})
		})

		r.GET("/cages/:cageID/notifications/ws", ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
			cageID := c.Param("cageID")
			userID, exists := c.Get("user_id")
			if !exists {
				log.Printf("[ERROR] user_id not found in context")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			upgrader := gorillawebsocket.Upgrader{
				ReadBufferSize:  1024,
				WriteBufferSize: 1024,
				CheckOrigin:     func(r *http.Request) bool { return true },
			}
			ws, err := upgrader.Upgrade(c.Writer, c.Request, nil)
			if err != nil {
				log.Printf("[ERROR] Error upgrading to WebSocket: %v", err)
				return
			}

			client := &websocket.Client{
				UserID: userID.(string),
				CageID: cageID,
				Type:   "notification", // Đảm bảo Type là notification
				Conn:   ws,
				Send:   make(chan []byte, 256), // 🔄 Thêm dung lượng cho kênh Send
			}
			wsHub.Register <- client
			log.Printf("[INFO] WebSocket client registered: userID=%s, cageID=%s", userID.(string), cageID)

			go client.WritePump()
			go client.ReadPump(wsHub)
		})

		r.PATCH("/notifications/:notiID/read", func(c *gin.Context) {
			userID, exists := c.Get("user_id")
			if !exists {
				log.Printf("[ERROR] user_id not found in context")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			notiID := c.Param("notiID")

			var ownerID string
			err := db.QueryRowContext(c.Request.Context(), `
                SELECT user_id FROM notifications WHERE id = $1
            `, notiID).Scan(&ownerID)
			if err != nil {
				if err == sql.ErrNoRows {
					c.JSON(http.StatusNotFound, gin.H{"error": "Notification not found"})
					return
				}
				log.Printf("[ERROR] Error checking notification ownership: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			if ownerID != userID.(string) {
				c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
				return
			}

			_, err = db.ExecContext(c.Request.Context(), `
                UPDATE notifications
                SET is_read = TRUE
                WHERE id = $1
            `, notiID)
			if err != nil {
				log.Printf("[ERROR] Error marking notification as read: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Notification marked as read",
			})
		})
	}
}

type ownershipChecker interface {
	IsOwnedByUser(ctx context.Context, userID, entityID string) (bool, error)
	IsExistsID(ctx context.Context, entityID string) (bool, error)
}

// Helper function to check if a slice contains a string
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

// In user_route.go or wherever ownershipMiddleware is defined
func ownershipMiddleware(checker ownershipChecker, resourceIDParam string) gin.HandlerFunc {
	return func(c *gin.Context) {
		resourceID := c.Param(resourceIDParam)

		// Check if the resource exists
		exists, err := checker.IsExistsID(c.Request.Context(), resourceID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
			c.Abort()
			return
		}
		if !exists {
			c.JSON(http.StatusNotFound, gin.H{"error": "Resource not found"})
			c.Abort()
			return
		}

		// Get the user ID from the context (set by authentication middleware)
		userID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			c.Abort()
			return
		}

		// Check if the user owns the resource
		owned, err := checker.IsOwnedByUser(c.Request.Context(), resourceID, userID.(string))
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
			c.Abort()
			return
		}
		if !owned {
			c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
			c.Abort()
			return
		}

		c.Next()
	}
}
