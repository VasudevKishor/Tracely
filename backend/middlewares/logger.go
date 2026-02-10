package middlewares

import (
	"log"
	"time"

	"github.com/gin-gonic/gin"
)

// RequestLogger is a Gin middleware that logs detailed information
// about every incoming HTTP request and its lifecycle.
func RequestLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Record the time at which the request was received
		// This is used later to calculate total request duration
		startTime := time.Now()
		// Store the request start time in Gin context
		c.Set("request_time", startTime)

		// Pass control to the next middleware/handler in the chain
		c.Next()

		// Log structured request details including:
		// - HTTP method (GET, POST, etc.)
		// - Request path
		// - Client IP address
		// - HTTP response status code
		// - Total execution time
		// - Distributed tracing identifiers (Trace ID, Span ID, Parent Span ID)
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
