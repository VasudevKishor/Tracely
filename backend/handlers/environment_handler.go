package handlers

import (
	"backend/middlewares" // Custom middlewares to extract user info
	"backend/services"    // Services layer for business logic
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// EnvironmentHandler handles HTTP requests related to environments
type EnvironmentHandler struct {
	environmentService *services.EnvironmentService
}

// Constructor for EnvironmentHandler
func NewEnvironmentHandler(environmentService *services.EnvironmentService) *EnvironmentHandler {
	return &EnvironmentHandler{environmentService: environmentService}
}

// Request structs for creating and updating environments and variables

// CreateEnvironmentRequest represents the payload for creating a new environment
type CreateEnvironmentRequest struct {
	Name        string `json:"name" binding:"required"` // Environment name (required)
	Type        string `json:"type" binding:"required"` // Environment type: global, development, staging, production (required)
	Description string `json:"description"`             // Optional description
	IsActive    bool   `json:"is_active"`               // Optional active flag
}

// UpdateEnvironmentRequest represents the payload for updating an existing environment
type UpdateEnvironmentRequest struct {
	Name        string `json:"name"`        // New name
	Type        string `json:"type"`        // New type
	Description string `json:"description"` // New description
	IsActive    *bool  `json:"is_active"`   // Pointer to allow optional boolean
}

// CreateEnvironmentVariableRequest represents the payload for adding/updating environment variables
type CreateEnvironmentVariableRequest struct {
	Key         string `json:"key" binding:"required"`   // Variable key (required)
	Value       string `json:"value" binding:"required"` // Variable value (required)
	Type        string `json:"type"`                     // Type: string, number, boolean, json
	Description string `json:"description"`              // Optional description
}

// ----------------------------------------
// Handlers for Environment CRUD operations
// ----------------------------------------

// GetEnvironments returns all environments for a workspace
func (h *EnvironmentHandler) GetEnvironments(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)                   // Get user ID from context (middleware)
	workspaceID, err := uuid.Parse(c.Param("workspace_id")) // Parse workspace UUID from URL
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	// Fetch all environments for this workspace and user
	environments, err := h.environmentService.GetAll(workspaceID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return environments as JSON
	c.JSON(http.StatusOK, gin.H{
		"environments": environments,
	})
}

// CreateEnvironment creates a new environment
func (h *EnvironmentHandler) CreateEnvironment(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	var req CreateEnvironmentRequest
	// Bind and validate JSON payload
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Validate environment type
	validTypes := map[string]bool{
		"global":      true,
		"development": true,
		"staging":     true,
		"production":  true,
	}
	if !validTypes[req.Type] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid environment type"})
		return
	}

	// Call service layer to create environment
	environment, err := h.environmentService.Create(workspaceID, req.Name, req.Type, req.Description, req.IsActive, userID)
	if err != nil {
		status := http.StatusInternalServerError
		// Handle duplicate name error
		if err.Error() == "duplicate key value violates unique constraint" {
			status = http.StatusConflict
		}
		c.JSON(status, gin.H{"error": err.Error()})
		return
	}

	// Return newly created environment
	c.JSON(http.StatusCreated, gin.H{
		"environment": environment,
	})
}

// UpdateEnvironment updates an existing environment
func (h *EnvironmentHandler) UpdateEnvironment(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	environmentID, err := uuid.Parse(c.Param("environment_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid environment ID"})
		return
	}

	var req UpdateEnvironmentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Prepare updates map for service layer
	updates := make(map[string]interface{})
	if req.Name != "" {
		updates["name"] = req.Name
	}
	if req.Type != "" {
		// Validate type
		validTypes := map[string]bool{
			"global":      true,
			"development": true,
			"staging":     true,
			"production":  true,
		}
		if !validTypes[req.Type] {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid environment type"})
			return
		}
		updates["type"] = req.Type
	}
	if req.Description != "" {
		updates["description"] = req.Description
	}
	if req.IsActive != nil {
		updates["is_active"] = *req.IsActive
	}

	// Call service layer to apply updates
	environment, err := h.environmentService.Update(workspaceID, environmentID, userID, updates)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"environment": environment,
	})
}

// DeleteEnvironment deletes an environment
func (h *EnvironmentHandler) DeleteEnvironment(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	environmentID, err := uuid.Parse(c.Param("environment_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid environment ID"})
		return
	}

	// Call service layer to delete environment
	if err := h.environmentService.Delete(workspaceID, environmentID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Environment deleted successfully",
	})
}

// ----------------------------------------
// Handlers for Environment Variables CRUD
// ----------------------------------------

// GetEnvironmentVariables returns variables and secrets for an environment
func (h *EnvironmentHandler) GetEnvironmentVariables(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	environmentID, err := uuid.Parse(c.Param("environment_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid environment ID"})
		return
	}

	// Get environment details
	environment, err := h.environmentService.GetByID(workspaceID, environmentID, userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	// Get variables
	variables, err := h.environmentService.GetVariables(workspaceID, environmentID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Return environment with variables and secrets
	c.JSON(http.StatusOK, gin.H{
		"environment": gin.H{
			"id":          environment.ID,
			"name":        environment.Name,
			"type":        environment.Type,
			"description": environment.Description,
			"is_active":   environment.IsActive,
			"created_at":  environment.CreatedAt,
			"updated_at":  environment.UpdatedAt,
		},
		"variables": variables,
		"secrets":   environment.Secrets,
	})
}

// AddEnvironmentVariable adds a new variable to an environment
func (h *EnvironmentHandler) AddEnvironmentVariable(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	environmentID, err := uuid.Parse(c.Param("environment_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid environment ID"})
		return
	}

	var req CreateEnvironmentVariableRequest
	// Bind and validate JSON
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Call service layer to add variable
	variable, err := h.environmentService.AddVariable(workspaceID, environmentID, req.Key, req.Value, req.Type, req.Description, userID)
	if err != nil {
		status := http.StatusInternalServerError
		// Handle duplicate key error
		if err.Error() == "duplicate key value violates unique constraint" {
			status = http.StatusConflict
		}
		c.JSON(status, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"variable": variable,
	})
}

// UpdateEnvironmentVariable updates an existing variable
func (h *EnvironmentHandler) UpdateEnvironmentVariable(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	environmentID, err := uuid.Parse(c.Param("environment_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid environment ID"})
		return
	}

	variableID, err := uuid.Parse(c.Param("variable_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid variable ID"})
		return
	}

	var req CreateEnvironmentVariableRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Prepare updates map
	updates := make(map[string]interface{})
	if req.Key != "" {
		updates["key"] = req.Key
	}
	if req.Value != "" {
		updates["value"] = req.Value
	}
	if req.Type != "" {
		updates["type"] = req.Type
	}
	if req.Description != "" {
		updates["description"] = req.Description
	}

	// Call service layer to update variable
	variable, err := h.environmentService.UpdateVariable(workspaceID, environmentID, variableID, userID, updates)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"variable": variable,
	})
}

// DeleteEnvironmentVariable deletes a variable from an environment
func (h *EnvironmentHandler) DeleteEnvironmentVariable(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	environmentID, err := uuid.Parse(c.Param("environment_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid environment ID"})
		return
	}

	variableID, err := uuid.Parse(c.Param("variable_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid variable ID"})
		return
	}

	// Call service layer to delete variable
	if err := h.environmentService.DeleteVariable(workspaceID, environmentID, variableID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Variable deleted successfully",
	})
}
