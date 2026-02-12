/*
Package handlers contains HTTP request handlers for the API endpoints.
This file implements the RequestHandler, which manages API request-related routes,
including creating, updating, deleting, executing, and retrieving request history.
It works with the RequestService for business logic and uses middlewares to
authenticate users and retrieve their IDs.
*/
package handlers

import (
	"backend/middlewares"
	"backend/services"
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// RequestHandler handles HTTP routes related to API requests.
type RequestHandler struct {
	requestService *services.RequestService
}

// NewRequestHandler creates a new instance of RequestHandler with the provided service.
func NewRequestHandler(requestService *services.RequestService) *RequestHandler {
	return &RequestHandler{requestService: requestService}
}

// CreateRequestRequest represents the payload for creating a new API request.
type CreateRequestRequest struct {
	Name        string            `json:"name" binding:"required"`   // Request name
	Method      string            `json:"method" binding:"required"` // HTTP method (GET, POST, etc.)
	URL         string            `json:"url" binding:"required"`    // Request URL
	Headers     map[string]string `json:"headers"`                   // HTTP headers
	QueryParams map[string]string `json:"query_params"`              // Query parameters
	Body        interface{}       `json:"body"`                      // Request body
	Description string            `json:"description"`               // Optional description
}

// Create handles creating a new request under a collection.
func (h *RequestHandler) Create(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)                     // Get authenticated user ID
	collectionID, err := uuid.Parse(c.Param("collection_id")) // Parse collection UUID
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	// Bind JSON payload to struct
	var req CreateRequestRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Convert headers, query params, and body to JSON strings for storage
	headersJSON, _ := json.Marshal(req.Headers)
	paramsJSON, _ := json.Marshal(req.QueryParams)
	bodyJSON, _ := json.Marshal(req.Body)

	// Call service to create the request
	request, err := h.requestService.Create(
		collectionID,
		req.Name,
		req.Method,
		req.URL,
		string(headersJSON),
		string(paramsJSON),
		string(bodyJSON),
		req.Description,
		userID,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, request)
}

// GetByID retrieves a request by its ID.
func (h *RequestHandler) GetByID(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	requestID, err := uuid.Parse(c.Param("request_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request ID"})
		return
	}

	request, err := h.requestService.GetByID(requestID, userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, request)
}

// Update handles updating fields of an existing request.
func (h *RequestHandler) Update(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	requestID, err := uuid.Parse(c.Param("request_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request ID"})
		return
	}

	// Bind JSON payload to a map of updates
	var updates map[string]interface{}
	if err := c.ShouldBindJSON(&updates); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	request, err := h.requestService.Update(requestID, userID, updates)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, request)
}

// Delete removes a request by its ID.
func (h *RequestHandler) Delete(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	requestID, err := uuid.Parse(c.Param("request_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request ID"})
		return
	}

	if err := h.requestService.Delete(requestID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

// ExecuteRequestRequest represents payload for executing a request
type ExecuteRequestRequest struct {
	OverrideURL     string            `json:"override_url"`     // Optional URL to override original
	OverrideHeaders map[string]string `json:"override_headers"` // Optional headers override
	TraceID         string            `json:"trace_id"`         // Optional trace ID for distributed tracing
	SpanID          string            `json:"span_id"`          // Optional span ID
	ParentSpanID    string            `json:"parent_span_id"`   // Optional parent span ID
}

// Execute runs the request, optionally overriding URL and headers, and supports tracing.
func (h *RequestHandler) Execute(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	requestID, err := uuid.Parse(c.Param("request_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request ID"})
		return
	}

	var req ExecuteRequestRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		req = ExecuteRequestRequest{} // Default if no JSON provided
	}

	// Parse or generate TraceID
	traceID := uuid.Nil
	if req.TraceID != "" {
		traceID, _ = uuid.Parse(req.TraceID)
	} else {
		traceID = uuid.New()
	}

	// Parse optional SpanID
	var spanID *uuid.UUID
	if req.SpanID != "" {
		parsedSpanID, err := uuid.Parse(req.SpanID)
		if err == nil {
			spanID = &parsedSpanID
		}
	}

	// Parse optional ParentSpanID
	var parentSpanID *uuid.UUID
	if req.ParentSpanID != "" {
		parsedParentID, err := uuid.Parse(req.ParentSpanID)
		if err == nil {
			parentSpanID = &parsedParentID
		}
	}

	execution, err := h.requestService.Execute(requestID, userID, req.OverrideURL, req.OverrideHeaders, traceID, spanID, parentSpanID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, execution)
}

// GetHistory retrieves execution history of a request, with pagination support.
func (h *RequestHandler) GetHistory(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	requestID, err := uuid.Parse(c.Param("request_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request ID"})
		return
	}

	// Parse pagination query params, default to limit=50 and offset=0
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	executions, total, err := h.requestService.GetHistory(requestID, userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"executions": executions,
		"total":      total,
	})
}
