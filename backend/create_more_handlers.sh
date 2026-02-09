#!/bin/bash

# Request Handler
cat > /home/claude/tracely-backend/handlers/request_handler.go << 'EOF'
package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"tracely-backend/middlewares"
	"tracely-backend/services"

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

	execution, err := h.requestService.Execute(requestID, userID, req.OverrideURL, req.OverrideHeaders, traceID)
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
EOF

# Trace Handler
cat > /home/claude/tracely-backend/handlers/trace_handler.go << 'EOF'
package handlers

import (
	"net/http"
	"strconv"
	"time"
	"tracely-backend/middlewares"
	"tracely-backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type TraceHandler struct {
	traceService *services.TraceService
}

func NewTraceHandler(traceService *services.TraceService) *TraceHandler {
	return &TraceHandler{traceService: traceService}
}

func (h *TraceHandler) GetTraces(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	serviceName := c.Query("service_name")
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	var startTime, endTime *time.Time
	if st := c.Query("start_time"); st != "" {
		t, _ := time.Parse(time.RFC3339, st)
		startTime = &t
	}
	if et := c.Query("end_time"); et != "" {
		t, _ := time.Parse(time.RFC3339, et)
		endTime = &t
	}

	traces, total, err := h.traceService.GetTraces(workspaceID, userID, serviceName, startTime, endTime, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"traces": traces,
		"total":  total,
	})
}

func (h *TraceHandler) GetTraceDetails(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	traceID, err := uuid.Parse(c.Param("trace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid trace ID"})
		return
	}

	trace, spans, err := h.traceService.GetTraceDetails(traceID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"trace_id": trace.ID,
		"spans":    spans,
	})
}

type AddAnnotationRequest struct {
	Comment   string `json:"comment" binding:"required"`
	Highlight bool   `json:"highlight"`
}

func (h *TraceHandler) AddAnnotation(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	spanID, err := uuid.Parse(c.Param("span_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid span ID"})
		return
	}

	var req AddAnnotationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	annotation, err := h.traceService.AddAnnotation(spanID, userID, req.Comment, req.Highlight)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, annotation)
}

func (h *TraceHandler) GetCriticalPath(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	traceID, err := uuid.Parse(c.Param("trace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid trace ID"})
		return
	}

	criticalPath, err := h.traceService.GetCriticalPath(traceID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"critical_path": criticalPath,
	})
}
EOF

# Monitoring Handler
cat > /home/claude/tracely-backend/handlers/monitoring_handler.go << 'EOF'
package handlers

import (
	"net/http"
	"tracely-backend/middlewares"
	"tracely-backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type MonitoringHandler struct {
	monitoringService *services.MonitoringService
}

func NewMonitoringHandler(monitoringService *services.MonitoringService) *MonitoringHandler {
	return &MonitoringHandler{monitoringService: monitoringService}
}

func (h *MonitoringHandler) GetDashboard(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	timeRange := c.DefaultQuery("time_range", "last_hour")

	dashboard, err := h.monitoringService.GetDashboard(workspaceID, userID, timeRange)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, dashboard)
}

func (h *MonitoringHandler) GetMetrics(c *gin.Context) {
	// Placeholder for metrics endpoint
	c.JSON(http.StatusOK, gin.H{
		"message": "Metrics endpoint - to be implemented",
	})
}

func (h *MonitoringHandler) GetTopology(c *gin.Context) {
	userID, _ := middlewares.GetUserID(c)
	workspaceID, err := uuid.Parse(c.Param("workspace_id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid workspace ID"})
		return
	}

	topology, err := h.monitoringService.GetTopology(workspaceID, userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, topology)
}
EOF

# Governance Handler
cat > /home/claude/tracely-backend/handlers/governance_handler.go << 'EOF'
package handlers

import (
	"net/http"
	"tracely-backend/middlewares"
	"tracely-backend/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type GovernanceHandler struct {
	governanceService *services.GovernanceService
}

func NewGovernanceHandler(governanceService *services.GovernanceService) *GovernanceHandler {
	return &GovernanceHandler{governanceService: governanceService}
}

type CreatePolicyRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
	Rules       string `json:"rules" binding:"required"`
	Enabled     bool   `json:"enabled"`
}

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
EOF

echo "More handlers created (2/3)"
