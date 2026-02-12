/*
Package handlers contains HTTP request handlers for the API endpoints.
This file implements the ReplayHandler, which manages replay-related routes
such as creating a replay, fetching replay details, executing a replay, and
retrieving replay results. It ensures proper authentication via middlewares
and delegates the business logic to the ReplayService.
*/
package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ReplayHandler handles HTTP requests related to replays.
type ReplayHandler struct {
	replayService *services.ReplayService
}

// NewReplayHandler creates a new instance of ReplayHandler.
func NewReplayHandler(replayService *services.ReplayService) *ReplayHandler {
	return &ReplayHandler{replayService: replayService}
}

// CreateReplayRequest represents the payload for creating a replay.
type CreateReplayRequest struct {
	Name              string                 `json:"name" binding:"required"`               // Name of the replay
	Description       string                 `json:"description"`                           // Optional description
	SourceTraceID     string                 `json:"source_trace_id" binding:"required"`    // Trace ID to replay
	TargetEnvironment string                 `json:"target_environment" binding:"required"` // Target environment for replay
	Configuration     map[string]interface{} `json:"configuration"`                         // Optional replay configuration
}

// CreateReplay handles POST requests to create a new replay within a workspace.
func (h *ReplayHandler) CreateReplay(c *gin.Context) {
	// Get the authenticated user's ID
	userID, _ := middlewares.GetUserID(c)

	// Parse workspace ID from URL parameter
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	// Bind JSON request payload
	var req CreateReplayRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse the source trace ID
	sourceTraceID, err := uuid.Parse(req.SourceTraceID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid trace ID"})
		return
	}

	// Call service to create the replay
	replay, err := h.replayService.CreateReplay(
		workspaceID,
		userID,
		req.Name,
		req.Description,
		sourceTraceID,
		req.TargetEnvironment,
		req.Configuration,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, replay)
}

// GetReplay handles GET requests to fetch a single replay by its ID.
func (h *ReplayHandler) GetReplay(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	replayID, err := uuid.Parse(c.Param("replay_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid replay ID"})
		return
	}

	replay, err := h.replayService.GetReplay(replayID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, replay)
}

// ExecuteReplay handles POST requests to execute a previously created replay.
func (h *ReplayHandler) ExecuteReplay(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	replayID, err := uuid.Parse(c.Param("replay_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid replay ID"})
		return
	}

	// Call service to execute the replay
	execution, err := h.replayService.ExecuteReplay(replayID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, execution)
}

// GetResults handles GET requests to fetch the results of a replay.
func (h *ReplayHandler) GetResults(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	replayID, err := uuid.Parse(c.Param("replay_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid replay ID"})
		return
	}

	// Call service to get replay results
	results, err := h.replayService.GetResults(replayID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"results": results})
}
