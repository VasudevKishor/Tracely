package middlewares

import (
	"net/http"
	"strings"

	"backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AuthMiddleware is a Gin middleware that authenticates requests
// using a Bearer token passed in the Authorization header.

func AuthMiddleware(authService *services.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Read the Authorization header
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			// Reject request if header is missing
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Authorization header required",
			})
			c.Abort()
			return
		}

		// Extract token from "Bearer <token>"
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			// Reject request if header format is invalid
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid authorization header format",
			})
			c.Abort()
			return
		}
		// Extract the JWT token
		token := parts[1]
		// Validate the token and extract claims
		claims, err := authService.ValidateToken(token)
		if err != nil {
			// Token is invalid or expired
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid or expired token",
			})
			c.Abort()
			return
		}

		// // Parse the user ID from token claims
		userID, err := uuid.Parse(claims.UserID)
		if err != nil {
			// User ID in token is not a valid UUID
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid user ID in token",
			})
			c.Abort()
			return
		}
		// Store authenticated user information in Gin context
		// so it can be accessed by downstream handlers
		c.Set("user_id", userID)
		c.Set("user_email", claims.Email)
		// Continue to the next middleware or handler
		c.Next()
	}
}

// GetUserID retrieves the authenticated user ID from the Gin context.
// This should be called only after AuthMiddleware has run
func GetUserID(c *gin.Context) (uuid.UUID, error) {
	userID, exists := c.Get("user_id")
	if !exists {
		// User ID not found in context (middleware not applied or failed)
		return uuid.Nil, http.ErrNoCookie
	}
	// Type assert the stored value to uuid.UUID
	return userID.(uuid.UUID), nil
}
