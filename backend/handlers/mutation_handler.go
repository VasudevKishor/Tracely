/*
Package handlers contains HTTP request handlers for the API endpoints.
This file implements the MutationHandler, which manages request mutation routes,
including applying mutations to requests.
*/
package handlers

import (
	"backend/middlewares"
	"backend/services"
	"net/http"

	"github.com/gin-gonic/gin"
)

// MutationHandler handles HTTP routes related to request mutations.
type MutationHandler struct {
	mutationService *services.MutationService
}

// NewMutationHandler creates a new instance of MutationHandler with the provided service.
func NewMutationHandler(mutationService *services.MutationService) *MutationHandler {
	return &MutationHandler{mutationService: mutationService}
}

// ApplyMutationsRequest represents the payload for applying mutations.
type ApplyMutationsRequest struct {
	URL       string                  `json:"url" binding:"required"`
	Body      string                  `json:"body"`
	Headers   map[string]string       `json:"headers"`
	Rules     []services.MutationRule `json:"rules" binding:"required"`
	Variables map[string]string       `json:"variables"`
}

// ApplyMutations applies mutation rules to a request.
func (h *MutationHandler) ApplyMutations(c *gin.Context) {
	_, _ = middlewares.GetUserID(c) // For authorization check

	var req ApplyMutationsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	mutatedURL, mutatedBody, mutatedHeaders, err := h.mutationService.ApplyMutations(
		req.URL, req.Body, req.Headers, req.Rules, req.Variables,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"url":     mutatedURL,
		"body":    mutatedBody,
		"headers": mutatedHeaders,
	})
}
