package middlewares

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

/*
ErrorHandler is a global middleware that handles errors
collected during request processing.
It runs AFTER all other handlers using c.Next(),
checks if any errors were added to the Gin context,
logs the error, and returns a standardized JSON error response.
*/
func ErrorHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Execute the remaining handlers in the chain
		c.Next()

		// Check if there are any errors
		if len(c.Errors) > 0 {
			// Get the last error (most recent)
			err := c.Errors.Last()
			// Log the error for debugging/monitoring
			log.Printf("Error: %v", err.Error())

			// Return error response
			c.JSON(http.StatusInternalServerError, gin.H{
				"error":     "Internal server error",
				"details":   err.Error(),
				"timestamp": c.GetTime("request_time"),
			})
		}
	}
}
