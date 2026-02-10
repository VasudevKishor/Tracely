/*
Package services contains business logic for the application.
This file implements the RequestService, which handles CRUD operations
for API requests, executing them, and retrieving execution history.
It also enforces workspace access control via WorkspaceService.
*/
package services

import (
	"backend/models"
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// RequestService handles operations on requests and their executions.
type RequestService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
}

// NewRequestService creates a new RequestService instance with DB connection.
func NewRequestService(db *gorm.DB) *RequestService {
	return &RequestService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
	}
}

// Create adds a new request to a collection, enforcing workspace access.
func (s *RequestService) Create(
	collectionID uuid.UUID, name, method, url, headers, queryParams, body, description string, userID uuid.UUID,
) (*models.Request, error) {

	// Check if collection exists
	var collection models.Collection
	if err := s.db.First(&collection, collectionID).Error; err != nil {
		return nil, err
	}

	// Verify user has access to the workspace
	if !s.workspaceService.HasAccess(collection.WorkspaceID, userID) {
		return nil, errors.New("access denied")
	}

	// Create request object
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

	// Save to DB
	if err := s.db.Create(&request).Error; err != nil {
		return nil, err
	}

	// Update collection's request count
	s.db.Model(&collection).Update("request_count", gorm.Expr("request_count + ?", 1))

	return &request, nil
}

// GetByID retrieves a request by ID and verifies workspace access.
func (s *RequestService) GetByID(requestID, userID uuid.UUID) (*models.Request, error) {
	var request models.Request
	if err := s.db.Preload("Collection").First(&request, requestID).Error; err != nil {
		return nil, err
	}

	// Check access
	if !s.workspaceService.HasAccess(request.Collection.WorkspaceID, userID) {
		return nil, errors.New("access denied")
	}

	return &request, nil
}

// Update modifies fields of a request after verifying access.
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

// Delete removes a request after verifying access.
func (s *RequestService) Delete(requestID, userID uuid.UUID) error {
	request, err := s.GetByID(requestID, userID)
	if err != nil {
		return err
	}

	return s.db.Delete(request).Error
}

// Execute sends an HTTP request based on stored request data and optional overrides.
// It records execution time, response, and trace/span IDs.
func (s *RequestService) Execute(
	requestID, userID uuid.UUID,
	overrideURL string,
	overrideHeaders map[string]string,
	traceID uuid.UUID,
	spanID, parentSpanID *uuid.UUID,
) (*models.Execution, error) {

	request, err := s.GetByID(requestID, userID)
	if err != nil {
		return nil, err
	}

	startTime := time.Now() // Track execution start

	// Determine URL to use
	url := request.URL
	if overrideURL != "" {
		url = overrideURL
	}

	// Prepare request body
	var reqBody io.Reader
	if request.Body != "" {
		reqBody = bytes.NewBufferString(request.Body)
	}

	// Create HTTP request
	httpReq, err := http.NewRequest(request.Method, url, reqBody)
	if err != nil {
		return nil, err
	}

	// Set headers from request
	var headers map[string]string
	if request.Headers != "" {
		json.Unmarshal([]byte(request.Headers), &headers)
		for k, v := range headers {
			httpReq.Header.Set(k, v)
		}
	}

	// Apply override headers
	for k, v := range overrideHeaders {
		httpReq.Header.Set(k, v)
	}

	// Add trace and span IDs
	if traceID != uuid.Nil {
		httpReq.Header.Set("X-Trace-ID", traceID.String())
	}
	if spanID == nil || *spanID == uuid.Nil {
		newSpanID := uuid.New()
		spanID = &newSpanID
	}
	httpReq.Header.Set("X-Span-ID", spanID.String())
	if parentSpanID != nil && *parentSpanID != uuid.Nil {
		httpReq.Header.Set("X-Parent-Span-ID", parentSpanID.String())
	}

	// Execute HTTP request
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(httpReq)
	responseTime := time.Since(startTime).Milliseconds() // Measure response time

	// Record execution details
	execution := models.Execution{
		RequestID:      requestID,
		ResponseTimeMs: responseTime,
		TraceID:        traceID,
		SpanID:         spanID,
		ParentSpanID:   parentSpanID,
		Timestamp:      startTime,
	}

	if err != nil {
		// Error during request execution
		execution.ErrorMessage = err.Error()
		execution.StatusCode = 0
	} else {
		defer resp.Body.Close()
		execution.StatusCode = resp.StatusCode

		// Capture response body
		bodyBytes, _ := io.ReadAll(resp.Body)
		execution.ResponseBody = string(bodyBytes)

		// Save response headers
		headersJSON, _ := json.Marshal(resp.Header)
		execution.ResponseHeaders = string(headersJSON)
	}

	// Persist execution record
	if err := s.db.Create(&execution).Error; err != nil {
		return nil, err
	}

	return &execution, nil
}

// GetHistory retrieves a paginated list of executions for a request.
func (s *RequestService) GetHistory(requestID, userID uuid.UUID, limit, offset int) ([]models.Execution, int64, error) {
	request, err := s.GetByID(requestID, userID)
	if err != nil {
		return nil, 0, err
	}

	var executions []models.Execution
	var total int64

	// Get total executions count
	s.db.Model(&models.Execution{}).Where("request_id = ?", request.ID).Count(&total)

	// Fetch paginated executions
	err = s.db.Where("request_id = ?", request.ID).
		Order("timestamp DESC").
		Limit(limit).
		Offset(offset).
		Find(&executions).Error

	return executions, total, err
}
