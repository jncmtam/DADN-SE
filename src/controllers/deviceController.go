package controllers

import (
	"hamstercare/models"
	"net/http"

	"github.com/gin-gonic/gin"
)

func GetDevices(c *gin.Context) {
	devices := models.GetAllDevices()
	c.JSON(http.StatusOK, devices)
}

func CreateDevice(c *gin.Context) {
	var device models.Device
	if err := c.ShouldBindJSON(&device); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	models.CreateDevice(&device)
	c.JSON(http.StatusCreated, device)
}
