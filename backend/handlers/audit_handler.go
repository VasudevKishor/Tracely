/*
Package handlers contains HTTP request handlers for the API endpoints.
This file implements the AuditHandler, which manages audit logging routes,
including retrieving audit logs and detecting anomalies.
*/
package handlers

import (
	"backend/services"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AuditHandler handles HTTP routes related to audit logging.
type AuditHandler struct {
	auditService *services.AuditService
}

// NewAuditHandler creates a new instance of AuditHandler with the provided service.
func NewAuditHandler(auditService *services.AuditService) *AuditHandler {
	return &AuditHandler{auditService: auditService}
}

// GetLogs retrieves audit logs with optional filters.
func (h *AuditHandler) GetLogs(c *gin.Context) {
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	filters := make(map[string]interface{})

	// Validate User ID if provided
	if userIDParam := c.Query("user_id"); userIDParam != "" {
		parsedUserID, err := uuid.Parse(userIDParam)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid user ID format"})
			return
		}
		filters["user_id"] = parsedUserID
	}

	filters["action"] = c.Query("action")
	filters["resource_type"] = c.Query("resource_type")

	// Better pagination handling
	limit, err := strconv.Atoi(c.DefaultQuery("limit", "50"))
	if err != nil || limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	} // Hard cap for performance

	offset, err := strconv.Atoi(c.DefaultQuery("offset", "0"))
	if err != nil || offset < 0 {
		offset = 0
	}

	logs, err := h.auditService.GetLogs(workspaceID, filters, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch logs"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"logs": logs})
}

// DetectAnomalies detects unusual access patterns for a user in a workspace.
func (h *AuditHandler) DetectAnomalies(c *gin.Context) {
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	targetUserID, err := uuid.Parse(c.Param("target_user_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid target user ID"})
		return
	}

	anomalies, err := h.auditService.DetectAnomalies(workspaceID, targetUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"anomalies": anomalies})
}
