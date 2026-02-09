package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// SettingsHandler handles HTTP requests related to user settings.
type SettingsHandler struct {
	settingsService *services.SettingsService
}

// NewSettingsHandler creates a new instance of SettingsHandler.
func NewSettingsHandler(settingsService *services.SettingsService) *SettingsHandler {
	return &SettingsHandler{settingsService: settingsService}
}

// GetSettings retrieves the settings for the authenticated user.
func (h *SettingsHandler) GetSettings(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	settings, err := h.settingsService.GetSettings(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, settings)
}

// UpdateSettings updates the settings for the authenticated user.
func (h *SettingsHandler) UpdateSettings(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)

	var updates map[string]interface{}
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
