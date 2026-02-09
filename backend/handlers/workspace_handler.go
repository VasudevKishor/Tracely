package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// WorkspaceHandler handles HTTP requests for workspace management.
type WorkspaceHandler struct {
	workspaceService *services.WorkspaceService
}

// NewWorkspaceHandler creates a new instance of WorkspaceHandler.
func NewWorkspaceHandler(workspaceService *services.WorkspaceService) *WorkspaceHandler {
	return &WorkspaceHandler{workspaceService: workspaceService}
}

type CreateWorkspaceRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
}

// Create handles the creation of a new workspace.
func (h *WorkspaceHandler) Create(c *gin.Context) {
	// Identify the user from the authentication token
	userID, err := middlewares.GetUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	var req CreateWorkspaceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	workspace, err := h.workspaceService.Create(req.Name, req.Description, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, workspace)
}

// GetAll retrieves all workspaces associated with the authenticated user.
func (h *WorkspaceHandler) GetAll(c *gin.Context) {
	// Identify the user from the authentication token
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

	c.JSON(http.StatusOK, gin.H{"workspaces": workspaces})
}

// GetByID retrieves a specific workspace by its ID.
func (h *WorkspaceHandler) GetByID(c *gin.Context) {
	// Identify the user from the authentication token
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

	workspace, err := h.workspaceService.GetByID(workspaceID, userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, workspace)
}

// Update modifies the details of an existing workspace.
func (h *WorkspaceHandler) Update(c *gin.Context) {
	// Identify the user from the authentication token
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

	workspace, err := h.workspaceService.Update(workspaceID, userID, req.Name, req.Description)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, workspace)
}

// Delete removes a workspace by its ID.
func (h *WorkspaceHandler) Delete(c *gin.Context) {
	// Identify the user from the authentication token
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

	if err := h.workspaceService.Delete(workspaceID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
