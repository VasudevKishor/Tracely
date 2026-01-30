#!/bin/bash

# Settings Handler
cat > /home/claude/tracely-backend/handlers/settings_handler.go << 'EOF'
package handlers

import (
	"net/http"
	"tracely-backend/middlewares"
	"tracely-backend/services"

	"github.com/gin-gonic/gin"
)

type SettingsHandler struct {
	settingsService *services.SettingsService
}

func NewSettingsHandler(settingsService *services.SettingsService) *SettingsHandler {
	return &SettingsHandler{settingsService: settingsService}
}

func (h *SettingsHandler) GetSettings(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	settings, err := h.settingsService.GetSettings(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}

func (h *SettingsHandler) UpdateSettings(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	settings, err := h.settingsService.UpdateSettings(userID, updates)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}
EOF

# Replay Handler
cat > /home/claude/tracely-backend/handlers/replay_handler.go << 'EOF'
package handlers

import (
	"net/http"
	"tracely-backend/middlewares"
	"tracely-backend/services"

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
EOF

# Mock Handler
cat > /home/claude/tracely-backend/handlers/mock_handler.go << 'EOF'
package handlers

import (
	"net/http"
	"tracely-backend/middlewares"
	"tracely-backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type MockHandler struct {
	mockService *services.MockService
}

func NewMockHandler(mockService *services.MockService) *MockHandler {
	return &MockHandler{mockService: mockService}
}

type GenerateMockRequest struct {
	TraceID string `json:"trace_id" binding:"required"`
}

func (h *MockHandler) GenerateFromTrace(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	var req GenerateMockRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	traceID, err := uuid.Parse(req.TraceID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid trace ID"})
		return
	}

	mocks, err := h.mockService.GenerateFromTrace(workspaceID, userID, traceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"mocks": mocks})
}

func (h *MockHandler) GetAll(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	mocks, err := h.mockService.GetAll(workspaceID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"mocks": mocks})
}

func (h *MockHandler) Update(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	mockID, err := uuid.Parse(c.Param("mock_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid mock ID"})
		return
	}

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	mock, err := h.mockService.Update(mockID, userID, updates)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, mock)
}

func (h *MockHandler) Delete(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	mockID, err := uuid.Parse(c.Param("mock_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid mock ID"})
		return
	}

	if err := h.mockService.Delete(mockID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
EOF

echo "All handlers created successfully (3/3)"
