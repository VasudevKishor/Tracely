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

type TracingConfigHandler struct {
	tracingConfigService *services.TracingConfigService
}

func NewTracingConfigHandler(tracingConfigService *services.TracingConfigService) *TracingConfigHandler {
	return &TracingConfigHandler{tracingConfigService: tracingConfigService}
}

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

// ... (GetAll and GetByID methods remain the same)

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
		CustomTags:       string(customTagsJSON),
		Description:      req.Description,
	}

	// Handle boolean pointers (allow explicit false)
	if req.Enabled != nil { config.Enabled = *req.Enabled } else { config.Enabled = true }
	if req.LogTraceHeaders != nil { config.LogTraceHeaders = *req.LogTraceHeaders } else { config.LogTraceHeaders = true }
	if req.PropagateContext != nil { config.PropagateContext = *req.PropagateContext } else { config.PropagateContext = true }
	if req.CaptureRequestBody != nil { config.CaptureRequestBody = *req.CaptureRequestBody }
	if req.CaptureResponseBody != nil { config.CaptureResponseBody = *req.CaptureResponseBody }

	createdConfig, err := h.tracingConfigService.CreateConfig(workspaceID, userID, config)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusCreated, createdConfig)
}

// ... (Update, Delete, and Toggle methods following the pointer logic)