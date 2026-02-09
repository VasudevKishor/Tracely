package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AlertHandler handles HTTP requests related to alerting rules and active alerts.
type AlertHandler struct {
	alertingService *services.AlertingService
}

// NewAlertHandler creates a new instance of AlertHandler with the given alerting service.
func NewAlertHandler(alertingService *services.AlertingService) *AlertHandler {
	return &AlertHandler{alertingService: alertingService}
}

// CreateAlertRuleRequest defines the payload for creating a new alert rule.
type CreateAlertRuleRequest struct {
	Name       string  `json:"name" binding:"required"`
	Condition  string  `json:"condition" binding:"required"`
	Threshold  float64 `json:"threshold" binding:"required"`
	TimeWindow int     `json:"time_window" binding:"required"`
	Channel    string  `json:"channel" binding:"required"`
}

// CreateRule handles the creation of a new alert rule for a specific workspace.
// It expects a JSON payload matching CreateAlertRuleRequest.
func (h *AlertHandler) CreateRule(c *gin.Context) {
	// Extract user identity from the context (populated by authentication middleware)
	userID, _ := middlewares.GetUserID(c)
	// Parse the workspace UUID from the URL parameter
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))

	var req CreateAlertRuleRequest
	// Validate and bind the incoming JSON payload to our request struct
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

// GetActiveAlerts retrieves all active alerts for a specific workspace.
func (h *AlertHandler) GetActiveAlerts(c *gin.Context) {
	// Parse the workspace UUID from the URL parameter
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))

	// Fetch active alerts from the service layer
	alerts, err := h.alertingService.GetActiveAlerts(workspaceID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"alerts": alerts})
}

// AcknowledgeAlert handles the acknowledgement of an alert by its ID.
func (h *AlertHandler) AcknowledgeAlert(c *gin.Context) {
	// Parse the specific alert ID to be acknowledged
	alertID, _ := uuid.Parse(c.Param("alert_id"))

	// Mark the alert as acknowledged in the service
	if err := h.alertingService.AcknowledgeAlert(alertID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Alert acknowledged"})
}
