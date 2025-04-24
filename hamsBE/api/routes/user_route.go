package routes

import (
    "context"
    "database/sql"
    "encoding/json"
    "errors"
    "fmt"
    "hamstercare/internal/database"
    "hamstercare/internal/middleware"
    "hamstercare/internal/model"
    "hamstercare/internal/repository"
    "hamstercare/internal/service"
    "hamstercare/internal/websocket"
    "log"
    "net/http"
    "time"

    "github.com/gin-gonic/gin"
    gorillawebsocket "github.com/gorilla/websocket"
)

func SetupUserRoutes(r *gin.RouterGroup, db *sql.DB, wsHub *websocket.Hub) {
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

    // Start sensor monitoring in the background
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
                    "id":         cage.ID,
                    "name":       cage.Name,
                    "num_device": cage.NumDevice,
                    "status":     cage.Status,
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

        // Lấy dữ liệu sensor mới nhất qua HTTP
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
                    "id":         id,
                    "value":      value,
                    "unit":       unit,
                    "timestamp":  createdAt.Format(time.RFC3339),
                }
            }

            c.JSON(http.StatusOK, sensorData)
        })

        // Lấy thống kê nước tiêu thụ
        r.GET("/cages/:cageID/statistics", ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
            cageID := c.Param("cageID")
            rangeType := c.Query("range") // daily, weekly, monthly
            startDate := c.Query("start_date") // YYYY-MM-DD
            endDate := c.Query("end_date") // YYYY-MM-DD

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
                    "date":           date,
                    "water_refill_sl": waterRefillSl,
                })
                totalRefills += waterRefillSl
                countDays++
            }

            // Calculate summary
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

        // Cấu hình ngưỡng thông báo sử dụng nước cao
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

        // WebSocket endpoint cho dữ liệu sensor và thống kê thời gian thực
        r.GET("/cages/:cageID/sensors-data/ws", ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
            cageID := c.Param("cageID")
            userID, exists := c.Get("user_id")
            if !exists {
                log.Printf("[ERROR] user_id not found in context")
                c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
                return
            }

            // Upgrade HTTP connection to WebSocket
            upgrader := gorillawebsocket.Upgrader{
                ReadBufferSize:  1024,
                WriteBufferSize: 1024,
                CheckOrigin: func(r *http.Request) bool {
                    return true // Adjust for production
                },
            }
            ws, err := upgrader.Upgrade(c.Writer, c.Request, nil)
            if err != nil {
                log.Printf("[ERROR] Error upgrading to WebSocket: %v", err)
                return
            }

            // Register client with WebSocket hub
            client := &websocket.Client{
                UserID: userID.(string),
                CageID: cageID,
                Conn:   ws,
                Send:   make(chan []byte),
            }
            wsHub.Register <- client

            // Start client read/write loops
            go client.WritePump()
            go client.ReadPump(wsHub)
        })

        // Xem chi tiết một chuồng (a cage) của user
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

            var actionType string = "on_off"
            if device.Type == "pump" {
                actionType = "refill"
            }

            c.JSON(http.StatusOK, gin.H{
                "id":             device.ID,
                "name":           device.Name,
                "status":         device.Status,
                "action_type":    actionType,
                "automation_rule": automationRules,
                "schedule_rule":  scheduleRules,
            })
        })

        // Thêm automation rule cho thiết bị
        r.POST("/devices/:deviceID/automations", ownershipMiddleware(deviceRepo, "deviceID"), func(c *gin.Context) {
            deviceID := c.Param("deviceID")

            var req struct {
                SensorID  string  `json:"sensor_id" binding:"required"`
                Condition string  `json:"condition" binding:"required"`
                Threshold float64 `json:"threshold" binding:"required"`
                Action    string  `json:"action" binding:"required"`
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

            validActions := map[string]bool{"turn_on": true, "turn_off": true, "refill": true, "lock": true}
            if !validActions[req.Action] {
                c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid action"})
                return
            }

            if req.Action == "refill" || req.Action == "lock" {
                if err := deviceService.ValidateDeviceAction(c.Request.Context(), deviceID, req.Action); err != nil {
                    log.Printf("[ERROR] %v", err)
                    c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
                    return
                }
            }

            // Get sensor unit
            var sensorUnit string
            err := db.QueryRowContext(c.Request.Context(), `
                SELECT unit FROM sensors WHERE id = $1
            `, req.SensorID).Scan(&sensorUnit)
            if err != nil {
                log.Printf("[ERROR] Error fetching sensor unit: %v", err)
                c.JSON(http.StatusBadRequest, gin.H{"error": "Sensor not found"})
                return
            }

            rule := &model.AutomationRule{
                SensorID:  req.SensorID,
                DeviceID:  deviceID,
                Condition: req.Condition,
                Threshold: req.Threshold,
                Unit:      sensorUnit,
                Action:    req.Action,
            }
            createRule, err := automationService.AddAutomationRule(c.Request.Context(), rule, cageService)
            if err != nil {
                switch {
                case errors.Is(err, service.ErrDifferentCage):
                    log.Printf("[ERROR] Sensor [%s] and device [%s] are not in the same cage.", req.SensorID, deviceID)
                    c.JSON(http.StatusBadRequest, gin.H{"error": "Sensor and device are not in the same cage."})
                default:
                    log.Printf("[ERROR] Failed to create automation rule: %v", err.Error())
                    c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
                }
                return
            }

            c.JSON(http.StatusOK, gin.H{
                "message": "Automation rule created successfully",
                "id":      createRule.ID,
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
                ExecutionTime string   `json:"execution_time" binding:"required"`
                Days          []string `json:"days" binding:"required"`
                Action        string   `json:"action" binding:"required,oneof=turn_on turn_off refill lock"`
            }

            if err := c.ShouldBindJSON(&req); err != nil {
                log.Printf("[ERROR] Invalid request body: %v", err.Error())
                c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
                return
            }

            // Kiểm tra ExecutionTime có đúng định dạng HH:MM không
            parsedTime, parseErr := time.Parse("15:04", req.ExecutionTime)
            if parseErr != nil {
                log.Printf("[ERROR] due to invalid execution_time format: %v", parseErr.Error())
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

            if req.Action == "refill" || req.Action == "lock" {
                if err := deviceService.ValidateDeviceAction(c.Request.Context(), deviceID, req.Action); err != nil {
                    log.Printf("[ERROR] %v", err)
                    c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
                    return
                }
            }

            rule := &model.ScheduleRule{
                ExecutionTime: parsedTime.Format("15:04"),
                Days:          req.Days,
                DeviceID:      deviceID,
                Action:        req.Action,
            }

            createSchedule, err := scheduleService.AddScheduleRule(c.Request.Context(), rule)
            if err != nil {
                log.Printf("[ERROR] Failed to create schedule rule: %v", err.Error())
                c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
                return
            }

            c.JSON(http.StatusOK, gin.H{
                "message": "Schedule rule created successfully",
                "id":      createSchedule.ID,
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

        // Thêm API điều khiển thiết bị thủ công
        r.POST("/devices/:deviceID/control", ownershipMiddleware(deviceRepo, "deviceID"), func(c *gin.Context) {
            deviceID := c.Param("deviceID")
            userID, exists := c.Get("user_id")
            if !exists {
                log.Printf("[ERROR] user_id not found in context")
                c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
                return
            }

            var req struct {
                Action string `json:"action" binding:"required,oneof=turn_on turn_off refill lock"`
            }

            if err := c.ShouldBindJSON(&req); err != nil {
                log.Printf("[ERROR] Invalid request body: %v", err.Error())
                c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
                return
            }

            // Get current device status
            var currentStatus string
            err := db.QueryRowContext(c.Request.Context(), `
                SELECT status FROM devices WHERE id = $1
            `, deviceID).Scan(&currentStatus)
            if err != nil {
                log.Printf("[ERROR] Error fetching device status: %v", err)
                c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
                return
            }

            // Prevent "refill" if device is locked
            if currentStatus == "locked" && req.Action == "refill" {
                c.JSON(http.StatusForbidden, gin.H{"error": "Cannot refill while device is locked"})
                return
            }

            // Validate action for device type
            if req.Action == "refill" || req.Action == "lock" {
                if err := deviceService.ValidateDeviceAction(c.Request.Context(), deviceID, req.Action); err != nil {
                    log.Printf("[ERROR] Invalid action for device %s: %v", deviceID, err)
                    c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
                    return
                }
            }

            // Get device details for cage_id and user_id
            device, err := deviceService.GetDeviceByID(c.Request.Context(), deviceID)
            if err != nil {
                log.Printf("[ERROR] Error fetching device %s: %v", deviceID, err)
                c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
                return
            }

            // Map action to status
            var newStatus string
            switch req.Action {
            case "turn_on":
                newStatus = "on"
            case "turn_off":
                newStatus = "off"
            case "refill":
                newStatus = "on" // Assuming refill sets the device to "on"
            case "lock":
                newStatus = "locked"
            }

            // Update device status in database
            _, err = db.ExecContext(c.Request.Context(), `
                UPDATE devices
                SET status = $1, last_status = status, updated_at = $2
                WHERE id = $3
            `, newStatus, time.Now().Format(time.RFC3339), deviceID)
            if err != nil {
                log.Printf("[ERROR] Error updating device %s status: %v", deviceID, err)
                c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
                return
            }

            // If action is refill and not locked, update water statistic
            if req.Action == "refill" && currentStatus != "locked" {
                if err := database.UpdateWaterStatistic(db, device.CageID); err != nil {
                    log.Printf("[ERROR] Error updating water statistic: %v", err)
                }
            }

            // Publish to MQTT
            topic := fmt.Sprintf("hamster/%s/%s/device/%s", userID.(string), device.CageID, deviceID)
            payload := map[string]interface{}{
                "device_id":   deviceID,
                "device_type": device.Type,
                "value":       req.Action,
                "timestamp":   time.Now().Format(time.RFC3339),
            }
            payloadBytes, err := json.Marshal(payload)
            if err != nil {
                log.Printf("[ERROR] Error marshaling MQTT payload: %v", err)
            } else {
                log.Printf("[INFO] Publishing to MQTT topic %s: %s", topic, string(payloadBytes))
                // Assume MQTT client is accessible via mqtt.Client
                // mqtt.Client.Publish(topic, 0, false, payloadBytes)
            }

            // Send notification via WebSocket
            notification := websocket.Notification{
                Type:    "device_action",
                Message: fmt.Sprintf("Device %s %s", device.Name, req.Action),
                CageID:  device.CageID,
                Time:    time.Now().Format(time.RFC3339),
            }
            if currentStatus == "locked" && req.Action == "refill" {
                notification.Message = fmt.Sprintf("Cannot refill device %s: device is locked", device.Name)
            }
            wsHub.Broadcast <- websocket.Message{
                CageID: device.CageID,
                Data:   notification,
            }

            // Store the device action notification in the database
            _, err = db.ExecContext(c.Request.Context(), `
                INSERT INTO notifications (user_id, cage_id, type, message, is_read, created_at)
                VALUES ($1, $2, $3, $4, $5, $6)
            `, userID.(string), device.CageID, "device_action", notification.Message, false, time.Now())
            if err != nil {
                log.Printf("[ERROR] Error storing device action notification: %v", err)
            }

            c.JSON(http.StatusOK, gin.H{
                "message": "Device action executed successfully",
            })
        })

        // API to get notifications for the user
        r.GET("/notifications", func(c *gin.Context) {
            userID, exists := c.Get("user_id")
            if !exists {
                log.Printf("[ERROR] user_id not found in context")
                c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
                return
            }

            // Query unread notifications
            rows, err := db.QueryContext(c.Request.Context(), `
                SELECT id, user_id, cage_id, type, message, is_read, created_at
                FROM notifications
                WHERE user_id = $1 AND is_read = FALSE
                ORDER BY created_at DESC
            `, userID.(string))
            if err != nil {
                log.Printf("[ERROR] Error querying notifications for user %s: %v", userID, err)
                c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
                return
            }
            defer rows.Close()

            notifications := []model.Notification{}
            for rows.Next() {
                var n model.Notification
                if err := rows.Scan(&n.ID, &n.UserID, &n.CageID, &n.Type, &n.Message, &n.IsRead, &n.CreatedAt); err != nil {
                    log.Printf("[ERROR] Error scanning notification: %v", err)
                    continue
                }
                notifications = append(notifications, n)
            }

            c.JSON(http.StatusOK, gin.H{
                "notifications": notifications,
            })
        })

        // API to mark a notification as read
        r.PUT("/notifications/:notificationID/read", func(c *gin.Context) {
            userID, exists := c.Get("user_id")
            if !exists {
                log.Printf("[ERROR] user_id not found in context")
                c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
                return
            }

            notificationID := c.Param("notificationID")

            // Verify the notification belongs to the user
            var ownerID string
            err := db.QueryRowContext(c.Request.Context(), `
                SELECT user_id FROM notifications WHERE id = $1
            `, notificationID).Scan(&ownerID)
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

            // Mark the notification as read
            _, err = db.ExecContext(c.Request.Context(), `
                UPDATE notifications
                SET is_read = TRUE
                WHERE id = $1
            `, notificationID)
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

// monitorSensors periodically checks all sensor data against automation rules and sends notifications if conditions are met.
func monitorSensors(db *sql.DB, wsHub *websocket.Hub) {
    ticker := time.NewTicker(10 * time.Second)
    defer ticker.Stop()

    lastNotified := make(map[string]time.Time)

    for range ticker.C {
        rows, err := db.QueryContext(context.Background(), `
            SELECT ar.id, ar.sensor_id, ar.device_id, ar.condition, ar.threshold, ar.action,
                   s.cage_id, s.type AS sensor_type, s.unit, d.name AS device_name, c.user_id
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
            Unit       string // Now fetched from sensors
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
                &r.CageID, &r.SensorType, &r.Unit, &r.DeviceName, &r.UserID); err != nil {
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
                case "refill":
                    actionVerb = "bơm nước cho"
                case "lock":
                    actionVerb = "khóa"
                }
                message := fmt.Sprintf("%s %.1f%s vượt ngưỡng %.1f%s: Hãy %s %s",
                    rule.SensorType, value, rule.Unit, rule.Threshold, rule.Unit, actionVerb, rule.DeviceName)

                wsNotification := websocket.Notification{
                    Type:    "sensor_alert",
                    Message: message,
                    CageID:  rule.CageID,
                    Time:    time.Now().Format(time.RFC3339),
                }
                wsHub.Broadcast <- websocket.Message{
                    CageID: rule.CageID,
                    Data:   wsNotification,
                }

                _, err = db.ExecContext(context.Background(), `
                    INSERT INTO notifications (user_id, cage_id, type, message, is_read, created_at)
                    VALUES ($1, $2, $3, $4, $5, $6)
                `, rule.UserID, rule.CageID, "sensor_alert", message, false, time.Now())
                if err != nil {
                    log.Printf("[ERROR] Error storing notification: %v", err)
                }

                lastNotified[notificationKey] = time.Now()
                log.Printf("[INFO] Sent sensor alert for cage %s: %s", rule.CageID, message)
            }
        }
    }
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