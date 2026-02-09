package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GovernanceHandler handles HTTP requests related to governance policies.
type GovernanceHandler struct {
	governanceService *services.GovernanceService
}

// NewGovernanceHandler creates a new instance of GovernanceHandler.
func NewGovernanceHandler(governanceService *services.GovernanceService) *GovernanceHandler {
	return &GovernanceHandler{governanceService: governanceService}
}

// CreatePolicyRequest defines the payload for creating a new governance policy.
type CreatePolicyRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
	Rules       string `json:"rules" binding:"required"`
	Enabled     bool   `json:"enabled"`
}

// GetPolicies retrieves all policies for a given workspace.
func (h *GovernanceHandler) GetPolicies(c *gin.Context) {
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

// CreatePolicy creates a new governance policy in a workspace.
func (h *GovernanceHandler) CreatePolicy(c *gin.Context) {
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

// UpdatePolicy updates an existing governance policy.
func (h *GovernanceHandler) UpdatePolicy(c *gin.Context) {
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

// DeletePolicy deletes a governance policy.
func (h *GovernanceHandler) DeletePolicy(c *gin.Context) {
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
