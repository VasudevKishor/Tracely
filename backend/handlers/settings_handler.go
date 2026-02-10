/*
Package handlers contains HTTP request handlers for the API endpoints.
This file implements the SettingsHandler, which manages user settings-related routes
such as retrieving and updating user preferences (theme, notifications, language, etc.).
It interfaces with the SettingsService to handle CRUD operations on user settings,
ensuring proper authentication via middlewares and JSON response formatting.
*/
package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// SettingsHandler holds the SettingsService instance to handle user settings logic
type SettingsHandler struct {
	settingsService *services.SettingsService
}

// NewSettingsHandler creates a new instance of SettingsHandler
func NewSettingsHandler(settingsService *services.SettingsService) *SettingsHandler {
	return &SettingsHandler{settingsService: settingsService}
}

// GetSettings handles GET requests to retrieve the current user's setting
func (h *SettingsHandler) GetSettings(c *gin.Context) {
	// Extract the user ID from context (set by AuthMiddleware)
	userID, _ := middlewares.GetUserID(c)
	// Retrieve user settings from the service
	settings, err := h.settingsService.GetSettings(userID)
	if err != nil {
		// Return 500 if there is an error retrieving settings
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	// Return the settings as JSON with HTTP 200
	c.JSON(http.StatusOK, settings)
}

// UpdateSettings handles PATCH/PUT requests to update the current user's settings
func (h *SettingsHandler) UpdateSettings(c *gin.Context) {
	// Extract the user ID from context
	userID, _ := middlewares.GetUserID(c)

	// Bind incoming JSON payload to a map for updates
	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		// Return 400 if JSON binding fails
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Update user settings via the service
	settings, err := h.settingsService.UpdateSettings(userID, updates)
	if err != nil {
		// Return 500 if there is an error updating settings
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	// Return the updated settings as JSON with HTTP 200
	c.JSON(http.StatusOK, settings)
}
