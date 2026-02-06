package middlewares

import (
	"log"
	"time"

	"github.com/gin-gonic/gin"
)

func RequestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		startTime := time.Now()
		c.Set("request_time", startTime)

		// Process request
		c.Next()

		// Log request details
		duration := time.Since(startTime)
		log.Printf(
			"[%s] %s %s - Status: %d - Duration: %v - TraceID: %s - SpanID: %s - ParentSpanID: %s",
			c.Request.Method,
			c.Request.URL.Path,
			c.ClientIP(),
			c.Writer.Status(),
			duration,
			c.GetString("trace_id"),
			c.GetString("span_id"),
			c.GetString("parent_span_id"),
		)
	}
}
