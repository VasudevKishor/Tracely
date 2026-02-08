package middlewares

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

func TraceID() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Check if trace ID exists in header
		traceID := c.GetHeader("X-Trace-ID")
		spanID := c.GetHeader("X-Span-ID")
		parentSpanID := c.GetHeader("X-Parent-Span-ID")
		if traceID == "" {
			// Generate new trace ID
			traceID = uuid.New().String()
		}
		if spanID == "" {
			spanID = uuid.New().String()
		}

		// Set trace ID in context and response header
		c.Set("trace_id", traceID)
		c.Set("span_id", spanID)
		if parentSpanID != "" {
			c.Set("parent_span_id", parentSpanID)
		}
		c.Header("X-Trace-ID", traceID)
		c.Header("X-Span-ID", spanID)
		if parentSpanID != "" {
			c.Header("X-Parent-Span-ID", parentSpanID)
		}
		c.Next()
	}
}
