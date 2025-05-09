package middleware

import (
	"errors"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

func JWTMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Get the Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			log.Println("Authorization header is missing")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header is required"})
			c.Abort()
			return
		}

		// Check the format of the Authorization header
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			log.Printf("Invalid Authorization header format: %s", authHeader)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid Authorization header format"})
			c.Abort()
			return
		}

		// Extract the token string
		tokenStr := parts[1]

		// Parse and validate the token
		token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
			// Verify the signing method
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}

			// Get the JWT_SECRET from environment variables
			jwtSecret := os.Getenv("JWT_SECRET_KEY")
			if jwtSecret == "" {
				return nil, jwt.ErrTokenSignatureInvalid
			}

			return []byte(jwtSecret), nil
		})

		// Check for parsing or validation errors
		if err != nil {
			log.Printf("Failed to parse token: %v", err)
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		// Verify token validity
		if !token.Valid {
			log.Println("Token is not valid")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		// Extract claims and set them in the context
		if claims, ok := token.Claims.(jwt.MapClaims); ok {
			// Type assertion for user_id
			userID, ok := claims["user_id"].(string)
			if !ok {
				log.Println("user_id claim is missing or not a string")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token claims"})
				c.Abort()
				return
			}

			// Type assertion for role
			role, ok := claims["role"].(string)
			if !ok {
				log.Println("role claim is missing or not a string")
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token claims"})
				c.Abort()
				return
			}

			// Set user_id and role in the context
			c.Set("user_id", userID)
			c.Set("role", role)
		} else {
			log.Println("Token claims are malformed")
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token claims"})
			c.Abort()
			return
		}

		// Proceed to the next handler
		c.Next()
	}
}

// TokenClaims chứa dữ liệu giải mã từ token
type TokenClaims struct {
	UserID string
	Role   string
}

// VerifyToken dùng để giải mã token JWT và trả về claims
func VerifyToken(tokenStr string) (*TokenClaims, error) {
	if tokenStr == "" {
		return nil, errors.New("token is required")
	}

	token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, jwt.ErrSignatureInvalid
		}
		secret := os.Getenv("JWT_SECRET_KEY")
		if secret == "" {
			return nil, errors.New("JWT secret is not configured")
		}
		return []byte(secret), nil
	})

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, errors.New("token is invalid or expired")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("invalid token claims structure")
	}

	userID, ok := claims["user_id"].(string)
	if !ok {
		return nil, errors.New("user_id claim missing or invalid")
	}

	role, ok := claims["role"].(string)
	if !ok {
		return nil, errors.New("role claim missing or invalid")
	}

	return &TokenClaims{
		UserID: userID,
		Role:   role,
	}, nil
}