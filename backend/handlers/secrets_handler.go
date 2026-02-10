package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// SecretsHandler handles HTTP requests related to secret management within a workspace, including creation, retrieval, and rotation.
type SecretsHandler struct {
	secretsService *services.SecretsService
}

func NewSecretsHandler(secretsService *services.SecretsService) *SecretsHandler {
	return &SecretsHandler{secretsService: secretsService}
}

// CreateSecretRequest represents the request payload for creating a new secret.
type CreateSecretRequest struct {
	Key         string `json:"key" binding:"required"`
	Value       string `json:"value" binding:"required"`
	Description string `json:"description"`
}

// Create stores a new secret in the workspace for the authenticated user.
// It validates the request payload and delegates storage to the service layer.
func (h *SecretsHandler) Create(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, _ := uuid.Parse(c.Param("workspace_id"))

	// Bind and validate request body.
	var req CreateSecretRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Create secret via service.
	secret, err := h.secretsService.CreateSecret(
		workspaceID, userID, req.Key, req.Value, req.Description,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, secret)
}

// GetValue retrieves the value of a specific secret in a workspace.
// Returns 404 if the secret is not found.
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

// RotateSecretRequest represents the request payload for rotating an existing secret.
type RotateSecretRequest struct {
	NewValue string `json:"new_value" binding:"required"`
}

// Rotate updates the value of an existing secret in the workspace.
// Only the new value is required; the service layer handles rotation logic.
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
