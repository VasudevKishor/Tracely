package handlers

import (
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// WaterfallHandler handles HTTP requests for generating trace waterfall visualizations.
type WaterfallHandler struct {
	waterfallService *services.WaterfallService
}

// NewWaterfallHandler creates a new instance of WaterfallHandler.
func NewWaterfallHandler(s *services.WaterfallService) *WaterfallHandler {
	return &WaterfallHandler{waterfallService: s}
}

// GetWaterfall returns a hierarchical tree of spans for a specific trace.
// GET /api/v1/traces/:trace_id/waterfall
func (h *WaterfallHandler) GetWaterfall(c *gin.Context) {
	// 1. Parse and validate the trace_id from the URL
	traceIDStr := c.Param("trace_id")
	traceID, err := uuid.Parse(traceIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid trace ID format",
		})
		return
	}

	// 2. Call the service to build the tree
	// The service performs the recursion and sorting internally
	waterfall, err := h.waterfallService.GenerateWaterfall(traceID)
	if err != nil {
		// If no root span is found or DB error occurs
		c.JSON(http.StatusNotFound, gin.H{
			"error": "Could not generate waterfall: " + err.Error(),
		})
		return
	}

	// 3. Return the hierarchical WaterfallNode
	// Gin will automatically serialize the nested 'Children' slices
	c.JSON(http.StatusOK, waterfall)
}
