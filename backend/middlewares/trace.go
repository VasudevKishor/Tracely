package middlewares

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func TraceID() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Check if trace ID exists in header
		traceID := c.GetHeader("X-Trace-ID")

		if traceID == "" {
			// Generate new trace ID
			traceID = uuid.New().String()
		}

		// Set trace ID in context and response header
		c.Set("trace_id", traceID)
		c.Header("X-Trace-ID", traceID)

		c.Next()
	}
}
