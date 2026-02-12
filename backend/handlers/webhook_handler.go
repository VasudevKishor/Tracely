package handlers

import (
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type WebhookHandler struct {
	webhookService *services.WebhookService
}

func NewWebhookHandler(s *services.WebhookService) *WebhookHandler {
	return &WebhookHandler{webhookService: s}
}

// CreateWebhookRequest defines the payload for creating a new webhook subscription
type CreateWebhookRequest struct {
	Name   string   `json:"name" binding:"required"`
	URL    string   `json:"url" binding:"required,url"`
	Secret string   `json:"secret"`
	Events []string `json:"events" binding:"required,min=1"`
}

// Create handles POST /workspaces/:workspace_id/webhooks
func (h *WebhookHandler) Create(c *gin.Context) {
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	var req CreateWebhookRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	webhook, err := h.webhookService.CreateWebhook(
		workspaceID,
		req.Name,
		req.URL,
		req.Secret,
		req.Events,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create webhook"})
		return
	}

	c.JSON(http.StatusCreated, webhook)
}

// TriggerEventRequest defines the payload for manually triggering a webhook event
type TriggerEventRequest struct {
	EventType string                 `json:"event_type" binding:"required"`
	Payload   map[string]interface{} `json:"payload" binding:"required"`
}

// Trigger handles POST /workspaces/:workspace_id/webhooks/trigger
func (h *WebhookHandler) Trigger(c *gin.Context) {
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	var req TriggerEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.webhookService.TriggerWebhook(workspaceID, req.EventType, req.Payload)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to trigger webhooks"})
		return
	}

	c.JSON(http.StatusAccepted, gin.H{"message": "Webhook delivery initiated"})
}
