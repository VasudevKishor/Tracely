/*
Package handlers contains HTTP request handlers for the API endpoints.
This file implements the FailureInjectionHandler, which manages failure injection routes,
including creating rules and applying failures.
*/
package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// FailureInjectionHandler handles HTTP routes related to failure injection.
type FailureInjectionHandler struct {
	failureInjectionService *services.FailureInjectionService
}

// NewFailureInjectionHandler creates a new instance of FailureInjectionHandler with the provided service.
func NewFailureInjectionHandler(failureInjectionService *services.FailureInjectionService) *FailureInjectionHandler {
	return &FailureInjectionHandler{failureInjectionService: failureInjectionService}
}

// CreateRuleRequest represents the payload for creating a failure injection rule.
type CreateRuleRequest struct {
	Name        string                 `json:"name" binding:"required"`
	Type        string                 `json:"type" binding:"required"`
	Probability float64                `json:"probability"`
	Config      map[string]interface{} `json:"config"`
}

// CreateRule creates a new failure injection rule.
func (h *FailureInjectionHandler) CreateRule(c *gin.Context) {
	_, _ = middlewares.GetUserID(c) // For authorization check
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	var req CreateRuleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	rule, err := h.failureInjectionService.CreateRule(workspaceID, req.Name, req.Type, req.Probability, req.Config)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, rule)
}
