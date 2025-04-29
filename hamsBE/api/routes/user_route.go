// api/routes/user.go
package routes

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"hamstercare/internal/middleware"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
	"hamstercare/internal/service"
	ws "hamstercare/internal/websocket"
	"strconv"
	"strings"
	"time"

	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func SetupUserRoutes(r *gin.RouterGroup, db *sql.DB) {
	userRepo := repository.NewUserRepository(db)

	cageRepo := repository.NewCageRepository(db)
	cageService := service.NewCageService(cageRepo, userRepo)

	automationRepo := repository.NewAutomationRepository(db)
	automationService := service.NewAutomationService(automationRepo)

	scheduleRepo := repository.NewScheduleRepository(db)
	scheduleService := service.NewScheduleService(scheduleRepo)

	deviceRepo := repository.NewDeviceRepository(db)
	deviceService := service.NewDeviceService(deviceRepo, cageRepo, automationRepo)

	sensorRepo := repository.NewSensorRepository(db)
	sensorService := service.NewSensorService(sensorRepo, cageRepo, automationRepo)

	// WebSocket để nhận dữ liệu cảm biến của cage
	r.GET("/user/cages/:cageID/sensors-data", func(c *gin.Context) {
		cageID := c.Param("cageID")
		token := c.Query("token")

		if token == "" {
			log.Printf("[ERROR] Missing token")
			c.JSON(http.StatusBadRequest, gin.H{"error": "Authorization token is required"})
			return
		}

		claims, err := middleware.VerifyToken(token)
		if err != nil {
			log.Printf("[ERROR] Invalid token: %v", err)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			return
		}

		entityExists, err := cageRepo.IsExistsID(c.Request.Context(), cageID)
		if err != nil {
			log.Printf("[ERROR] Error fetching cage %s: %v", cageID, err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
			return
		}
		if !entityExists {
			c.JSON(http.StatusNotFound, gin.H{"error": "Cage not found"})
			return
		}

		owned, err := cageRepo.IsOwnedByUser(c.Request.Context(), claims.UserID, cageID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
			return
		}
		if !owned {
			c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
			return
		}

		if err := ws.StreamSensorData(sensorRepo, cageID, c.Writer, c.Request); err != nil {
			log.Printf("[ERROR] %v", err)
		}
	})

	// WebSocket để nhận thông báo realtime
	r.GET("/ws/notifications", func(c *gin.Context) {
		token := c.Query("token")

		if token == "" {
			log.Printf("[ERROR] Missing token")
			c.JSON(http.StatusBadRequest, gin.H{"error": "Authorization token is required"})
			return
		}

		claims, err := middleware.VerifyToken(token)
		if err != nil {
			log.Printf("[ERROR] Invalid token: %v", err)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			return
		}

		userID := claims.UserID
		if userID == "" {
			log.Printf("[ERROR] Invalid claims: missing userID")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token claims"})
			return
		}

		if err := ws.StreamNotifications(userID, c.Writer, c.Request); err != nil {
			log.Printf("[ERROR] %v", err)
		}
	})



	//user := r.Group("/user")
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

		// Lấy danh sách chuồng (cages) của user
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
					"id":     cage.ID,
					"name":   cage.Name,
					"num_device": cage.NumDevice,
					"status": cage.Status,
				}
				cageRes = append(cageRes, cageMap)
			}
		
			c.JSON(http.StatusOK, cageRes)
		})

		// Get General Info (number of active devices in all cages)
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

		// Lấy danh sách sensor trong 1 cage
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

		// Xem chi tiết một chuồng (a cage) của user
		r.GET("/cages/:cageID",ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
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
					"status": device.Mode,
				}
		
				if device.Type == "pump" {
					deviceMap["action_type"] = "refill"
				} else {
					deviceMap["action_type"] = "on_off"
				}
		
				devicesWithActionType = append(devicesWithActionType, deviceMap)
			}

			c.JSON(http.StatusOK, gin.H{
				"id": cage.ID,
				"name": cage.Name,
				"status": cage.Status,
				"sensors": sensors,
				"devices": devicesWithActionType,
			})
		})

		// Xem chi tiết một thiết bị (device) của user
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

			var action_type string = "on_off";
			if device.Type == "pump" {
				action_type = "refill"
			}

			c.JSON(http.StatusOK, gin.H{
				"id": device.ID,
				"name": device.Name,
				"status": device.Mode,
				"action_type": action_type,
				"automation_rule": automationRules,
				"schedule_rule": scheduleRules,
			})
		})

		// Thêm automation rule cho thiết bị
		r.POST("/devices/:deviceID/automations", ownershipMiddleware(deviceRepo, "deviceID"), func(c *gin.Context) {
			deviceID := c.Param("deviceID")
			
			var req struct {
				SensorID 	string `json:"sensor_id" binding:"required"`
				Condition 	string `json:"condition" binding:"required"`
				Threshold 	float64 `json:"threshold" binding:"required"`
				Action 		string `json:"action" binding:"required"`
			}

			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err.Error())
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			validConditions := map[string]bool{"<": true, ">": true, "=": true}
			if !validConditions[req.Condition] {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid condition"})
				return
			}

			validActions := map[string]bool{"turn_on": true, "turn_off": true, "refill": true}
			if !validActions[req.Action] {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid action"})
				return
			}

			if req.Action == "refill" {
				if err := deviceService.ValidateDeviceAction(c.Request.Context(), deviceID, req.Action); err != nil {
					log.Printf("[ERROR] %v", err)
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}
			}

			rule := &model.AutomationRule{
				SensorID:  req.SensorID,
				DeviceID:  deviceID,
				Condition: req.Condition,
				Threshold: req.Threshold,
				Action:    req.Action,
			}
			createRule, err := automationService.AddAutomationRule(c.Request.Context(), rule, cageService) 
			if err != nil {
				switch {
					case errors.Is(err, service.ErrDifferentCage): 
						log.Printf("[ERROR]  Sensor [%s] and device [%s] are not in the same cage.", req.SensorID, deviceID)
						c.JSON(http.StatusBadRequest, gin.H{"error": " Sensor and device are not in the same cage."})
					default:
						log.Printf("[ERROR] Failed to create automation rule: %v", err.Error())
						c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
					}
					return
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Automation rule created successfully",
				"id": createRule.ID,
			})
		})

		// Xóa automation rule
		r.DELETE("/automations/:ruleID", ownershipMiddleware(automationRepo, "ruleID"), func(c *gin.Context) {
			ruleID := c.Param("ruleID")
			
			err := automationService.RemoveAutomationRule(c.Request.Context(), ruleID)
			if err != nil {
				switch {
					case errors.Is(err, service.ErrInvalidUUID): 
						log.Printf("[ERROR] Invalid UUID format for ruleID: %s", ruleID)
						c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
					case errors.Is(err, service.ErrRuleNotFound):
						log.Printf("[ERROR] Automation rule not found: %s", ruleID)
						c.JSON(http.StatusNotFound, gin.H{"error": "Automation rule not found"})
					default:
						log.Printf("[ERROR] Failed to delete automation rule %s: %v", ruleID, err)
						c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
					}
					return
			}
			
			c.JSON(http.StatusOK, gin.H{
				"message": "Automation rule deleted successfully",
			})
		})

		// Thêm API tạo schedule
		r.POST("/devices/:deviceID/schedules", ownershipMiddleware(deviceRepo, "deviceID"), func(c *gin.Context) {
			deviceID := c.Param("deviceID")
			
			var req struct {
				ExecutionTime 	string `json:"execution_time" binding:"required"`
				Days 			[]string `json:"days" binding:"required"`
				Action 			string `json:"action" binding:"required,oneof=turn_on turn_off refill"`
			}

			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err.Error())
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			// Kiểm tra ExecutionTime có đúng định dạng HH:MM không
			parsedTime, parseErr := time.Parse("15:04", req.ExecutionTime)
			if parseErr != nil {
				log.Printf("[ERROR] Invalid execution_time format: %v", parseErr.Error())
				c.JSON(http.StatusBadRequest, gin.H{"error": "execution_time must be in format HH:MM"})
				return
			}
			
			// Kiểm tra Days có giá trị hợp lệ không
			validDays := map[string]bool{
				"mon": true, "tue": true, "wed": true, "thu": true, "fri": true, "sat": true, "sun": true,
			}
			for _, day := range req.Days {
				if !validDays[day] {
					log.Printf("[ERROR] Invalid day in schedule: %s", day)
					c.JSON(http.StatusBadRequest, gin.H{"error": "days must only contain values: mon, tue, wed, thu, fri, sat, sun"})
					return
				}
			}

			if req.Action == "refill" {
				if err := deviceService.ValidateDeviceAction(c.Request.Context(), deviceID, req.Action); err != nil {
					log.Printf("[ERROR] %v", err)
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
					return
				}
			}

			rule := &model.ScheduleRule{
				ExecutionTime:  parsedTime.Format("15:04"), 
				Days:  			req.Days,
				DeviceID: 		deviceID,
				Action: 		req.Action,
			}

			createSchedule, err := scheduleService.AddScheduleRule(c.Request.Context(), rule) 
			if err != nil {
				log.Printf("[ERROR] Failed to create schedule rule: %v", err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			} 

			c.JSON(http.StatusOK, gin.H{
				"message": "Schedule rule created successfully",
				"id": createSchedule.ID,
			})
		})

		// Thêm API xóa schedule
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

		// Set device status
		r.PUT("/devices/:deviceID/status", ownershipMiddleware(deviceRepo, "deviceID"), func(c *gin.Context) {
			deviceID := c.Param("deviceID")
		
			var req struct {
				Status string `json:"status"` // on/off/auto
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}
			if strings.TrimSpace(req.Status) == "" {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Status is required"})
				return
			}
		
			device, err := deviceService.GetDeviceByID(c.Request.Context(), deviceID)
			if err != nil {
				log.Printf("[ERROR] Fetching device %s: %v", deviceID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch device"})
				return
			}
		
			if err := handleDeviceAction(req.Status, device); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				return
			}
		
			if err := deviceService.UpdateDeviceMode(c.Request.Context(), deviceID, req.Status); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update device status"})
				return
			}
		
			c.JSON(http.StatusOK, gin.H{"message": "Device status updated successfully"})
		})
		
		// Update device name
		r.PUT("/devices/:deviceID/name", ownershipMiddleware(deviceRepo, "deviceID"), func(c *gin.Context) {
			deviceID := c.Param("deviceID")
		
			var req struct {
				Name string `json:"name"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}
			if strings.TrimSpace(req.Name) == "" {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Name is required"})
				return
			}
		
			// Check duplicate name
			exists, err := deviceService.IsDeviceNameExists(c.Request.Context(), req.Name)
			if err != nil {
				log.Printf("[ERROR] Failed to check device name uniqueness: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}
			if exists {
				log.Printf("[ERROR] Device name already exists: %s", req.Name)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Device name already exists"})
				return
			}
		
			if err := deviceService.UpdateDeviceName(c.Request.Context(), deviceID, req.Name); err != nil {
				log.Printf("[ERROR] Failed to update device name: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update device name"})
				return
			}
		
			c.JSON(http.StatusOK, gin.H{"message": "Device name updated successfully"})
		})
		
		// Set cages status
		r.PUT("/cages/:cageID/status", ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
			cageID := c.Param("cageID")
		
			var req struct {
				Status string `json:"status"` // active/inactive
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}
		
			switch req.Status {
			case "inactive":
				// Tắt hết device trong cage
				if err := deviceService.TurnOffDevicesInCage(c.Request.Context(), cageID); err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to turn off devices"})
					return
				}
			case "active":
				// Khôi phục trạng thái last mode của device
				if err := deviceService.RestoreDevicesInCage(c.Request.Context(), cageID); err != nil {
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to restore devices"})
					return
				}
			default:
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid status value"})
				return
			}
		
			// Update lại trạng thái cage
			if err := cageService.UpdateCageStatus(c.Request.Context(), cageID, req.Status); err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update cage status"})
				return
			}

			c.JSON(http.StatusOK, gin.H{"message": "Cage status updated successfully"})
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

			// Gửi thông báo
			// userIDRaw, exists := c.Get("user_id")
			// if !exists {
			// 	log.Printf("[ERROR] user_id not found in context")
			// 	c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
			// 	return
			// }

			// userID, ok := userIDRaw.(string)
			// if !ok {
			// 	log.Printf("[ERROR] user_id is not a string")
			// 	c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
			// 	return
			// }

			// Lấy tên cage
			// cageName, err := cageRepo.GetCageNameByID(c.Request.Context(), cageID)
			// if err != nil {
			// 	log.Printf("[ERROR] Failed to fetch cage name: %v", err)
			// 	c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch cage name"})
			// 	return
			// }
			// if cageName == "" {
			// 	cageName = "Cage" // fallback nếu không có tên
			// }

			// Tạo nội dung notification dựa theo status
			// var title, message, notifType string
			// switch req.Status {
			// case "active":
			// 	title = fmt.Sprintf("%s: Cage activated", cageName)
			// 	message = "The cage was successfully activated."
			// 	notifType = "info"
			// case "inactive":
			// 	title = fmt.Sprintf("%s: Cage deactivated", cageName)
			// 	message = "The cage was deactivated and all devices were turned off."
			// 	notifType = "warning"
			// default:
			// 	c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid status value"})
			// 	return
			// }

			// Gửi notification
			// if err := notiService.SendNotificationToUser(c.Request.Context(), userID, cageID, title, notifType, message); err != nil {
			// 	log.Printf("[ERROR] Failed to send notification: %v", err)
			// }


func handleDeviceAction(reqStatus string, device *model.DeviceResponse) error {
    userID := "user1"
    cageID := "cage1"

    var action int
    switch reqStatus {
    case "on":
        action = 1
    case "off", "auto":
        action = 0
    default:
        return fmt.Errorf("invalid status value")
    }

    // Xử lý hành động thiết bị
    if err := service.HandleDeviceAction(userID, cageID, device.ID, device.Type, action); err != nil {
        return fmt.Errorf("failed to handle device action: %w", err)
    }

    // Nếu là thiết bị "pump", tự động tắt sau 5 giây nếu trạng thái là "on"
    if device.Type == "pump" && reqStatus == "on" {
        go func(userID, cageID, deviceID, deviceType string) {
            time.Sleep(5 * time.Second)
            if err := service.HandleDeviceAction(userID, cageID, deviceID, deviceType, 0); err != nil {
                log.Printf("[ERROR] Failed to auto-turn off pump %s: %v", deviceID, err)
            } else {
                log.Printf("[DEBUG] Pump %s auto-turned off after 5 seconds", deviceID)
            }
        }(userID, cageID, device.ID, device.Type)
    }

    return nil
}

// OwnershipChecker định nghĩa interface kiểm tra quyền sở hữu
type ownershipChecker interface {
    IsOwnedByUser(ctx context.Context, userID, entityID string) (bool, error)
	IsExistsID(ctx context.Context, entityID string) (bool, error) 
}

// ownershipMiddleware kiểm tra quyền sở hữu của user đối với thực thể (cage, device, automation_rule)
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
