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
	"time"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	gorillawebsocket "github.com/gorilla/websocket"
)

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
	scheduleRepo := repository.NewScheduleRepository(db)
	scheduleService := service.NewScheduleService(scheduleRepo)

	go monitorSensors(db, wsHub)

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
				cageMap := map[string]interface{}{
					"id":         cage.ID,
					"name":       cage.Name,
					"num_device": cage.NumDevice,
					"status":     cage.Status,
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
				Conn:   ws,
				Send:   make(chan []byte),
			}
			wsHub.Register <- client

			client.WritePump()
			go client.ReadPump(wsHub)
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
				Conn:   ws,
				Send:   make(chan []byte),
				Type:   "notification",
			}
			wsHub.Register <- client

			go client.WritePump()
			go client.ReadPump(wsHub)
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

			scheduleRules, err := scheduleService.GetRulesByDeviceID(c.Request.Context(), deviceID)
			if err != nil {
				log.Printf("[ERROR] Error fetching schedule rules for device %s: %v", deviceID, err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			var actionType string = "on_off"
			if device.Type == "pump" {
				actionType = "refill"
			}

			c.JSON(http.StatusOK, gin.H{
				"id":              device.ID,
				"name":            device.Name,
				"status":          device.Status,
				"action_type":     actionType,
				"automation_rule": automationRules,
				"schedule_rule":   scheduleRules,
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
				Action    string  `json:"action" binding:"required,oneof=turn_on turn_off refill lock"`
			}

			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("Invalid request body: %v", err)})
				return
			}

			// Verify device exists and get cage_id
			var cageID string
			err := db.QueryRowContext(c, `
                SELECT cage_id FROM devices WHERE id = $1
            `, deviceID).Scan(&cageID)
			if err != nil {
				log.Printf("[ERROR] Error fetching device %s: %v", deviceID, err)
				c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
				return
			}

			// Verify sensor exists and belongs to same cage
			var sensorUnit string
			err = db.QueryRowContext(c, `
                SELECT unit FROM sensors WHERE id = $1 AND cage_id = $2
            `, req.SensorID, cageID).Scan(&sensorUnit)
			if err != nil {
				log.Printf("[ERROR] Error fetching sensor %s: %v", req.SensorID, err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Sensor not found or not in same cage"})
				return
			}

			// Verify user owns cage
			var owned bool
			err = db.QueryRowContext(c, `
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
				Unit:      sensorUnit, // Include unit if added to schema
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
				"id":      createdRule.ID,
			})
		})

		r.DELETE("/schedules/:ruleID", ownershipMiddleware(scheduleRepo, "ruleID"), func(c *gin.Context) {
			ruleID := c.Param("ruleID")

			err := scheduleService.RemoveScheduleRule(c.Request.Context(), ruleID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrInvalidUUID):
					log.Printf("[ERROR] Invalid UUID format for ruleID: %s", ruleID)
					c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
				case errors.Is(err, service.ErrRuleNotFound):
					log.Printf("[ERROR] Schedule rule not found: %s", ruleID)
					c.JSON(http.StatusNotFound, gin.H{"error": "Schedule rule not found"})
				default:
					log.Printf("[ERROR] Failed to delete schedule rule %s: %v", ruleID, err)
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				}
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Schedule rule deleted successfully",
			})
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
				Action string `json:"action" binding:"required,oneof=turn_on turn_off"`
			}

			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err.Error())
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			var currentStatus string
			err := db.QueryRowContext(c.Request.Context(), `
                SELECT status FROM devices WHERE id = $1
            `, deviceID).Scan(&currentStatus)
			if err != nil {
				log.Printf("[ERROR] Error fetching device status: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			device, err := deviceService.GetDeviceByID(c.Request.Context(), deviceID)
			if err != nil {
				log.Printf("[ERROR] Error fetching device %s: %v", deviceID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			var newStatus string
			switch req.Action {
			case "turn_on":
				newStatus = "on"
			case "turn_off":
				newStatus = "off"
			}

			_, err = db.ExecContext(c.Request.Context(), `
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
			err = db.QueryRowContext(c.Request.Context(), `
                SELECT u.username, c.name
                FROM users u
                JOIN cages c ON c.user_id = u.id
                WHERE c.id = $1
            `, device.CageID).Scan(&username, &cagename)
			if err != nil {
				log.Printf("[ERROR] Error fetching username and cagename: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			topic := fmt.Sprintf("hamster/%s/%s/device/%s", username, cagename, deviceID)
			payload := map[string]interface{}{
				"username": username,
				"cagename": cagename,
				"type":     "device",
				"id":       deviceID,
				"dataname": device.Name,
				"value":    req.Action,
				"time":     time.Now().Unix(),
			}
			payloadBytes, err := json.Marshal(payload)
			if err != nil {
				log.Printf("[ERROR] Error marshaling MQTT payload: %v", err)
			} else {
				log.Printf("[INFO] Publishing to MQTT topic %s: %s", topic, string(payloadBytes))
				mqttClient.Publish(topic, 0, false, payloadBytes)
			}

			title := fmt.Sprintf("Device %s: Action %s executed", device.Name, req.Action)
			messageText := fmt.Sprintf("Device %s %s", device.Name, req.Action)
			wsHub.Broadcast <- websocket.Message{
				UserID:  userID.(string),
				Type:    "info",
				Title:   title,
				Message: messageText,
				CageID:  device.CageID,
				Time:    time.Now().Unix(),
				Value:   0.0,
			}

			_, err = db.ExecContext(c.Request.Context(), `
                INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            `, uuid.New().String(), userID.(string), device.CageID, "info", title, messageText, false, time.Now())
			if err != nil {
				log.Printf("[ERROR] Error storing device action notification: %v", err)
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Device action executed successfully",
			})
		})

		r.GET("/notifications", func(c *gin.Context) {
			userID, exists := c.Get("user_id")
			if !exists {
				log.Printf("[ERROR] user_id not found in context")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}

			rows, err := db.QueryContext(c.Request.Context(), `
                SELECT id, user_id, cage_id, type, title, message, is_read, created_at
                FROM notifications
                WHERE user_id = $1
                ORDER BY created_at DESC
            `, userID.(string))
			if err != nil {
				log.Printf("[ERROR] Error querying notifications for user %s: %v", userID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch notifications"})
				return
			}
			defer rows.Close()

			notifications := []map[string]interface{}{}
			for rows.Next() {
				var n model.Notification
				if err := rows.Scan(&n.ID, &n.UserID, &n.CageID, &n.Type, &n.Title, &n.Message, &n.IsRead, &n.CreatedAt); err != nil {
					log.Printf("[ERROR] Error scanning notification: %v", err)
					continue
				}
				notifications = append(notifications, map[string]interface{}{
					"id":        n.ID,
					"title":     n.Title,
					"timestamp": n.CreatedAt.Unix(),
					"type":      n.Type,
					"read":      n.IsRead,
				})
			}
			if err := rows.Err(); err != nil {
				log.Printf("[ERROR] Error iterating notifications: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to process notifications"})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"notifications": notifications,
			})
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

func monitorSensors(db *sql.DB, wsHub *websocket.Hub) {
	ticker := time.NewTicker(10 * time.Second)
	defer ticker.Stop()

	lastNotified := make(map[string]time.Time)

	for range ticker.C {
		rows, err := db.QueryContext(context.Background(), `
            SELECT ar.id, ar.sensor_id, ar.device_id, ar.condition, ar.threshold, ar.action,
                   s.cage_id, s.type AS sensor_type, d.name AS device_name, c.user_id
            FROM automation_rules ar
            JOIN sensors s ON ar.sensor_id = s.id
            JOIN devices d ON ar.device_id = d.id
            JOIN cages c ON s.cage_id = c.id
        `)
		if err != nil {
			log.Printf("[ERROR] Error querying automation rules: %v", err)
			continue
		}

		type ruleInfo struct {
			RuleID     string
			SensorID   string
			DeviceID   string
			Condition  string
			Threshold  float64
			Action     string
			CageID     string
			SensorType string
			DeviceName string
			UserID     string
		}

		var rules []ruleInfo
		for rows.Next() {
			var r ruleInfo
			if err := rows.Scan(&r.RuleID, &r.SensorID, &r.DeviceID, &r.Condition, &r.Threshold, &r.Action,
				&r.CageID, &r.SensorType, &r.DeviceName, &r.UserID); err != nil {
				log.Printf("[ERROR] Error scanning automation rule: %v", err)
				continue
			}
			rules = append(rules, r)
		}
		rows.Close()

		for _, rule := range rules {
			var value float64
			var createdAt time.Time
			err := db.QueryRowContext(context.Background(), `
                SELECT value, created_at
                FROM sensors
                WHERE id = $1
                ORDER BY created_at DESC
                LIMIT 1
            `, rule.SensorID).Scan(&value, &createdAt)
			if err != nil {
				if err == sql.ErrNoRows {
					log.Printf("[INFO] No data for sensor %s", rule.SensorID)
				} else {
					log.Printf("[ERROR] Error querying sensor %s: %v", rule.SensorID, err)
				}
				continue
			}

			triggered := false
			switch rule.Condition {
			case ">":
				if value > rule.Threshold {
					triggered = true
				}
			case "<":
				if value < rule.Threshold {
					triggered = true
				}
			case "=":
				if value == rule.Threshold {
					triggered = true
				}
			}

			if triggered {
				notificationKey := fmt.Sprintf("%s-%s", rule.SensorID, rule.RuleID)
				lastNotificationTime, exists := lastNotified[notificationKey]
				if exists && time.Since(lastNotificationTime) < 5*time.Minute {
					continue
				}

				actionVerb := ""
				switch rule.Action {
				case "turn_on":
					actionVerb = "bật"
				case "turn_off":
					actionVerb = "tắt"
				}
				title := fmt.Sprintf("Cage %s: Sensor alert triggered", rule.CageID)
				message := fmt.Sprintf("%s %.1f%s vượt ngưỡng %.1f%s: Hãy %s %s",
					rule.SensorType, value, rule.Threshold, actionVerb, rule.DeviceName)

				wsHub.Broadcast <- websocket.Message{
					UserID:  rule.UserID,
					Type:    "warning",
					Title:   title,
					Message: message,
					CageID:  rule.CageID,
					Time:    time.Now().Unix(),
					Value:   value,
				}

				_, err = db.ExecContext(context.Background(), `
                    INSERT INTO notifications (id, user_id, cage_id, type, title, message, is_read, created_at)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                `, uuid.New().String(), rule.UserID, rule.CageID, "warning", title, message, false, time.Now())
				if err != nil {
					log.Printf("[ERROR] Error storing notification: %v", err)
				}

				lastNotified[notificationKey] = time.Now()
				log.Printf("[INFO] Sent sensor alert for cage %s: %s", rule.CageID, message)
			}
		}
	}
}

type ownershipChecker interface {
	IsOwnedByUser(ctx context.Context, userID, entityID string) (bool, error)
	IsExistsID(ctx context.Context, entityID string) (bool, error)
}

func ownershipMiddleware(repo ownershipChecker, paramName string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID, exists := c.Get("user_id")
		if !exists {
			log.Println("[ERROR] Missing userID in context")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			c.Abort()
			return
		}

		entityID := c.Param(paramName)
		if err := service.IsValidUUID(entityID); err != nil {
			log.Printf("[ERROR] Invalid UUID format for %s: %s", paramName, entityID)
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
			c.Abort()
			return
		}

		entityExists, err := repo.IsExistsID(c.Request.Context(), entityID)
		if err != nil {
			log.Printf("[ERROR] Error checking existence of %s: %v", paramName, err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
			c.Abort()
			return
		}
		if !entityExists {
			log.Printf("[ERROR] %s not found: %s", paramName, entityID)
			c.JSON(http.StatusNotFound, gin.H{"error": fmt.Sprintf("%s not found", paramName)})
			c.Abort()
			return
		}

		owned, err := repo.IsOwnedByUser(c.Request.Context(), userID.(string), entityID)
		if err != nil {
			log.Printf("[ERROR] Error checking ownership of %s %s: %v", paramName, entityID, err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
			c.Abort()
			return
		}

		if !owned {
			log.Printf("[ERROR] Unauthorized access: User %s does not own %s %s", userID.(string), paramName, entityID)
			c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
			c.Abort()
			return
		}

		c.Next()
	}
}
