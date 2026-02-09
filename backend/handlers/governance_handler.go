package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GovernanceHandler manages workspace policies and compliance rules.
type GovernanceHandler struct {
	governanceService *services.GovernanceService
}

// NewGovernanceHandler creates a new instance of GovernanceHandler.
func NewGovernanceHandler(governanceService *services.GovernanceService) *GovernanceHandler {
	return &GovernanceHandler{governanceService: governanceService}
}

type CreatePolicyRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
	Rules       string `json:"rules" binding:"required"`
	Enabled     bool   `json:"enabled"`
}

// GetPolicies retrieves all policies defined for a specific workspace.
func (h *GovernanceHandler) GetPolicies(c *gin.Context) {
	// Identify the user and target workspace from the request
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	policies, err := h.governanceService.GetPolicies(workspaceID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"policies": policies})
}

// CreatePolicy adds a new compliance policy to a workspace.
func (h *GovernanceHandler) CreatePolicy(c *gin.Context) {
	// Identify the user and target workspace from the request
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	var req CreatePolicyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	policy, err := h.governanceService.CreatePolicy(workspaceID, userID, req.Name, req.Description, req.Rules, req.Enabled)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, policy)
}

// UpdatePolicy modifies an existing policy's configuration or status.
func (h *GovernanceHandler) UpdatePolicy(c *gin.Context) {
	// Identify the user and specific policy to update
	userID, _ := middlewares.GetUserID(c)
	policyID, err := uuid.Parse(c.Param("policy_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid policy ID"})
		return
	}

	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	policy, err := h.governanceService.UpdatePolicy(policyID, userID, updates)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, policy)
}

// DeletePolicy removes a compliance policy from the workspace.
func (h *GovernanceHandler) DeletePolicy(c *gin.Context) {
	// Identify the user and target policy
	userID, _ := middlewares.GetUserID(c)
	policyID, err := uuid.Parse(c.Param("policy_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid policy ID"})
		return
	}

	if err := h.governanceService.DeletePolicy(policyID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}
