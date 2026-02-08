#!/bin/bash

# Alert Handler
cat > handlers/alert_handler.go << 'EOF'
package handlers

import (
	"net/http"
	"tracely-backend/middlewares"
	"tracely-backend/services"

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
	Name      string  `json:"name" binding:"required"`
	Condition string  `json:"condition" binding:"required"`
	Threshold float64 `json:"threshold" binding:"required"`
	TimeWindow int    `json:"time_window" binding:"required"`
	Channel   string  `json:"channel" binding:"required"`
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
		workspaceID, req.Name, req.Condition,
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
EOF

# Secrets Handler
cat > handlers/secrets_handler.go << 'EOF'
package handlers

import (
	"net/http"
	"tracely-backend/middlewares"
	"tracely-backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SecretsHandler struct {
	secretsService *services.SecretsService
}

func NewSecretsHandler(secretsService *services.SecretsService) *SecretsHandler {
	return &SecretsHandler{secretsService: secretsService}
}

type CreateSecretRequest struct {
	Key         string `json:"key" binding:"required"`
	Value       string `json:"value" binding:"required"`
	Description string `json:"description"`
}

func (h *SecretsHandler) Create(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))

	var req CreateSecretRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	secret, err := h.secretsService.CreateSecret(
		workspaceID, userID, req.Key, req.Value, req.Description,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, secret)
}

func (h *SecretsHandler) GetValue(c *gin.Context) {
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))
	secretID, _ := uuid.Parse(c.Param("secret_id"))

	value, err := h.secretsService.GetSecret(secretID, workspaceID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"value": value})
}

type RotateSecretRequest struct {
	NewValue string `json:"new_value" binding:"required"`
}

func (h *SecretsHandler) Rotate(c *gin.Context) {
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))
	secretID, _ := uuid.Parse(c.Param("secret_id"))

	var req RotateSecretRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.secretsService.RotateSecret(secretID, workspaceID, req.NewValue); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Secret rotated successfully"})
}
EOF

# Workflow Handler
cat > handlers/workflow_handler.go << 'EOF'
package handlers

import (
	"net/http"
	"tracely-backend/middlewares"
	"tracely-backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type WorkflowHandler struct {
	workflowService *services.WorkflowService
}

func NewWorkflowHandler(workflowService *services.WorkflowService) *WorkflowHandler {
	return &WorkflowHandler{workflowService: workflowService}
}

type CreateWorkflowRequest struct {
	Name        string                      `json:"name" binding:"required"`
	Description string                      `json:"description"`
	Steps       []services.WorkflowStep     `json:"steps" binding:"required"`
}

func (h *WorkflowHandler) Create(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))

	var req CreateWorkflowRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	workflow, err := h.workflowService.CreateWorkflow(
		workspaceID, userID, req.Name, req.Description, req.Steps,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, workflow)
}

func (h *WorkflowHandler) Execute(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workflowID, _ := uuid.Parse(c.Param("workflow_id"))

	execution, err := h.workflowService.ExecuteWorkflow(workflowID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, execution)
}
EOF

# Load Test Handler
cat > handlers/loadtest_handler.go << 'EOF'
package handlers

import (
	"net/http"
	"tracely-backend/middlewares"
	"tracely-backend/services"

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
EOF

echo "New handlers created successfully!"
