// api/routes/admin.go
package routes

import (
	"database/sql"
	"errors"
	"hamstercare/internal/middleware"
	"hamstercare/internal/repository"
	"hamstercare/internal/service"
	"log"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

func SetupAdminRoutes(r *gin.RouterGroup, db *sql.DB) {
	userRepo := repository.NewUserRepository(db)

	cageRepo := repository.NewCageRepository(db)
	cageService := service.NewCageService(cageRepo, userRepo)

	automationRepo := repository.NewAutomationRepository(db)

	deviceRepo := repository.NewDeviceRepository(db)
	deviceService := service.NewDeviceService(deviceRepo, cageRepo, automationRepo)

	sensorRepo := repository.NewSensorRepository(db)
	sensorService := service.NewSensorService(sensorRepo, cageRepo, automationRepo)


	otpRepo := repository.NewOTPRepository(db)
	authService := service.NewAuthService(userRepo, otpRepo)
	admin := r.Group("/admin")
	admin.Use(middleware.JWTMiddleware(), authMiddleware("admin"))
		// Lấy thông tin người dùng
		admin.GET("/users/:id", func(c *gin.Context) {
			id := c.Param("id")
			user, err := userRepo.GetUserByID(c.Request.Context(), id)
			if err != nil {
				log.Printf("Failed to get user by ID %s: %v", id, err)
				c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
				return
			}
			c.JSON(http.StatusOK, user)
		})
		admin.GET("/users", middleware.JWTMiddleware(), func(c *gin.Context) {
			users, err := authService.GetAllUsers(c.Request.Context())
			if err != nil {
				log.Printf("Failed to fetch users: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch users: " + err.Error()})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"message": "Users retrieved successfully",
				"users":   users,
			})
		})

		// Đăng ký người dùng mới (chỉ admin)
		admin.POST("/auth/register", func(c *gin.Context) {
			var req struct {
				Username string `json:"username" binding:"required"`
				Email    string `json:"email" binding:"required,email"`
				Password string `json:"password" binding:"required"`
				Role     string `json:"role" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
			if err != nil {
				log.Printf("Failed to hash password: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
				return
			}

			user, err := userRepo.CreateUser(c.Request.Context(), req.Username, req.Email, string(hash), req.Role)
			if err != nil {
				// Kiểm tra lỗi cụ thể từ PostgreSQL
				if pqErr, ok := err.(*pq.Error); ok {
					switch pqErr.Code {
					case "23505": // Unique violation
						if pqErr.Constraint == "users_email_key" {
							log.Printf("Duplicate email: %s, error: %v", req.Email, err)
							c.JSON(http.StatusConflict, gin.H{"error": "Email already exists"})
						} else if pqErr.Constraint == "unique_username" {
							log.Printf("Duplicate username: %s, error: %v", req.Username, err)
							c.JSON(http.StatusConflict, gin.H{"error": "Username already exists"})
						}
						return
					}
				}
				log.Printf("Failed to create user: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create user"})
				return
			}
			c.JSON(http.StatusCreated, gin.H{"message": "User registered successfully", "user_id": user.ID})
		})

		admin.DELETE("/users/:user_id", middleware.JWTMiddleware(), func(c *gin.Context) {
            // Kiểm tra quyền admin
            role, exists := c.Get("role")
            if !exists || role != "admin" {
                c.JSON(http.StatusForbidden, gin.H{"error": "Only admins can delete users"})
                return
            }

            userID := c.Param("user_id")
            if userID == "" {
                c.JSON(http.StatusBadRequest, gin.H{"error": "User ID is required"})
                return
            }

            err := authService.DeleteUser(c.Request.Context(), userID)
            if err != nil {
                log.Printf("Failed to delete user %s: %v", userID, err)
                if errors.Is(err, errors.New("user not found")) {
                    c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
                } else {
                    c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete user: " + err.Error()})
                }
                return
            }

            c.JSON(http.StatusOK, gin.H{
                "message":   "User deleted successfully",
                "user_id":   userID,
                "timestamp": time.Now().UTC(),
            })
        })

		// Tạo một chuồng (cage) mới cho user.
		admin.POST("/users/:id/cages", func(c *gin.Context) {
			userID := c.Param("id")
		
			var req struct {
				NameCage string `json:"name_cage" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			exists, err := cageService.IsCageNameExists(c.Request.Context(), userID, req.NameCage)
			if err != nil {
				log.Printf("[ERROR] Failed to check cage name uniqueness: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}
			if exists {
				log.Printf("[WARN] Duplicate cage name: %s for user: %s", req.NameCage, userID)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Cage name already exists"})
				return
			}

			// Tạo cage mới cho user
			cage, err := cageService.CreateCage(c.Request.Context(), req.NameCage, userID)
			if err != nil {
				switch {
					case errors.Is(err, service.ErrInvalidUUID): 
						log.Printf("[ERROR] Invalid UUID format for userID: %s", userID)
						c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
					case errors.Is(err, service.ErrUserNotFound):
						log.Printf("[ERROR] User not found: %s", userID)
						c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
					default:
						log.Printf("[ERROR] Failed to creating cage for user %s: %v", userID, err)
						c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
					}
					return
			}
			
			log.Printf("[INFO] Cage created successfully: (id: %s, name: %s", cage.ID, cage.Name)

			c.JSON(http.StatusCreated, gin.H{
				"message": "Cage created successfully",
				"id":      cage.ID,
				"name":    cage.Name,
			})
		})

		// Thêm một thiết bị (device) mới 
		admin.POST("/devices", func(c *gin.Context) {
			var req struct {
				Name   string `json:"name" binding:"required"`
				Type   string `json:"type" binding:"required,oneof=display lock light pump fan"`
				CageID string `json:"cageID"` // cageID có thể null
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}
		
			// Kiểm tra trùng tên thiết bị
			exists, err := deviceService.IsDeviceNameExists(c.Request.Context(), req.Name)
			if err != nil {
				log.Printf("[ERROR] Failed to check device name uniqueness: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}
			if exists {
				log.Printf("[ERROR] Device name already exists globally: %s", req.Name)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Device name already exists"})
				return
			}
		
			// Tạo thiết bị
			device, err := deviceService.CreateDevice(c.Request.Context(), req.Name, req.Type, req.CageID)
			if err != nil {
				log.Printf("[ERROR] Failed to create device (name: %s, type: %s): %v", req.Name, req.Type, err)
				switch {
					case errors.Is(err, service.ErrInvalidUUID):
						c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
					case errors.Is(err, service.ErrCageNotFound):
						c.JSON(http.StatusNotFound, gin.H{"error": "Cage not found"})
					default:
						c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				}
				return
			}
		
			log.Printf("[INFO] Device created successfully: (id: %s, name: %s, type: %s)", device.ID, device.Name, device.Type)
			c.JSON(http.StatusCreated, gin.H{
				"message": "Device created successfully",
				"id":      device.ID,
				"name":    device.Name,
			})
		})
		
		// Gán một thiết bị vào chuồng (assign a device to a cage)
		admin.PUT("/devices/:deviceID/cage", func(c *gin.Context) {
			deviceID := c.Param("deviceID")

			var req struct {
				CageID string `json:"cageID" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			err := deviceService.AssignDeviceToCage(c.Request.Context(), deviceID, req.CageID)
			if err != nil {
				log.Printf("[ERROR] Failed to assign device %s to cage %s: %v", deviceID, req.CageID, err)
				switch {
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
				case errors.Is(err, service.ErrDeviceNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
				case errors.Is(err, service.ErrCageNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": "Cage not found"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				}
				return
			}

			log.Printf("[INFO] Device %s assigned to cage %s successfully", deviceID, req.CageID)
			c.JSON(http.StatusOK, gin.H{
				"message": "Device assigned to cage successfully",
				"id":      deviceID,
				"cageID":  req.CageID,
			})
		})
		
		// Lấy 1 list device cho device drop down
		admin.GET("/devices", func(c *gin.Context) {
			deviceList, err := deviceService.GetDevicesAssignable(c.Request.Context())
			if err != nil {
				log.Printf("[ERROR] Failed to fetch assignable devices: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}
			c.JSON(http.StatusOK, deviceList)
		})

		// Lấy 1 list sensor cho sensor drop down
		admin.GET("/sensors", func(c *gin.Context) {
			sensorList, err := sensorService.GetSensorsAssignable(c.Request.Context())
			if err != nil {
				log.Printf("[ERROR] Failed to fetch assignable sensors: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}
			c.JSON(http.StatusOK, sensorList)
		})

		// Thêm một cảm biến (sensor) mới
		admin.POST("/sensors", func(c *gin.Context) {
			var req struct {
				Name string `json:"name" binding:"required"`
				Type string `json:"type" binding:"required,oneof=temperature humidity light water"`
				CageID string `json:"cageID"` // cageID có thể null
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			// Kiểm tra trùng tên sensor
			exists, err := sensorService.IsSensorNameExists(c.Request.Context(), req.Name)
			if err != nil {
				log.Printf("[ERROR] Failed to check sensor name uniqueness: %v", err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}
			if exists {
				log.Printf("[ERROR] Sensor name already exists globally: %s", req.Name)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Sensor name already exists"})
				return
			}

			// Tự động set unit theo type
			var unit string
			switch req.Type {
			case "temperature":
				unit = "oC"
			case "humidity":
				unit = "%"
			case "light":
				unit = "lux"
			case "water":
				unit = "mm"	
			default:
				unit = "unknown"
			}
		
			// Tạo thiết bị
			sensor, err := sensorService.AddSensor(c.Request.Context(), req.Name, req.Type, unit, req.CageID)
			if err != nil {
				switch {
					case errors.Is(err, service.ErrInvalidUUID): 
						log.Printf("[ERROR] Invalid UUID format for cageID: %s", req.CageID)
						c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
					case errors.Is(err, service.ErrCageNotFound):
						log.Printf("[ERROR] Cage not found: %s", req.CageID)
						c.JSON(http.StatusNotFound, gin.H{"error": "Cage not found"})
					default:
						log.Printf("[ERROR] Failed to creating sensor for cage %s (name: %s, type: %s): %v", req.CageID, req.Name, req.Type, err)
						c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
					}
					return
			}
		
			log.Printf("[INFO] Sensor created successfully: (id: %s, name: %s)", sensor.ID, sensor.Name)

			c.JSON(http.StatusCreated, gin.H{
				"message": "Sensor created successfully",
				"id":      sensor.ID,
				"name":    sensor.Name,
			})
		})

		// Gán một cảm biến vào chuồng (assign a sensor to a cage)
		admin.PUT("/sensors/:sensorID/cage", func(c *gin.Context) {
			sensorID := c.Param("sensorID")

			var req struct {
				CageID string `json:"cageID" binding:"required"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			err := sensorService.AssignSensorToCage(c.Request.Context(), sensorID, req.CageID)
			if err != nil {
				log.Printf("[ERROR] Failed to assign sensor %s to cage %s: %v", sensorID, req.CageID, err)
				switch {
				case errors.Is(err, service.ErrInvalidUUID):
					c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
				case errors.Is(err, service.ErrSensorNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": "Sensor not found"})
				case errors.Is(err, service.ErrCageNotFound):
					c.JSON(http.StatusNotFound, gin.H{"error": "Cage not found"})
				default:
					c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				}
				return
			}

			log.Printf("[INFO] Sensor %s assigned to cage %s successfully", sensorID, req.CageID)
			c.JSON(http.StatusOK, gin.H{
				"message": "Sensor assigned to cage successfully",
				"id":      sensorID,
				"cageID":  req.CageID,
			})
		})

		// Xóa một chuồng (cage)
		admin.DELETE("cages/:cageID", func(c *gin.Context) {
			cageID := c.Param("cageID")

			err := cageService.DeleteCage(c.Request.Context(), cageID)
			if err != nil {
				switch {
					case errors.Is(err, service.ErrInvalidUUID): 
						log.Printf("[ERROR] Invalid UUID format for cageID: %s", cageID)
						c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
					case errors.Is(err, service.ErrCageNotFound):
						log.Printf("[ERROR] Cage not found: %s", cageID)
						c.JSON(http.StatusNotFound, gin.H{"error": "Cage not found"})
					default:
						log.Printf("[ERROR] Failed to delete cage %s: %v", cageID, err)
						c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
					}
					return
			}

			log.Printf("[INFO] Cage deleted successfully: %s", cageID)

			c.JSON(http.StatusOK, gin.H{
				"message": "Cage deleted successfully",
			})
		})

		// Xóa một thiết bị (device)
		admin.DELETE("/devices/:deviceID", func(c *gin.Context) {
			deviceID := c.Param("deviceID")
		
			err := deviceService.UnassignDevice(c.Request.Context(), deviceID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrInvalidUUID):
					log.Printf("[ERROR] Invalid UUID format for deviceID: %s", deviceID)
					c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
				case errors.Is(err, service.ErrDeviceNotFound):
					log.Printf("[ERROR] Device not found: %s", deviceID)
					c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
				default:
					log.Printf("[ERROR] Failed to unassign device %s: %v", deviceID, err)
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				}
				return
			}
		
			log.Printf("[INFO] Device removed from cage successfully: %s", deviceID)
		
			c.JSON(http.StatusOK, gin.H{
				"message": "Device removed from cage successfully",
			})
		})
		

		// Xóa một cảm biến (sensor)
		admin.DELETE("/sensors/:sensorID", func(c *gin.Context) {
			sensorID := c.Param("sensorID")
		
			err := sensorService.UnassignSensor(c.Request.Context(), sensorID)
			if err != nil {
				switch {
				case errors.Is(err, service.ErrInvalidUUID):
					log.Printf("[ERROR] Invalid UUID format for sensorID: %s", sensorID)
					c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
				case errors.Is(err, service.ErrSensorNotFound):
					log.Printf("[ERROR] Sensor not found: %s", sensorID)
					c.JSON(http.StatusNotFound, gin.H{"error": "Sensor not found"})
				default:
					log.Printf("[ERROR] Failed to unassign sensor %s: %v", sensorID, err)
					c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
				}
				return
			}
		
			log.Printf("[INFO] Sensor unassigned successfully: %s", sensorID)
		
			c.JSON(http.StatusOK, gin.H{
				"message": "Sensor unassigned successfully",
			})
		})
		

		// Xem chi tiết của một chuồng (cage).
		admin.GET("/cages/:cageID", func(c *gin.Context) {
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
				log.Printf("Error fetching devices for cage %s: %v", cageID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			devicesRes := []map[string]interface{}{}

			for _, device := range devices {
				deviceMap := map[string]interface{}{
					"id":     device.ID,
					"name":   device.Name,
					"status": device.Mode,
				}
				devicesRes = append(devicesRes, deviceMap)
			}

			c.JSON(http.StatusOK, gin.H{
				"id": cage.ID,
				"name": cage.Name,
				"status": cage.Status,
				"sensors": sensors,
				"devices": devicesRes,
			})
		})

		// Lấy danh sách các chuồng (cages) của một user.
		admin.GET("/users/:id/cages", func(c *gin.Context) {
			userID := c.Param("id")
	
			cages, err := cageService.GetCagesByUserID(c.Request.Context(), userID)
			if err != nil {
				switch {
					case errors.Is(err, service.ErrInvalidUUID): 
						log.Printf("[ERROR] Invalid UUID format for userID: %s", userID)
						c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
					case errors.Is(err, service.ErrUserNotFound):
						log.Printf("[ERROR] User not found: %s", userID)
						c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
					default:
						log.Printf("[ERROR] Error fetching cages for user %s: %v", userID, err)
						c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
					}
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
}

func authMiddleware(requiredRole string) gin.HandlerFunc {
	return func(c *gin.Context) {
		userRole := c.GetString("role")
		if userRole != requiredRole {
			c.JSON(http.StatusForbidden, gin.H{"error": "Permission denied"})
			c.Abort()
			return
		}
		c.Next()
	}
}
