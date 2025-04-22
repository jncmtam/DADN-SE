package routes

import (
	"errors"
	"hamstercare/internal/middleware"
	"hamstercare/internal/model"
	"hamstercare/internal/service"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

func SetupUserRoutes(r *gin.RouterGroup, cageService *service.CageService, sensorService *service.SensorService, deviceService *service.DeviceService, automationService *service.AutomationService, scheduleService *service.ScheduleService) {
	users := r.Group("/users")
	{
		// Create a cage for the authenticated user
		users.POST("/:user_id/cages", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			var req struct {
				Name string `json:"name" binding:"required,max=100"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "code": "invalid_request"})
				return
			}

			cage, err := cageService.CreateCage(c.Request.Context(), req.Name, userID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrUserNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "user_not_found"})
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create cage", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusCreated, cage)
		})

		// Get all cages for a user
		users.GET("/:user_id/cages", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			cages, err := cageService.GetCagesByUserID(c.Request.Context(), userID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrUserNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "user_not_found"})
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get cages", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, cages)
		})

		// Get a specific cage by ID
		users.GET("/:user_id/cages/:cage_id", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			cageID := c.Param("cage_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			cage, err := cageService.GetACageByCageID(c.Request.Context(), cageID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrCageNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "cage_not_found"})
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get cage", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, cage)
		})

		// Delete a cage
		users.DELETE("/:user_id/cages/:cage_id", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			cageID := c.Param("cage_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			err := cageService.DeleteCage(c.Request.Context(), cageID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrCageNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "cage_not_found"})
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete cage", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, gin.H{"message": "Cage deleted successfully"})
		})

		// Add a sensor to a cage
		users.POST("/:user_id/cages/:cage_id/sensors", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			cageID := c.Param("cage_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			var req struct {
				Name       string `json:"name" binding:"required,max=100"`
				SensorType string `json:"sensor_type" binding:"required,oneof=temperature humidity light distance"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "code": "invalid_request"})
				return
			}

			sensor, err := sensorService.AddSensor(c.Request.Context(), req.Name, req.SensorType, cageID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrCageNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "cage_not_found"})
				case strings.Contains(err.Error(), "invalid sensorType"):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_sensor_type"})
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add sensor", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusCreated, sensor)
		})

		// Get sensors for a cage
		users.GET("/:user_id/cages/:cage_id/sensors", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			cageID := c.Param("cage_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			sensors, err := sensorService.GetSensorsByCageID(c.Request.Context(), cageID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get sensors", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, sensors)
		})

		// Delete a sensor
		users.DELETE("/:user_id/cages/:cage_id/sensors/:sensor_id", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			sensorID := c.Param("sensor_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			err := sensorService.DeleteSensor(c.Request.Context(), sensorID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrSensorNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "sensor_not_found"})
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete sensor", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, gin.H{"message": "Sensor deleted successfully"})
		})

		// Add a device to a cage
		users.POST("/:user_id/cages/:cage_id/devices", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			cageID := c.Param("cage_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			var req struct {
				Name       string `json:"name" binding:"required,max=100"`
				DeviceType string `json:"device_type" binding:"required,oneof=display lock light pump fan"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "code": "invalid_request"})
				return
			}

			device, err := deviceService.CreateDevice(c.Request.Context(), req.Name, req.DeviceType, cageID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrCageNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "cage_not_found"})
				case strings.Contains(err.Error(), "invalid deviceType"):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_device_type"})
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add device", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusCreated, device)
		})

		// Get devices for a cage
		users.GET("/:user_id/cages/:cage_id/devices", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			cageID := c.Param("cage_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			devices, err := deviceService.GetDevicesByCageID(c.Request.Context(), cageID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get devices", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, devices)
		})

		// Get a specific device
		users.GET("/:user_id/cages/:cage_id/devices/:device_id", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			deviceID := c.Param("device_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			device, err := deviceService.GetDeviceByID(c.Request.Context(), deviceID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrDeviceNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "device_not_found"})
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get device", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, device)
		})

		// Delete a device
		users.DELETE("/:user_id/cages/:cage_id/devices/:device_id", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			deviceID := c.Param("device_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			err := deviceService.DeleteDevice(c.Request.Context(), deviceID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrDeviceNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "device_not_found"})
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete device", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, gin.H{"message": "Device deleted successfully"})
		})

		// Add an automation rule
		users.POST("/:user_id/cages/:cage_id/automation", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			var req struct {
				SensorID  string  `json:"sensor_id" binding:"required"`
				DeviceID  string  `json:"device_id" binding:"required"`
				Condition string  `json:"condition" binding:"required,oneof=> < = >= <="`
				Threshold float64 `json:"threshold" binding:"required,gt=0"`
				Unit      string  `json:"unit" binding:"required"`
				Action    string  `json:"action" binding:"required,oneof=turn_on turn_off"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "code": "invalid_request"})
				return
			}

			rule := &model.AutomationRule{
				SensorID:  req.SensorID,
				DeviceID:  req.DeviceID,
				Condition: req.Condition,
				Threshold: req.Threshold,
				Unit:      req.Unit,
				Action:    req.Action,
			}

			createdRule, err := automationService.AddAutomationRule(c.Request.Context(), rule)
			if err != nil {
				switch {
				case strings.Contains(err.Error(), "all fields are required") || err.Error() == "automation rule is required":
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "missing_fields"})
				case strings.Contains(err.Error(), "invalid condition"):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_condition"})
				case strings.Contains(err.Error(), "invalid action"):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_action"})
				case errors.Is(err, service.ErrDifferentCage):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "different_cage"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add automation rule", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusCreated, createdRule)
		})

		// Get automation rules for a device
		users.GET("/:user_id/cages/:cage_id/devices/:device_id/automation", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			deviceID := c.Param("device_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			rules, err := automationService.GetRulesByDeviceID(c.Request.Context(), deviceID)
			if err != nil {
				switch {
				case strings.Contains(err.Error(), "deviceID is required"):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "missing_device_id"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get automation rules", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, rules)
		})

		// Delete an automation rule
		users.DELETE("/:user_id/cages/:cage_id/automation/:rule_id", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			ruleID := c.Param("rule_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			err := automationService.RemoveAutomationRule(c.Request.Context(), ruleID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrRuleNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "rule_not_found"})
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete automation rule", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, gin.H{"message": "Automation rule deleted successfully"})
		})

		// Add a schedule rule
		users.POST("/:user_id/cages/:cage_id/schedule", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			var req struct {
				DeviceID      string   `json:"device_id" binding:"required"`
				ExecutionTime string   `json:"execution_time" binding:"required"`
				Days          []string `json:"days" binding:"required,dive,oneof=Mon Tue Wed Thu Fri Sat Sun"`
				Action        string   `json:"action" binding:"required,oneof=turn_on turn_off"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body", "code": "invalid_request"})
				return
			}

			rule := &model.ScheduleRule{
				DeviceID:      req.DeviceID,
				ExecutionTime: req.ExecutionTime,
				Days:          req.Days,
				Action:        req.Action,
			}

			createdRule, err := scheduleService.AddScheduleRule(c.Request.Context(), rule)
			if err != nil {
				switch {
				case strings.Contains(err.Error(), "all fields are required") || err.Error() == "schedule rule is required":
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "missing_fields"})
				case strings.Contains(err.Error(), "invalid day"):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_day"})
				case strings.Contains(err.Error(), "invalid action"):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_action"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to add schedule rule", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusCreated, createdRule)
		})

		// Get schedule rules for a device
		users.GET("/:user_id/cages/:cage_id/devices/:device_id/schedule", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			deviceID := c.Param("device_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			rules, err := scheduleService.GetRulesByDeviceID(c.Request.Context(), deviceID)
			if err != nil {
				switch {
				case strings.Contains(err.Error(), "deviceID is required"):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "missing_device_id"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get schedule rules", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, rules)
		})

		// Delete a schedule rule
		users.DELETE("/:user_id/cages/:cage_id/schedule/:rule_id", middleware.JWTMiddleware(), func(c *gin.Context) {
			userID := c.Param("user_id")
			ruleID := c.Param("rule_id")
			currentUserID := c.GetString("user_id")
			if userID != currentUserID {
				c.JSON(http.StatusForbidden, gin.H{"error": "Unauthorized access", "code": "unauthorized"})
				return
			}

			err := scheduleService.RemoveScheduleRule(c.Request.Context(), ruleID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrRuleNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": err.Error(), "code": "rule_not_found"})
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": err.Error(), "code": "invalid_uuid"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete schedule rule", "code": "internal_error"})
				}
				return
			}

			c.JSON(http.StatusOK, gin.H{"message": "Schedule rule deleted successfully"})
		})
	}
}