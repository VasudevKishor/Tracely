package middlewares

import (
	"encoding/json"
	"math/rand"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// TracingConfig holds the configuration for per-service tracing
type TracingConfig struct {
	Enabled          bool
	SamplingRate     float64
	LogTraceHeaders  bool
	PropagateContext bool
	ExcludePaths     []string
}

// DefaultTracingConfig returns default tracing configuration
func DefaultTracingConfig() *TracingConfig {
	return &TracingConfig{
		Enabled:          true,
		SamplingRate:     1.0,
		LogTraceHeaders:  true,
		PropagateContext: true,
		ExcludePaths:     []string{},
	}
}

// TraceID creates a middleware that handles trace context propagation
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

// ServiceTracingMiddleware creates a middleware that respects per-service tracing configuration
// It requires database access to fetch service configurations
func ServiceTracingMiddleware(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		serviceName := c.GetHeader("X-Service-Name")
		if serviceName == "" {
			serviceName = "default"
		}

		// Get workspace ID from URL params or context
		workspaceIDStr := c.Param("workspace_id")
		var workspaceID uuid.UUID
		var err error
		if workspaceIDStr != "" {
			workspaceID, err = uuid.Parse(workspaceIDStr)
			if err != nil {
				workspaceID = uuid.Nil
			}
		}

		// Get tracing configuration for this service
		config := getServiceTracingConfig(db, workspaceID, serviceName)
		c.Set("tracing_config", config)
		c.Set("service_name", serviceName)

		// Check if tracing is enabled
		if !config.Enabled {
			c.Set("tracing_enabled", false)
			c.Next()
			return
		}

		// Check if path is excluded
		path := c.Request.URL.Path
		for _, excludePath := range config.ExcludePaths {
			if strings.HasPrefix(path, excludePath) || strings.Contains(path, excludePath) {
				c.Set("tracing_enabled", false)
				c.Next()
				return
			}
		}

		// Check sampling rate
		if config.SamplingRate < 1.0 && rand.Float64() >= config.SamplingRate {
			c.Set("tracing_enabled", false)
			c.Set("tracing_sampled_out", true)
			c.Next()
			return
		}

		c.Set("tracing_enabled", true)

		// Handle trace context if propagation is enabled
		if config.PropagateContext {
			traceID := c.GetHeader("X-Trace-ID")
			spanID := c.GetHeader("X-Span-ID")
			parentSpanID := c.GetHeader("X-Parent-Span-ID")

			if traceID == "" {
				traceID = uuid.New().String()
			}
			if spanID == "" {
				spanID = uuid.New().String()
			}

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
		}

		c.Next()
	}
}

// ServiceTracingConfig represents the database model (imported from models, defined here for query)
type serviceTracingConfigDB struct {
	Enabled          bool    `gorm:"column:enabled"`
	SamplingRate     float64 `gorm:"column:sampling_rate"`
	LogTraceHeaders  bool    `gorm:"column:log_trace_headers"`
	PropagateContext bool    `gorm:"column:propagate_context"`
	ExcludePaths     string  `gorm:"column:exclude_paths"`
}

// getServiceTracingConfig fetches tracing config from database
func getServiceTracingConfig(db *gorm.DB, workspaceID uuid.UUID, serviceName string) *TracingConfig {
	if db == nil || workspaceID == uuid.Nil {
		return DefaultTracingConfig()
	}

	var config serviceTracingConfigDB
	result := db.Table("service_tracing_configs").
		Select("enabled, sampling_rate, log_trace_headers, propagate_context, exclude_paths").
		Where("workspace_id = ? AND service_name = ? AND deleted_at IS NULL", workspaceID, serviceName).
		First(&config)

	if result.Error != nil {
		return DefaultTracingConfig()
	}

	tracingConfig := &TracingConfig{
		Enabled:          config.Enabled,
		SamplingRate:     config.SamplingRate,
		LogTraceHeaders:  config.LogTraceHeaders,
		PropagateContext: config.PropagateContext,
		ExcludePaths:     []string{},
	}

	// Parse exclude paths JSON
	if config.ExcludePaths != "" && config.ExcludePaths != "[]" {
		var paths []string
		if err := json.Unmarshal([]byte(config.ExcludePaths), &paths); err == nil {
			tracingConfig.ExcludePaths = paths
		}
	}

	return tracingConfig
}

// IsTracingEnabled is a helper to check if tracing is enabled from context
func IsTracingEnabled(c *gin.Context) bool {
	enabled, exists := c.Get("tracing_enabled")
	if !exists {
		return true // Default to enabled
	}
	return enabled.(bool)
}

// GetTracingConfig retrieves tracing config from context
func GetTracingConfig(c *gin.Context) *TracingConfig {
	config, exists := c.Get("tracing_config")
	if !exists {
		return DefaultTracingConfig()
	}
	return config.(*TracingConfig)
}
