package handlers

import (
	"net/http"
	"backend/middlewares"
	"backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// MockHandler handles HTTP requests related to mock generation and management within a workspace context.
type MockHandler struct {
	mockService *services.MockService
}

// NewMockHandler creates a new MockHandler with the given service dependency.
func NewMockHandler(mockService *services.MockService) *MockHandler {
	return &MockHandler{mockService: mockService}
}

// GenerateMockRequest represents the request body used to generate mocks from an existing trace.
type GenerateMockRequest struct {
	TraceID string `json:"trace_id" binding:"required"`
}

// GenerateFromTrace generates mock definitions based on a trace.
// It validates workspace and trace identifiers, ensures the request is scoped to the authenticated user, and delegates mock generation to the service layer.
func (h *MockHandler) GenerateFromTrace(c *gin.Context) {
	// Retrieve authenticated user ID from context.
	userID, _ := middlewares.GetUserID(c)

	// Parse and validate workspace ID from URL parameters.
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	// Bind and validate request payload.
	var req GenerateMockRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Parse and validate trace ID.
	traceID, err := uuid.Parse(req.TraceID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid trace ID"})
		return
	}

	// Generate mocks from trace via service layer.
	mocks, err := h.mockService.GenerateFromTrace(workspaceID, userID, traceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return created mock definitions.
	c.JSON(http.StatusCreated, gin.H{"mocks": mocks})
}

// GetAll retrieves all mocks belonging to the authenticated user within the specified workspace.
func (h *MockHandler) GetAll(c *gin.Context) {
	// Retrieve authenticated user ID.
	userID, _ := middlewares.GetUserID(c)

	// Parse and validate workspace ID.
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	// Fetch all mocks from the service layer.
	mocks, err := h.mockService.GetAll(workspaceID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"mocks": mocks})
}

// Update updates an existing mock with the provided fields.
// Only the fields present in the request body are modified.
func (h *MockHandler) Update(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	mockID, err := uuid.Parse(c.Param("mock_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid mock ID"})
		return
	}

	// Bind partial update payload.
	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Apply updates via service layer.
	mock, err := h.mockService.Update(mockID, userID, updates)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, mock)
}

// Delete removes a mock identified by its ID.
// The operation is scoped to the authenticated user.
func (h *MockHandler) Delete(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	mockID, err := uuid.Parse(c.Param("mock_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid mock ID"})
		return
	}

	// Delete mock via service layer.
	if err := h.mockService.Delete(mockID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
