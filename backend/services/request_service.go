package services

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"
	"backend/models"

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
