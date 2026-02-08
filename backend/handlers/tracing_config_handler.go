package handlers

import (
	"encoding/json"
	"net/http"

	"backend/middlewares"
	"backend/models"
	"backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// TracingConfigHandler handles HTTP requests for tracing configuration
type TracingConfigHandler struct {
	tracingConfigService *services.TracingConfigService
}

// NewTracingConfigHandler creates a new TracingConfigHandler
func NewTracingConfigHandler(tracingConfigService *services.TracingConfigService) *TracingConfigHandler {
	return &TracingConfigHandler{tracingConfigService: tracingConfigService}
}

// CreateConfigRequest represents the request body for creating a tracing config
type CreateConfigRequest struct {
	ServiceName         string                 `json:"service_name" binding:"required"`
	Enabled             *bool                  `json:"enabled"`
	SamplingRate        *float64               `json:"sampling_rate"`
	LogTraceHeaders     *bool                  `json:"log_trace_headers"`
	PropagateContext    *bool                  `json:"propagate_context"`
	CaptureRequestBody  *bool                  `json:"capture_request_body"`
	CaptureResponseBody *bool                  `json:"capture_response_body"`
	MaxBodySizeBytes    int                    `json:"max_body_size_bytes"`
	ExcludePaths        []string               `json:"exclude_paths"`
	CustomTags          map[string]interface{} `json:"custom_tags"`
	Description         string                 `json:"description"`
}

// UpdateConfigRequest represents the request body for updating a tracing config
type UpdateConfigRequest struct {
	Enabled             *bool    `json:"enabled"`
	SamplingRate        *float64 `json:"sampling_rate"`
	LogTraceHeaders     *bool    `json:"log_trace_headers"`
	PropagateContext    *bool    `json:"propagate_context"`
	CaptureRequestBody  *bool    `json:"capture_request_body"`
	CaptureResponseBody *bool    `json:"capture_response_body"`
	MaxBodySizeBytes    *int     `json:"max_body_size_bytes"`
	ExcludePaths        *string  `json:"exclude_paths"`
	CustomTags          *string  `json:"custom_tags"`
	Description         *string  `json:"description"`
}

// ToggleRequest represents the request body for toggling tracing
type ToggleRequest struct {
	Enabled bool `json:"enabled" binding:"required"`
}

// BulkToggleRequest represents the request body for bulk toggling
type BulkToggleRequest struct {
	ServiceNames []string `json:"service_names" binding:"required"`
	Enabled      bool     `json:"enabled" binding:"required"`
}

// GetAll retrieves all tracing configurations for a workspace
func (h *TracingConfigHandler) GetAll(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	configs, err := h.tracingConfigService.GetAllConfigs(workspaceID, userID)
	if err != nil {
		if err.Error() == "access denied" {
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"configs": configs,
		"count":   len(configs),
	})
}

// GetByID retrieves a specific tracing configuration
func (h *TracingConfigHandler) GetByID(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	configID, err := uuid.Parse(c.Param("config_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid config ID"})
		return
	}

	config, err := h.tracingConfigService.GetConfigByID(configID, userID)
	if err != nil {
		if err.Error() == "access denied" {
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
			return
		}
		if err.Error() == "record not found" {
			c.JSON(http.StatusNotFound, gin.H{"error": "Configuration not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, config)
}

// GetByServiceName retrieves tracing config for a specific service
func (h *TracingConfigHandler) GetByServiceName(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	serviceName := c.Param("service_name")
	if serviceName == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Service name is required"})
		return
	}

	config, err := h.tracingConfigService.GetConfigByServiceName(workspaceID, serviceName)
	if err != nil {
		if err.Error() == "record not found" {
			defaultConfig := h.tracingConfigService.GetTracingSettings(workspaceID, serviceName)
			c.JSON(http.StatusOK, gin.H{
				"config":     defaultConfig,
				"is_default": true,
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	_, err = h.tracingConfigService.GetConfigByID(config.ID, userID)
	if err != nil {
		if err.Error() == "access denied" {
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"config":     config,
		"is_default": false,
	})
}

// Create creates a new tracing configuration
func (h *TracingConfigHandler) Create(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	var req CreateConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.SamplingRate != nil {
		if *req.SamplingRate < 0 || *req.SamplingRate > 1 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Sampling rate must be between 0 and 1"})
			return
		}
	}

	excludePathsJSON, _ := json.Marshal(req.ExcludePaths)
	customTagsJSON, _ := json.Marshal(req.CustomTags)

	config := &models.ServiceTracingConfig{
		ServiceName: req.ServiceName,
		SamplingRate: func() float64 {
			if req.SamplingRate != nil {
				return *req.SamplingRate
			}
			return 1.0
		}(),
		MaxBodySizeBytes: req.MaxBodySizeBytes,
		ExcludePaths:     string(excludePathsJSON),
		CustomTags:        string(customTagsJSON),
		Description:      req.Description,
	}

	if req.Enabled != nil {
		config.Enabled = *req.Enabled
	} else {
		config.Enabled = true
	}
	if req.LogTraceHeaders != nil {
		config.LogTraceHeaders = *req.LogTraceHeaders
	} else {
		config.LogTraceHeaders = true
	}
	if req.PropagateContext != nil {
		config.PropagateContext = *req.PropagateContext
	} else {
		config.PropagateContext = true
	}
	if req.CaptureRequestBody != nil {
		config.CaptureRequestBody = *req.CaptureRequestBody
	}
	if req.CaptureResponseBody != nil {
		config.CaptureResponseBody = *req.CaptureResponseBody
	}

	createdConfig, err := h.tracingConfigService.CreateConfig(workspaceID, userID, config)
	if err != nil {
		switch err.Error() {
		case "access denied":
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		case "tracing configuration already exists for this service":
			c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		}
		return
	}

	c.JSON(http.StatusCreated, createdConfig)
}

// Update updates an existing tracing configuration
func (h *TracingConfigHandler) Update(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	configID, err := uuid.Parse(c.Param("config_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid config ID"})
		return
	}

	var req UpdateConfigRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.SamplingRate != nil {
		if *req.SamplingRate < 0 || *req.SamplingRate > 1 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Sampling rate must be between 0 and 1"})
			return
		}
	}

	updates := make(map[string]interface{})

	if req.Enabled != nil {
		updates["enabled"] = *req.Enabled
	}
	if req.SamplingRate != nil {
		updates["sampling_rate"] = *req.SamplingRate
	}
	if req.LogTraceHeaders != nil {
		updates["log_trace_headers"] = *req.LogTraceHeaders
	}
	if req.PropagateContext != nil {
		updates["propagate_context"] = *req.PropagateContext
	}
	if req.CaptureRequestBody != nil {
		updates["capture_request_body"] = *req.CaptureRequestBody
	}
	if req.CaptureResponseBody != nil {
		updates["capture_response_body"] = *req.CaptureResponseBody
	}
	if req.MaxBodySizeBytes != nil {
		updates["max_body_size_bytes"] = *req.MaxBodySizeBytes
	}
	if req.ExcludePaths != nil {
		updates["exclude_paths"] = *req.ExcludePaths
	}
	if req.CustomTags != nil {
		updates["custom_tags"] = *req.CustomTags
	}
	if req.Description != nil {
		updates["description"] = *req.Description
	}

	updatedConfig, err := h.tracingConfigService.UpdateConfig(configID, userID, updates)
	if err != nil {
		if err.Error() == "access denied" {
			c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
			return
		}
		if err.Error() == "record not found" {
			c.JSON(http.StatusNotFound, gin.H{"error": "Configuration not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, updatedConfig)
}

// Delete, Toggle, BulkToggle, etc. (Remain unchanged as they had no conflicts)