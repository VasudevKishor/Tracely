#!/bin/bash

# Request Service
cat > /home/claude/tracely-backend/services/request_service.go << 'EOF'
package services

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"
	"tracely-backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type RequestService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
}

func NewRequestService(db *gorm.DB) *RequestService {
	return &RequestService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
	}
}

func (s *RequestService) Create(collectionID uuid.UUID, name, method, url, headers, queryParams, body, description string, userID uuid.UUID) (*models.Request, error) {
	var collection models.Collection
	if err := s.db.First(&collection, collectionID).Error; err != nil {
		return nil, err
	}

	if !s.workspaceService.HasAccess(collection.WorkspaceID, userID) {
		return nil, errors.New("access denied")
	}

	request := models.Request{
		Name:         name,
		Method:       method,
		URL:          url,
		Headers:      headers,
		QueryParams:  queryParams,
		Body:         body,
		Description:  description,
		CollectionID: collectionID,
	}

	if err := s.db.Create(&request).Error; err != nil {
		return nil, err
	}

	// Update collection request count
	s.db.Model(&collection).Update("request_count", gorm.Expr("request_count + ?", 1))

	return &request, nil
}

func (s *RequestService) GetByID(requestID, userID uuid.UUID) (*models.Request, error) {
	var request models.Request
	if err := s.db.Preload("Collection").First(&request, requestID).Error; err != nil {
		return nil, err
	}

	if !s.workspaceService.HasAccess(request.Collection.WorkspaceID, userID) {
		return nil, errors.New("access denied")
	}

	return &request, nil
}

func (s *RequestService) Update(requestID, userID uuid.UUID, updates map[string]interface{}) (*models.Request, error) {
	request, err := s.GetByID(requestID, userID)
	if err != nil {
		return nil, err
	}

	if err := s.db.Model(request).Updates(updates).Error; err != nil {
		return nil, err
	}

	return request, nil
}

func (s *RequestService) Delete(requestID, userID uuid.UUID) error {
	request, err := s.GetByID(requestID, userID)
	if err != nil {
		return err
	}

	return s.db.Delete(request).Error
}

func (s *RequestService) Execute(requestID, userID uuid.UUID, overrideURL string, overrideHeaders map[string]string, traceID uuid.UUID) (*models.Execution, error) {
	request, err := s.GetByID(requestID, userID)
	if err != nil {
		return nil, err
	}

	startTime := time.Now()

	// Prepare request
	url := request.URL
	if overrideURL != "" {
		url = overrideURL
	}

	var reqBody io.Reader
	if request.Body != "" {
		reqBody = bytes.NewBufferString(request.Body)
	}

	httpReq, err := http.NewRequest(request.Method, url, reqBody)
	if err != nil {
		return nil, err
	}

	// Set headers
	var headers map[string]string
	if request.Headers != "" {
		json.Unmarshal([]byte(request.Headers), &headers)
		for k, v := range headers {
			httpReq.Header.Set(k, v)
		}
	}

	// Override headers if provided
	for k, v := range overrideHeaders {
		httpReq.Header.Set(k, v)
	}

	// Add trace ID
	if traceID != uuid.Nil {
		httpReq.Header.Set("X-Trace-ID", traceID.String())
	}

	// Execute request
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(httpReq)
	
	responseTime := time.Since(startTime).Milliseconds()

	execution := models.Execution{
		RequestID:      requestID,
		ResponseTimeMs: responseTime,
		TraceID:        traceID,
		Timestamp:      startTime,
	}

	if err != nil {
		execution.ErrorMessage = err.Error()
		execution.StatusCode = 0
	} else {
		defer resp.Body.Close()
		execution.StatusCode = resp.StatusCode

		// Read response body
		bodyBytes, _ := io.ReadAll(resp.Body)
		execution.ResponseBody = string(bodyBytes)

		// Save response headers
		headersJSON, _ := json.Marshal(resp.Header)
		execution.ResponseHeaders = string(headersJSON)
	}

	if err := s.db.Create(&execution).Error; err != nil {
		return nil, err
	}

	return &execution, nil
}

func (s *RequestService) GetHistory(requestID, userID uuid.UUID, limit, offset int) ([]models.Execution, int64, error) {
	request, err := s.GetByID(requestID, userID)
	if err != nil {
		return nil, 0, err
	}

	var executions []models.Execution
	var total int64

	s.db.Model(&models.Execution{}).Where("request_id = ?", request.ID).Count(&total)
	
	err = s.db.Where("request_id = ?", request.ID).
		Order("timestamp DESC").
		Limit(limit).
		Offset(offset).
		Find(&executions).Error

	return executions, total, err
}
EOF

# Trace Service
cat > /home/claude/tracely-backend/services/trace_service.go << 'EOF'
package services

import (
	"encoding/json"
	"errors"
	"time"
	"tracely-backend/models"

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
EOF

# Monitoring Service
cat > /home/claude/tracely-backend/services/monitoring_service.go << 'EOF'
package services

import (
	"errors"
	"time"
	"tracely-backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type MonitoringService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
}

type DashboardData struct {
	TotalRequests      int64                  `json:"total_requests"`
	SuccessfulRequests int64                  `json:"successful_requests"`
	FailedRequests     int64                  `json:"failed_requests"`
	AvgResponseTimeMs  float64                `json:"avg_response_time_ms"`
	P95ResponseTimeMs  float64                `json:"p95_response_time_ms"`
	P99ResponseTimeMs  float64                `json:"p99_response_time_ms"`
	ErrorRate          float64                `json:"error_rate"`
	TopEndpoints       []map[string]interface{} `json:"top_endpoints"`
	Services           []map[string]interface{} `json:"services"`
}

func NewMonitoringService(db *gorm.DB) *MonitoringService {
	return &MonitoringService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
	}
}

func (s *MonitoringService) GetDashboard(workspaceID, userID uuid.UUID, timeRange string) (*DashboardData, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	// Calculate time range
	var startTime time.Time
	switch timeRange {
	case "last_hour":
		startTime = time.Now().Add(-1 * time.Hour)
	case "last_24h":
		startTime = time.Now().Add(-24 * time.Hour)
	case "last_7d":
		startTime = time.Now().Add(-7 * 24 * time.Hour)
	case "last_30d":
		startTime = time.Now().Add(-30 * 24 * time.Hour)
	default:
		startTime = time.Now().Add(-1 * time.Hour)
	}

	dashboard := &DashboardData{
		TopEndpoints: []map[string]interface{}{},
		Services:     []map[string]interface{}{},
	}

	// Get total requests
	s.db.Model(&models.Execution{}).
		Where("timestamp >= ?", startTime).
		Count(&dashboard.TotalRequests)

	// Get successful requests
	s.db.Model(&models.Execution{}).
		Where("timestamp >= ? AND status_code >= 200 AND status_code < 400", startTime).
		Count(&dashboard.SuccessfulRequests)

	dashboard.FailedRequests = dashboard.TotalRequests - dashboard.SuccessfulRequests

	if dashboard.TotalRequests > 0 {
		dashboard.ErrorRate = float64(dashboard.FailedRequests) / float64(dashboard.TotalRequests) * 100
	}

	// Get average response time
	var avgTime *float64
	s.db.Model(&models.Execution{}).
		Where("timestamp >= ?", startTime).
		Select("AVG(response_time_ms)").
		Row().Scan(&avgTime)
	
	if avgTime != nil {
		dashboard.AvgResponseTimeMs = *avgTime
	}

	// Get percentiles (simplified - should use proper percentile calculation)
	type PercentileResult struct {
		P95 float64
		P99 float64
	}

	// Get services
	var traces []models.Trace
	s.db.Where("workspace_id = ? AND start_time >= ?", workspaceID, startTime).
		Group("service_name").
		Find(&traces)

	for _, trace := range traces {
		serviceData := map[string]interface{}{
			"name":          trace.ServiceName,
			"status":        "healthy",
			"request_count": 0,
		}

		var count int64
		s.db.Model(&models.Trace{}).
			Where("workspace_id = ? AND service_name = ? AND start_time >= ?", workspaceID, trace.ServiceName, startTime).
			Count(&count)
		
		serviceData["request_count"] = count
		dashboard.Services = append(dashboard.Services, serviceData)
	}

	return dashboard, nil
}

func (s *MonitoringService) GetTopology(workspaceID, userID uuid.UUID) (map[string]interface{}, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	// Build service dependency graph from spans
	var spans []models.Span
	s.db.Joins("JOIN traces ON traces.id = spans.trace_id").
		Where("traces.workspace_id = ?", workspaceID).
		Select("spans.*").
		Find(&spans)

	// Build adjacency map
	dependencies := make(map[string][]string)
	services := make(map[string]bool)

	for _, span := range spans {
		services[span.ServiceName] = true
		
		if span.ParentSpanID != nil {
			var parentSpan models.Span
			if err := s.db.First(&parentSpan, span.ParentSpanID).Error; err == nil {
				if parentSpan.ServiceName != span.ServiceName {
					key := parentSpan.ServiceName
					if !contains(dependencies[key], span.ServiceName) {
						dependencies[key] = append(dependencies[key], span.ServiceName)
					}
				}
			}
		}
	}

	nodes := []map[string]string{}
	for service := range services {
		nodes = append(nodes, map[string]string{
			"id":   service,
			"name": service,
		})
	}

	edges := []map[string]string{}
	for source, targets := range dependencies {
		for _, target := range targets {
			edges = append(edges, map[string]string{
				"source": source,
				"target": target,
			})
		}
	}

	return map[string]interface{}{
		"nodes": nodes,
		"edges": edges,
	}, nil
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
EOF

# Governance Service
cat > /home/claude/tracely-backend/services/governance_service.go << 'EOF'
package services

import (
	"errors"
	"tracely-backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type GovernanceService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
}

func NewGovernanceService(db *gorm.DB) *GovernanceService {
	return &GovernanceService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
	}
}

func (s *GovernanceService) GetPolicies(workspaceID, userID uuid.UUID) ([]models.Policy, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	var policies []models.Policy
	err := s.db.Where("workspace_id = ?", workspaceID).Find(&policies).Error
	return policies, err
}

func (s *GovernanceService) CreatePolicy(workspaceID, userID uuid.UUID, name, description, rules string, enabled bool) (*models.Policy, error) {
	if !s.workspaceService.IsAdmin(workspaceID, userID) {
		return nil, errors.New("permission denied")
	}

	policy := models.Policy{
		WorkspaceID: workspaceID,
		Name:        name,
		Description: description,
		Rules:       rules,
		Enabled:     enabled,
	}

	if err := s.db.Create(&policy).Error; err != nil {
		return nil, err
	}

	return &policy, nil
}

func (s *GovernanceService) UpdatePolicy(policyID, userID uuid.UUID, updates map[string]interface{}) (*models.Policy, error) {
	var policy models.Policy
	if err := s.db.First(&policy, policyID).Error; err != nil {
		return nil, err
	}

	if !s.workspaceService.IsAdmin(policy.WorkspaceID, userID) {
		return nil, errors.New("permission denied")
	}

	if err := s.db.Model(&policy).Updates(updates).Error; err != nil {
		return nil, err
	}

	return &policy, nil
}

func (s *GovernanceService) DeletePolicy(policyID, userID uuid.UUID) error {
	var policy models.Policy
	if err := s.db.First(&policy, policyID).Error; err != nil {
		return err
	}

	if !s.workspaceService.IsAdmin(policy.WorkspaceID, userID) {
		return errors.New("permission denied")
	}

	return s.db.Delete(&policy).Error
}
EOF

# Settings Service
cat > /home/claude/tracely-backend/services/settings_service.go << 'EOF'
package services

import (
	"tracely-backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SettingsService struct {
	db *gorm.DB
}

func NewSettingsService(db *gorm.DB) *SettingsService {
	return &SettingsService{db: db}
}

func (s *SettingsService) GetSettings(userID uuid.UUID) (*models.UserSettings, error) {
	var settings models.UserSettings
	err := s.db.Where("user_id = ?", userID).First(&settings).Error
	
	if err == gorm.ErrRecordNotFound {
		// Create default settings
		settings = models.UserSettings{
			UserID:               userID,
			Theme:                "light",
			NotificationsEnabled: true,
			EmailNotifications:   true,
			Language:             "en",
			Timezone:             "UTC",
			Preferences:          "{}",
		}
		s.db.Create(&settings)
		return &settings, nil
	}

	return &settings, err
}

func (s *SettingsService) UpdateSettings(userID uuid.UUID, updates map[string]interface{}) (*models.UserSettings, error) {
	settings, err := s.GetSettings(userID)
	if err != nil {
		return nil, err
	}

	if err := s.db.Model(settings).Updates(updates).Error; err != nil {
		return nil, err
	}

	return settings, nil
}
EOF

# Replay Service
cat > /home/claude/tracely-backend/services/replay_service.go << 'EOF'
package services

import (
	"encoding/json"
	"errors"
	"time"
	"tracely-backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ReplayService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
	traceService     *TraceService
}

func NewReplayService(db *gorm.DB) *ReplayService {
	return &ReplayService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
		traceService:     NewTraceService(db),
	}
}

func (s *ReplayService) CreateReplay(workspaceID, userID uuid.UUID, name, description string, sourceTraceID uuid.UUID, targetEnv string, config map[string]interface{}) (*models.Replay, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	configJSON, _ := json.Marshal(config)

	replay := models.Replay{
		WorkspaceID:       workspaceID,
		Name:              name,
		Description:       description,
		SourceTraceID:     sourceTraceID,
		TargetEnvironment: targetEnv,
		Configuration:     string(configJSON),
		Status:            "pending",
		CreatedBy:         userID,
	}

	if err := s.db.Create(&replay).Error; err != nil {
		return nil, err
	}

	return &replay, nil
}

func (s *ReplayService) GetReplay(replayID, userID uuid.UUID) (*models.Replay, error) {
	var replay models.Replay
	if err := s.db.First(&replay, replayID).Error; err != nil {
		return nil, err
	}

	if !s.workspaceService.HasAccess(replay.WorkspaceID, userID) {
		return nil, errors.New("access denied")
	}

	return &replay, nil
}

func (s *ReplayService) ExecuteReplay(replayID, userID uuid.UUID) (*models.ReplayExecution, error) {
	replay, err := s.GetReplay(replayID, userID)
	if err != nil {
		return nil, err
	}

	// Update replay status
	s.db.Model(replay).Update("status", "running")

	startTime := time.Now()

	// Create execution trace
	trace, err := s.traceService.CreateTrace(replay.WorkspaceID, "replay-service", "success")
	if err != nil {
		return nil, err
	}

	// Execute replay logic here (simplified)
	// In a real implementation, this would:
	// 1. Fetch original trace
	// 2. Apply mutations from configuration
	// 3. Execute requests in sequence
	// 4. Collect results

	execution := models.ReplayExecution{
		ReplayID:         replayID,
		ExecutionTraceID: trace.ID,
		Status:           "success",
		StartTime:        startTime,
		EndTime:          time.Now(),
		DurationMs:       time.Since(startTime).Milliseconds(),
		Results:          "{}",
	}

	if err := s.db.Create(&execution).Error; err != nil {
		return nil, err
	}

	// Update replay status
	s.db.Model(replay).Update("status", "completed")

	return &execution, nil
}

func (s *ReplayService) GetResults(replayID, userID uuid.UUID) ([]models.ReplayExecution, error) {
	replay, err := s.GetReplay(replayID, userID)
	if err != nil {
		return nil, err
	}

	var executions []models.ReplayExecution
	err = s.db.Where("replay_id = ?", replay.ID).
		Order("created_at DESC").
		Find(&executions).Error

	return executions, err
}
EOF

# Mock Service
cat > /home/claude/tracely-backend/services/mock_service.go << 'EOF'
package services

import (
	"encoding/json"
	"errors"
	"tracely-backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type MockService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
	traceService     *TraceService
}

func NewMockService(db *gorm.DB) *MockService {
	return &MockService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
		traceService:     NewTraceService(db),
	}
}

func (s *MockService) GenerateFromTrace(workspaceID, userID, traceID uuid.UUID) ([]*models.Mock, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	// Get trace spans
	_, spans, err := s.traceService.GetTraceDetails(traceID, userID)
	if err != nil {
		return nil, err
	}

	var mocks []*models.Mock

	// Generate mocks from spans
	for _, span := range spans {
		// Parse tags to extract request/response info
		var tags map[string]interface{}
		json.Unmarshal([]byte(span.Tags), &tags)

		if method, ok := tags["http.method"].(string); ok {
			if url, ok := tags["http.url"].(string); ok {
				responseBody := "{}"
				if body, ok := tags["http.response.body"]; ok {
					if bodyStr, ok := body.(string); ok {
						responseBody = bodyStr
					}
				}

				statusCode := 200
				if code, ok := tags["http.status_code"].(float64); ok {
					statusCode = int(code)
				}

				mock := &models.Mock{
					WorkspaceID:     workspaceID,
					Name:            span.OperationName + " Mock",
					Description:     "Auto-generated from trace",
					Method:          method,
					PathPattern:     url,
					ResponseBody:    responseBody,
					ResponseHeaders: "{}",
					StatusCode:      statusCode,
					Latency:         int(span.DurationMs),
					Enabled:         true,
					SourceTraceID:   &traceID,
				}

				if err := s.db.Create(mock).Error; err != nil {
					continue
				}

				mocks = append(mocks, mock)
			}
		}
	}

	return mocks, nil
}

func (s *MockService) GetAll(workspaceID, userID uuid.UUID) ([]models.Mock, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	var mocks []models.Mock
	err := s.db.Where("workspace_id = ?", workspaceID).Find(&mocks).Error
	return mocks, err
}

func (s *MockService) Update(mockID, userID uuid.UUID, updates map[string]interface{}) (*models.Mock, error) {
	var mock models.Mock
	if err := s.db.First(&mock, mockID).Error; err != nil {
		return nil, err
	}

	if !s.workspaceService.HasAccess(mock.WorkspaceID, userID) {
		return nil, errors.New("access denied")
	}

	if err := s.db.Model(&mock).Updates(updates).Error; err != nil {
		return nil, err
	}

	return &mock, nil
}

func (s *MockService) Delete(mockID, userID uuid.UUID) error {
	var mock models.Mock
	if err := s.db.First(&mock, mockID).Error; err != nil {
		return err
	}

	if !s.workspaceService.HasAccess(mock.WorkspaceID, userID) {
		return errors.New("access denied")
	}

	return s.db.Delete(&mock).Error
}
EOF

echo "All services created successfully"
