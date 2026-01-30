package services

import (
	"encoding/json"
	"errors"
	"time"
	"backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type TraceService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
}

func NewTraceService(db *gorm.DB) *TraceService {
	return &TraceService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
	}
}

func (s *TraceService) CreateTrace(workspaceID uuid.UUID, serviceName string, status string) (*models.Trace, error) {
	trace := models.Trace{
		WorkspaceID: workspaceID,
		ServiceName: serviceName,
		StartTime:   time.Now(),
		Status:      status,
	}

	if err := s.db.Create(&trace).Error; err != nil {
		return nil, err
	}

	return &trace, nil
}

func (s *TraceService) AddSpan(traceID uuid.UUID, parentSpanID *uuid.UUID, operationName, serviceName string, durationMs float64, tags, logs map[string]interface{}) (*models.Span, error) {
	tagsJSON, _ := json.Marshal(tags)
	logsJSON, _ := json.Marshal(logs)

	span := models.Span{
		TraceID:       traceID,
		ParentSpanID:  parentSpanID,
		OperationName: operationName,
		ServiceName:   serviceName,
		StartTime:     time.Now(),
		DurationMs:    durationMs,
		Tags:          string(tagsJSON),
		Logs:          string(logsJSON),
		Status:        "ok",
	}

	if err := s.db.Create(&span).Error; err != nil {
		return nil, err
	}

	// Update trace span count and duration
	s.db.Model(&models.Trace{}).Where("id = ?", traceID).Updates(map[string]interface{}{
		"span_count":        gorm.Expr("span_count + ?", 1),
		"total_duration_ms": gorm.Expr("total_duration_ms + ?", durationMs),
		"end_time":          time.Now(),
	})

	return &span, nil
}

func (s *TraceService) GetTraces(workspaceID, userID uuid.UUID, serviceName string, startTime, endTime *time.Time, limit, offset int) ([]models.Trace, int64, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, 0, errors.New("access denied")
	}

	query := s.db.Model(&models.Trace{}).Where("workspace_id = ?", workspaceID)

	if serviceName != "" {
		query = query.Where("service_name = ?", serviceName)
	}

	if startTime != nil {
		query = query.Where("start_time >= ?", startTime)
	}

	if endTime != nil {
		query = query.Where("start_time <= ?", endTime)
	}

	var total int64
	query.Count(&total)

	var traces []models.Trace
	err := query.Order("start_time DESC").Limit(limit).Offset(offset).Find(&traces).Error

	return traces, total, err
}

func (s *TraceService) GetTraceDetails(traceID, userID uuid.UUID) (*models.Trace, []models.Span, error) {
	var trace models.Trace
	if err := s.db.First(&trace, traceID).Error; err != nil {
		return nil, nil, err
	}

	if !s.workspaceService.HasAccess(trace.WorkspaceID, userID) {
		return nil, nil, errors.New("access denied")
	}

	var spans []models.Span
	err := s.db.Where("trace_id = ?", traceID).Order("start_time ASC").Find(&spans).Error

	return &trace, spans, err
}

func (s *TraceService) AddAnnotation(spanID, userID uuid.UUID, comment string, highlight bool) (*models.Annotation, error) {
	annotation := models.Annotation{
		SpanID:    spanID,
		UserID:    userID,
		Comment:   comment,
		Highlight: highlight,
	}

	if err := s.db.Create(&annotation).Error; err != nil {
		return nil, err
	}

	return &annotation, nil
}

func (s *TraceService) GetCriticalPath(traceID, userID uuid.UUID) ([]models.Span, error) {
	trace, spans, err := s.GetTraceDetails(traceID, userID)
	if err != nil {
		return nil, err
	}

	if trace == nil || len(spans) == 0 {
		return []models.Span{}, nil
	}

	// Build span tree and find critical path (longest sequential chain)
	criticalPath := s.findCriticalPath(spans)
	return criticalPath, nil
}

func (s *TraceService) findCriticalPath(spans []models.Span) []models.Span {
	// Simple implementation: find the longest chain based on parent-child relationships
	spanMap := make(map[uuid.UUID]*models.Span)
	for i := range spans {
		spanMap[spans[i].ID] = &spans[i]
	}

	var findLongestChain func(span *models.Span, currentPath []models.Span) []models.Span
	findLongestChain = func(span *models.Span, currentPath []models.Span) []models.Span {
		currentPath = append(currentPath, *span)
		
		longestPath := currentPath
		maxDuration := span.DurationMs

		// Find children
		for _, s := range spans {
			if s.ParentSpanID != nil && *s.ParentSpanID == span.ID {
				childPath := findLongestChain(&s, currentPath)
				childDuration := calculateTotalDuration(childPath)
				if childDuration > maxDuration {
					longestPath = childPath
					maxDuration = childDuration
				}
			}
		}

		return longestPath
	}

	// Find root spans (no parent)
	var longestOverall []models.Span
	maxOverallDuration := 0.0

	for i := range spans {
		if spans[i].ParentSpanID == nil {
			path := findLongestChain(&spans[i], []models.Span{})
			duration := calculateTotalDuration(path)
			if duration > maxOverallDuration {
				longestOverall = path
				maxOverallDuration = duration
			}
		}
	}

	return longestOverall
}

func calculateTotalDuration(spans []models.Span) float64 {
	total := 0.0
	for _, span := range spans {
		total += span.DurationMs
	}
	return total
}
