package routes

import (
	"hamstercare/controllers"

	"github.com/gin-gonic/gin"
)

func InitRoutes() *gin.Engine {
	r := gin.Default()
	r.GET("/devices", controllers.GetDevices)
	r.POST("/devices", controllers.CreateDevice)
	return r
}
