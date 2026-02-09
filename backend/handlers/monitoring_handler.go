package handlers

import (
	"net/http"
	"backend/middlewares"
	"backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type MonitoringHandler struct {
	monitoringService *services.MonitoringService
}

func NewMonitoringHandler(monitoringService *services.MonitoringService) *MonitoringHandler {
	return &MonitoringHandler{monitoringService: monitoringService}
}

func (h *MonitoringHandler) GetDashboard(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	timeRange := c.DefaultQuery("time_range", "last_hour")

	dashboard, err := h.monitoringService.GetDashboard(workspaceID, userID, timeRange)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, dashboard)
}

func (h *MonitoringHandler) GetMetrics(c *gin.Context) {
	// Placeholder for metrics endpoint
	c.JSON(http.StatusOK, gin.H{
		"message": "Metrics endpoint - to be implemented",
	})
}

func (h *MonitoringHandler) GetTopology(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	topology, err := h.monitoringService.GetTopology(workspaceID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, topology)
}
