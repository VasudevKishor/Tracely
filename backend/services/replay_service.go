package services

import (
	"backend/models"
	"encoding/json"
	"errors"
	"time"

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
