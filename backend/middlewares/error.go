package middlewares

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

func ErrorHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		// Check if there are any errors
		if len(c.Errors) > 0 {
			err := c.Errors.Last()
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
