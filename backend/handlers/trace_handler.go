package handlers

import (
	"net/http"
	"strconv"
	"time"
	"backend/middlewares"
	"backend/services"

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
