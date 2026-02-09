package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"backend/middlewares"
	"backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type RequestHandler struct {
	requestService *services.RequestService
}

func NewRequestHandler(requestService *services.RequestService) *RequestHandler {
	return &RequestHandler{requestService: requestService}
}

type CreateRequestRequest struct {
	Name        string                 `json:"name" binding:"required"`
	Method      string                 `json:"method" binding:"required"`
	URL         string                 `json:"url" binding:"required"`
	Headers     map[string]string      `json:"headers"`
	QueryParams map[string]string      `json:"query_params"`
	Body        interface{}            `json:"body"`
	Description string                 `json:"description"`
}

func (h *RequestHandler) Create(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	collectionID, err := uuid.Parse(c.Param("collection_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid collection ID"})
		return
	}

	var req CreateRequestRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	headersJSON, _ := json.Marshal(req.Headers)
	paramsJSON, _ := json.Marshal(req.QueryParams)
	bodyJSON, _ := json.Marshal(req.Body)

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

func (h *RequestHandler) Update(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	requestID, err := uuid.Parse(c.Param("request_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request ID"})
		return
	}

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

type ExecuteRequestRequest struct {
	OverrideURL     string            `json:"override_url"`
	OverrideHeaders map[string]string `json:"override_headers"`
	TraceID         string            `json:"trace_id"`
	SpanID          string            `json:"span_id"`
	ParentSpanID    string            `json:"parent_span_id"`
}

func (h *RequestHandler) Execute(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	requestID, err := uuid.Parse(c.Param("request_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request ID"})
		return
	}

	var req ExecuteRequestRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		req = ExecuteRequestRequest{}
	}

	traceID := uuid.Nil
	if req.TraceID != "" {
		traceID, _ = uuid.Parse(req.TraceID)
	} else {
		traceID = uuid.New()
	}

	var spanID *uuid.UUID
	if req.SpanID != "" {
		parsedSpanID, err := uuid.Parse(req.SpanID)
		if err == nil {
			spanID = &parsedSpanID
		}
	}

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

func (h *RequestHandler) GetHistory(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	requestID, err := uuid.Parse(c.Param("request_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request ID"})
		return
	}

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
