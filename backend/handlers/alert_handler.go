package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type AlertHandler struct {
	alertingService *services.AlertingService
}

func NewAlertHandler(alertingService *services.AlertingService) *AlertHandler {
	return &AlertHandler{alertingService: alertingService}
}

type CreateAlertRuleRequest struct {
	Name       string  `json:"name" binding:"required"`
	Condition  string  `json:"condition" binding:"required"`
	Threshold  float64 `json:"threshold" binding:"required"`
	TimeWindow int     `json:"time_window" binding:"required"`
	Channel    string  `json:"channel" binding:"required"`
}

func (h *AlertHandler) CreateRule(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))

	var req CreateAlertRuleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	rule, err := h.alertingService.CreateRule(
		userID, workspaceID, req.Name, req.Condition,
		req.Threshold, req.TimeWindow, req.Channel,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, rule)
}

func (h *AlertHandler) GetActiveAlerts(c *gin.Context) {
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))

	alerts, err := h.alertingService.GetActiveAlerts(workspaceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"alerts": alerts})
}

func (h *AlertHandler) AcknowledgeAlert(c *gin.Context) {
	alertID, _ := uuid.Parse(c.Param("alert_id"))

	if err := h.alertingService.AcknowledgeAlert(alertID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Alert acknowledged"})
}
