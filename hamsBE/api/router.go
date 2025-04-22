package api

import (
	"database/sql"
	"net/http"
	"hamstercare/api/routes"
	"hamstercare/internal/repository"
	"hamstercare/internal/service"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine, db *sql.DB) {
	api := r.Group("/api")

	api.GET("/ping", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"message": "pong"})
	})

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
	cageRepo := repository.NewCageRepository(db)
	sensorRepo := repository.NewSensorRepository(db)
	deviceRepo := repository.NewDeviceRepository(db)
	automationRepo := repository.NewAutomationRepository(db)
	scheduleRepo := repository.NewScheduleRepository(db)

	// Initialize services
	cageService := service.NewCageService(cageRepo, userRepo)
	sensorService := service.NewSensorService(sensorRepo, cageRepo)
	deviceService := service.NewDeviceService(deviceRepo, cageRepo)
	automationService := service.NewAutomationService(automationRepo, cageRepo)
	scheduleService := service.NewScheduleService(scheduleRepo)

	// Setup routes
	routes.SetupAuthRoutes(api, db)
	routes.SetupUserRoutes(api, cageService, sensorService, deviceService, automationService, scheduleService)
	routes.SetupAdminRoutes(api, db)
}