package services

import (
	"errors"
	"time"
	"backend/models"

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
