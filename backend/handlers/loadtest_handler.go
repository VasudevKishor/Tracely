package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type LoadTestHandler struct {
	loadTestService *services.LoadTestService
}

func NewLoadTestHandler(loadTestService *services.LoadTestService) *LoadTestHandler {
	return &LoadTestHandler{loadTestService: loadTestService}
}

type CreateLoadTestRequest struct {
	Name          string `json:"name" binding:"required"`
	RequestID     string `json:"request_id" binding:"required"`
	Concurrency   int    `json:"concurrency" binding:"required"`
	TotalRequests int    `json:"total_requests" binding:"required"`
	RampUpSeconds int    `json:"ramp_up_seconds"`
}

func (h *LoadTestHandler) Create(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))

	var req CreateLoadTestRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	requestID, _ := uuid.Parse(req.RequestID)

	loadTest, err := h.loadTestService.CreateLoadTest(
		workspaceID, requestID, userID, req.Name,
		req.Concurrency, req.TotalRequests, req.RampUpSeconds,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, loadTest)
}
