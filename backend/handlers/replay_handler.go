package handlers

import (
	"net/http"
	"backend/middlewares"
	"backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ReplayHandler struct {
	replayService *services.ReplayService
}

func NewReplayHandler(replayService *services.ReplayService) *ReplayHandler {
	return &ReplayHandler{replayService: replayService}
}

type CreateReplayRequest struct {
	Name              string                 `json:"name" binding:"required"`
	Description       string                 `json:"description"`
	SourceTraceID     string                 `json:"source_trace_id" binding:"required"`
	TargetEnvironment string                 `json:"target_environment" binding:"required"`
	Configuration     map[string]interface{} `json:"configuration"`
}

func (h *ReplayHandler) GetAll(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}
	replays, err := h.replayService.GetAll(workspaceID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{"replays": replays})
}

func (h *ReplayHandler) CreateReplay(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	var req CreateReplayRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	sourceTraceID, err := uuid.Parse(req.SourceTraceID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid trace ID"})
		return
	}

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

func (h *ReplayHandler) ExecuteReplay(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	replayID, err := uuid.Parse(c.Param("replay_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid replay ID"})
		return
	}

	execution, err := h.replayService.ExecuteReplay(replayID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, execution)
}

func (h *ReplayHandler) GetResults(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	replayID, err := uuid.Parse(c.Param("replay_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid replay ID"})
		return
	}

	results, err := h.replayService.GetResults(replayID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"results": results})
}
