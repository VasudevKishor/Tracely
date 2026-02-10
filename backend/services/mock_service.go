package services

import (
	"encoding/json"
	"errors"
	"backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// MockService provides CRUD operations and trace-based generation of mocks.
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

// GenerateFromTrace generates mocks based on a trace's spans.
// Checks user access, retrieves trace spans, parses HTTP-related tags and creates Mock records in the database.
func (s *MockService) GenerateFromTrace(workspaceID, userID, traceID uuid.UUID) ([]*models.Mock, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	// Get trace spans for given trace ID.
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

				//Default Status Code
				statusCode := 200
				if code, ok := tags["http.status_code"].(float64); ok {
					statusCode = int(code)
				}

				// Create the Mock Record.
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
				//Save mocks to database.
				mocks = append(mocks, mock)
			}
		}
	}

	return mocks, nil
}

// GetAll retrieves all mocks for a workspace and user and returns an error if the user does not have access.
func (s *MockService) GetAll(workspaceID, userID uuid.UUID) ([]models.Mock, error) {
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	var mocks []models.Mock
	err := s.db.Where("workspace_id = ?", workspaceID).Find(&mocks).Error
	return mocks, err
}

// Update applies partial updates to a mock.
// Validates user access and updates only the specified fields.
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

// Delete removes a mock from the database.
// Checks user access before deletion.
func (s *MockService) Delete(mockID, userID uuid.UUID) error {
	// Searches database for a record in mocks table with primary key equal to mockID.
	var mock models.Mock
	if err := s.db.First(&mock, mockID).Error; err != nil {
		return err
	}

	// User can only delete if they have access to the workspace corresponding to the mock.
	if !s.workspaceService.HasAccess(mock.WorkspaceID, userID) {
		return errors.New("access denied")
	}

	return s.db.Delete(&mock).Error
}
