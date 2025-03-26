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

	deviceRepo := repository.NewDeviceRepository(db)
	deviceService := service.NewDeviceService(deviceRepo, cageRepo)

	sensorRepo := repository.NewSensorRepository(db)
	sensorService := service.NewSensorService(sensorRepo, cageRepo)


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

		// Thêm một thiết bị (device) mới vào chuồng.
		admin.POST("/cages/:cageID/devices", func(c *gin.Context) {
			cageID := c.Param("cageID")

			var req struct {
				Name string `json:"name" binding:"required"`
				Type string `json:"type" binding:"required,oneof=display lock light pump fan"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			device, err := deviceService.CreateDevice(c.Request.Context(), req.Name, req.Type, cageID)
			if err != nil {
				switch {
					case errors.Is(err, service.ErrInvalidUUID): 
						log.Printf("[ERROR] Invalid UUID format for cageID: %s", cageID)
						c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
					case errors.Is(err, service.ErrCageNotFound):
						log.Printf("[ERROR] Cage not found: %s", cageID)
						c.JSON(http.StatusNotFound, gin.H{"error": "Cage not found"})
					default:
						log.Printf("[ERROR] Failed to creating device for cage %s (name: %s, type: %s): %v", cageID, req.Name, req.Type, err)
						c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
					}
					return
			}
	
			log.Printf("[INFO] Device created successfully: (id: %s, name: %s, type: %s", device.ID, device.Name, device.Type)

			c.JSON(http.StatusCreated, gin.H{
				"message": "Device created successfully",
				"id":      device.ID,
				"name":    device.Name,
			})
		})

		// Thêm một cảm biến (sensor) mới vào chuồng 
		admin.POST("/cages/:cageID/sensors", func(c *gin.Context) {
			cageID := c.Param("cageID")

			var req struct {
				Name string `json:"name" binding:"required"`
				Type string `json:"type" binding:"required,oneof=temperature humidity light distance"`
			}
			if err := c.ShouldBindJSON(&req); err != nil {
				log.Printf("[ERROR] Invalid request body: %v", err)
				c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
				return
			}

			sensor, err := sensorService.AddSensor(c.Request.Context(), req.Name, req.Type, cageID)
			if err != nil {
				switch {
					case errors.Is(err, service.ErrInvalidUUID): 
						log.Printf("[ERROR] Invalid UUID format for cageID: %s", cageID)
						c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
					case errors.Is(err, service.ErrCageNotFound):
						log.Printf("[ERROR] Cage not found: %s", cageID)
						c.JSON(http.StatusNotFound, gin.H{"error": "Cage not found"})
					default:
						log.Printf("[ERROR] Failed to creating sensor for cage %s (name: %s, type: %s): %v", cageID, req.Name, req.Type, err)
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

			err := deviceService.DeleteDevice(c.Request.Context(), deviceID)
			if err != nil {
				switch {
					case errors.Is(err, service.ErrInvalidUUID): 
						log.Printf("[ERROR] Invalid UUID format for deviceID: %s", deviceID)
						c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
					case errors.Is(err, service.ErrDeviceNotFound):
						log.Printf("[ERROR] Device not found: %s", deviceID)
						c.JSON(http.StatusNotFound, gin.H{"error": "Device not found"})
					default:
						log.Printf("[ERROR] Failed to deleting device %s: %v", deviceID, err)
						c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					}
					return
			}
			
			log.Printf("[INFO] Device deleted successfully: %s", deviceID)

			c.JSON(http.StatusOK, gin.H{
				"message": "Device deleted successfully",
			})
		})

		// Xóa một cảm biến (sensor)
		admin.DELETE("/sensors/:sensorID", func(c *gin.Context) {
			sensorID := c.Param("sensorID")

			err := sensorService.DeleteSensor(c.Request.Context(), sensorID)
			if err != nil {
				switch {
					case errors.Is(err, service.ErrInvalidUUID): 
						log.Printf("[ERROR] Invalid UUID format for sensorID: %s", sensorID)
						c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid UUID format"})
					case errors.Is(err, service.ErrSensorNotFound):
						log.Printf("[ERROR] Sensor not found: %s", sensorID)
						c.JSON(http.StatusNotFound, gin.H{"error": "Sensor not found"})
					default:
						log.Printf("[ERROR] Failed to deleting sensor %s: %v", sensorID, err)
						c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
					}
					return
			}
			
			log.Printf("[INFO] Sensor deleted successfully: %s", sensorID)

			c.JSON(http.StatusOK, gin.H{
				"message": "Sensor deleted successfully",
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

			// Lấy id của sensor
			// 

			// sensors, err := sensorService.GetSensorsByCageID(c.Request.Context(), cageID)
			// if err != nil {
			// 	log.Printf("Error fetching sensors for cage %s: %v", cageID, err)
			// 	c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			// 	return
			// }
			devices, err := deviceService.GetDevicesByCageID(c.Request.Context(), cageID)
			if err != nil {
				log.Printf("Error fetching devices for cage %s: %v", cageID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal Server Error"})
				return
			}

			c.JSON(http.StatusOK, gin.H{
				"id": cage.ID,
				"name": cage.Name,
				//"sensors": sensors,
				"devices": devices,
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
		
			c.JSON(http.StatusOK, cages)
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
