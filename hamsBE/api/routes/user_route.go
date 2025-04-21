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
	"time"

	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func SetupUserRoutes(r *gin.RouterGroup, db *sql.DB) {
	userRepo := repository.NewUserRepository(db)

	cageRepo := repository.NewCageRepository(db)
	cageService := service.NewCageService(cageRepo, userRepo)

	deviceRepo := repository.NewDeviceRepository(db)
	deviceService := service.NewDeviceService(deviceRepo, cageRepo)

	//sensorRepo := repository.NewSensorRepository(db)
	//sensorService := service.NewSensorService(sensorRepo, cageRepo)

	automationRepo := repository.NewAutomationRepository(db)
	automationService := service.NewAutomationService(automationRepo)

	scheduleRepo := repository.NewScheduleRepository(db)
	scheduleService := service.NewScheduleService(scheduleRepo)


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
		
			c.JSON(http.StatusOK, cages)
		})

		// Thêm 1 API cho FE cập nhật value sensor 
		// Gửi dữ liệu cảm biến có giá trị lấy ra từ redis

		// Xem chi tiết một chuồng (a cage) của user
		r.GET("/cages/:cageID",ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
			cageID := c.Param("cageID")
			
			cage, err := cageService.GetACageByCageID(c.Request.Context(), cageID)
			if err != nil {
				log.Printf("[ERROR] Error fetching cage %s: %v", cageID, err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			// Lay gia trị cua sensor từ redis 

			// sensors, err := sensorService.GetSensorsByCageID(c.Request.Context(), cageID)
			// if err != nil {
			// 	log.Printf("[ERROR] Error fetching sensors for cage %s: %v", cageID, err.Error())
			// 	c.JSON(http.StatusNotFound, gin.H{"error": "Internal Server Error"})
			// 	return
			// }
			devices, err := deviceService.GetDevicesByCageID(c.Request.Context(), cageID)
			if err != nil {
				log.Printf("[ERROR] Error fetching devices for cage %s: %v", cageID, err.Error())
				c.JSON(http.StatusNotFound, gin.H{"error": "Internal Server Error"})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"id": cage.ID,
				"name": cage.Name,
				"status": cage.Status,
				//"sensors": sensors,
				"devices": devices,
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

			c.JSON(http.StatusOK, gin.H{
				"id": device.ID,
				"name": device.Name,
				"status": device.Status,
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

		// Bật / Tắt / Auto device
		// Active/ Inactive cage
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
