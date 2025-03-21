// api/routes/user.go
package routes

import (
	"context"
	"database/sql"
	"fmt"
	"hamstercare/internal/middleware"
	"hamstercare/internal/model"
	"hamstercare/internal/repository"
	"hamstercare/internal/service"

	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func SetupUserRoutes(r *gin.RouterGroup, db *sql.DB) {
	userRepo := repository.NewUserRepository(db)

	cageRepo := repository.NewCageRepository(db)
	cageService := service.NewCageService(cageRepo)

	sensorRepo := repository.NewSensorRepository(db)
	sensorService := service.NewSensorService(sensorRepo)

	deviceRepo := repository.NewDeviceRepository(db)
	deviceService := service.NewDeviceService(deviceRepo)

	automationRepo := repository.NewAutomationRepository(db)
	automationService := service.NewAutomationService(automationRepo)


	user := r.Group("/user")
	user.Use(middleware.JWTMiddleware())
	{
		user.GET("/:id", func(c *gin.Context) {
			id := c.Param("id")
			user, err := userRepo.GetUserByID(c.Request.Context(), id)
			if err != nil {
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
				return
			}
			c.JSON(http.StatusOK, user)
		})

		// Lấy danh sách chuồng (cages) của user
		user.GET("/cages", func(c *gin.Context) {
			userID, exists := c.Get("user_id")
			if !exists {
				log.Printf("user_id not found in context")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
				return
			}
			
			cages, err := cageService.GetCagesByUserID(c.Request.Context(), userID.(string))
			if err != nil {
				log.Printf("Error fetching cages for user %s: %v", userID, err.Error())
				c.JSON(http.StatusNotFound, gin.H{"error": "Internal Server Error"})
				return
			}
		
			c.JSON(http.StatusOK, cages)
		})

		// Xem chi tiết một chuồng (a cage) của user
		user.GET("/cages/:cageID",ownershipMiddleware(cageRepo, "cageID"), func(c *gin.Context) {
			cageID := c.Param("cageID")
			
			cage, err := cageService.GetACageByCageID(c.Request.Context(), cageID)
			if err != nil {
				log.Printf("Error fetching cage %s: %v", cageID, err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			sensors, err := sensorService.GetSensorsByCageID(c.Request.Context(), cageID)
			if err != nil {
				log.Printf("Error fetching sensors for cage %s: %v", cageID, err.Error())
				c.JSON(http.StatusNotFound, gin.H{"error": "Internal Server Error"})
				return
			}
			devices, err := deviceService.GetDevicesByCageID(c.Request.Context(), cageID)
			if err != nil {
				log.Printf("Error fetching devices for cage %s: %v", cageID, err.Error())
				c.JSON(http.StatusNotFound, gin.H{"error": "Internal Server Error"})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"id": cage.ID,
				"name": cage.Name,
				"sensors": sensors,
				"devices": devices,
			})
		})

		// Xem chi tiết một thiết bị (device) của user
		user.GET("/devices/:deviceID", ownershipMiddleware(deviceRepo, "deviceID"), func(c *gin.Context) {
			deviceID := c.Param("deviceID")
			
			device, err := deviceService.GetDeviceByID(c.Request.Context(), deviceID)
			if err != nil {
				log.Printf("Error fetching device %s: %v", deviceID, err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			} 

			rules, err := automationService.GetRulesByDeviceID(c.Request.Context(), deviceID) 
			if err != nil {
				log.Printf("Error fetching rules for device %s: %v", deviceID, err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			} 

			c.JSON(http.StatusOK, gin.H{
				"id": device.ID,
				"name": device.Name,
				"status": device.Status,
				"rule": rules,
			})
		})

		// Thêm automation rule cho thiết bị
		user.POST("/devices/:deviceID/automations", ownershipMiddleware(deviceRepo, "deviceID"), func(c *gin.Context) {
			deviceID := c.Param("deviceID")
			
			var req struct {
				SensorID 	string `json:"sensor_id" binding:"required"`
				Condition 	string `json:"condition" binding:"required"`
				Threshold 	float64 `json:"threshold" binding:"required"`
				Unit 		string `json:"unit" binding:"required"`
				Action 		string `json:"action" binding:"required"`
			}

			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("Invalid request body: %v", err.Error())
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			validConditions := map[string]bool{"<": true, ">": true, "=": true, ">=": true, "<=": true}
			if !validConditions[req.Condition] {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid condition"})
				return
			}

			validActions := map[string]bool{"turn_on": true, "turn_off": true}
			if !validActions[req.Action] {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid action"})
				return
			}


			rule := &model.AutomationRule{
				SensorID:  req.SensorID,
				DeviceID:  deviceID,
				Condition: req.Condition,
				Threshold: req.Threshold,
				Unit:      req.Unit,
				Action:    req.Action,
			}
			createRule, err := automationService.AddAutomationRule(c.Request.Context(), rule) 
			if err != nil {
				log.Printf("Failed to create automation rule: %v", err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			} 

			c.JSON(http.StatusOK, gin.H{
				"message": "Automation rule created successfully",
				"id": createRule.ID,
			})
		})

		// Xóa automation rule
		user.DELETE("/automations/:ruleID", ownershipMiddleware(automationRepo, "ruleID"), func(c *gin.Context) {
			ruleID := c.Param("ruleID")
			
			err := automationService.RemoveAutomationRule(c.Request.Context(), ruleID)
			if err != nil {
				log.Printf("Failed to delete automation rule: %v", err.Error())
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			} 

			c.JSON(http.StatusOK, gin.H{
				"message": "Automation rule deleted successfully",
			})
		})

	}
}
// OwnershipChecker định nghĩa interface kiểm tra quyền sở hữu
type ownershipChecker interface {
    IsOwnedByUser(ctx context.Context, userID, entityID string) (bool, error)
}

// ownershipMiddleware kiểm tra quyền sở hữu của user đối với thực thể (cage, device, automation_rule)
func ownershipMiddleware(repo ownershipChecker, paramName string) gin.HandlerFunc {
    return func(c *gin.Context) {
        userID, exists := c.Get("user_id")
        if !exists {
            log.Println("Missing userID in context")
            c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
            c.Abort()
            return
        }

        entityID := c.Param(paramName)
        if entityID == "" {
            log.Printf("Missing %s in request", paramName)
            c.JSON(http.StatusBadRequest, gin.H{"error": fmt.Sprintf("%s is required", paramName)})
            c.Abort()
            return
        }

        owned, err := repo.IsOwnedByUser(c.Request.Context(), userID.(string), entityID)
        if err != nil {
            log.Printf("Error checking ownership: %v", err)
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
            c.Abort()
            return
        }

        if !owned {
            log.Printf("Unauthorized access: User %s does not own %s %s", userID, paramName, entityID)
            c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
            c.Abort()
            return
        }

        c.Next()
    }
}
