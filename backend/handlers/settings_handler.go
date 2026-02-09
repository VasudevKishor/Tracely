package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// SettingsHandler provides HTTP endpoints for managing user preferences and settings.
type SettingsHandler struct {
	settingsService *services.SettingsService
}

// NewSettingsHandler creates a new instance of SettingsHandler with the given settings service.
func NewSettingsHandler(settingsService *services.SettingsService) *SettingsHandler {
	return &SettingsHandler{settingsService: settingsService}
}

// GetSettings retrieves the configuration and preferences for the currently authenticated user.
func (h *SettingsHandler) GetSettings(c *gin.Context) {
	// Identify the user from the authentication token
	userID, _ := middlewares.GetUserID(c)

	settings, err := h.settingsService.GetSettings(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}

// UpdateSettings modifies user preferences based on the provided JSON body.
func (h *SettingsHandler) UpdateSettings(c *gin.Context) {
	// Identify the user from the authentication token
	userID, _ := middlewares.GetUserID(c)

	var updates map[string]interface{}
	// Bind the flexible JSON map to capture dynamic settings updates
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	settings, err := h.settingsService.UpdateSettings(userID, updates)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}
