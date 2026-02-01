package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

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
