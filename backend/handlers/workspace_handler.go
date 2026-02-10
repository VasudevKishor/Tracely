/*
Package handlers contains HTTP request handlers for the API endpoints.
This file implements the WorkspaceHandler, which manages workspace-related routes
such as creating, retrieving, updating, and deleting workspaces. It enforces
Role-Based Access Control (RBAC) by checking user permissions via middlewares
and the WorkspaceService, ensuring users can only access workspaces they own or are members of.
*/
package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// WorkspaceHandler holds the WorkspaceService to handle business logic for workspaces
type WorkspaceHandler struct {
	workspaceService *services.WorkspaceService
}

// NewWorkspaceHandler creates a new instance of WorkspaceHandler
func NewWorkspaceHandler(workspaceService *services.WorkspaceService) *WorkspaceHandler {
	return &WorkspaceHandler{workspaceService: workspaceService}
}

// CreateWorkspaceRequest defines the payload for creating or updating a workspace
type CreateWorkspaceRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
}

// Create handles POST /workspaces
// It creates a new workspace for the authenticated user
func (h *WorkspaceHandler) Create(c *gin.Context) {
	// Get the authenticated user's ID from the context
	userID, err := middlewares.GetUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	// Bind JSON payload to struct
	var req CreateWorkspaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Call service to create workspace
	workspace, err := h.workspaceService.Create(req.Name, req.Description, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	// Return created workspace with HTTP 201
	c.JSON(http.StatusCreated, workspace)
}

// GetAll handles GET /workspaces
// It retrieves all workspaces where the user is a member or owner
func (h *WorkspaceHandler) GetAll(c *gin.Context) {
	userID, err := middlewares.GetUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	workspaces, err := h.workspaceService.GetAll(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	// Return all workspaces as JSON
	c.JSON(http.StatusOK, gin.H{"workspaces": workspaces})
}

// GetByID handles GET /workspaces/:workspace_id
// It retrieves a specific workspace by its ID, ensuring the user has access
func (h *WorkspaceHandler) GetByID(c *gin.Context) {
	userID, err := middlewares.GetUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	// Parse workspace_id from URL
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}
	// Fetch workspace via service
	workspace, err := h.workspaceService.GetByID(workspaceID, userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, workspace)
}

// Update handles PATCH/PUT /workspaces/:workspace_id
// It updates a workspace's name or description for authorized users

func (h *WorkspaceHandler) Update(c *gin.Context) {
	userID, err := middlewares.GetUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	var req CreateWorkspaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Update workspace via service
	workspace, err := h.workspaceService.Update(workspaceID, userID, req.Name, req.Description)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, workspace)
}

// Delete handles DELETE /workspaces/:workspace_id
// It deletes a workspace if the user is authorized (owner or admin)

func (h *WorkspaceHandler) Delete(c *gin.Context) {
	userID, err := middlewares.GetUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}
	// Call service to delete workspace
	if err := h.workspaceService.Delete(workspaceID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	// Return HTTP 204 No Content on successful deletion
	c.Status(http.StatusNoContent)
}
