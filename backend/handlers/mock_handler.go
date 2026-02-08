package handlers

import (
	"net/http"
	"backend/middlewares"
	"backend/services"

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
