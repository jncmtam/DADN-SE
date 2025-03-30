package middleware

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// ValidateUserID kiểm tra userID từ context
func ValidateUserID() gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := c.GetString("user_id")
		if userID == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
			c.Abort()
			return
		}
		c.Next()
	}
}

// ValidateJSONBody kiểm tra và bind JSON body
func ValidateJSONBody(req interface{}) gin.HandlerFunc {
	return func(c *gin.Context) {
		if err := c.ShouldBindJSON(req); err != nil {
			log.Printf("Invalid request body: %v", err)
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request body"})
			c.Abort()
			return
		}
		c.Next()
	}
}