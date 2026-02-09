package services

import (
	"encoding/json"
	"errors"
	"backend/models"

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
