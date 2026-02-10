/*
Package services contains business logic for the application.
This file implements the ReplayService, which handles creation, execution,
and result retrieval of replays. Replays allow replaying API calls or traces
in a workspace with a given configuration. Access control is enforced via WorkspaceService.
*/
package services

import (
	"backend/models"
	"encoding/json"
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// ReplayService provides methods to create, execute, and retrieve replays.
type ReplayService struct {
	db               *gorm.DB
	workspaceService *WorkspaceService
	traceService     *TraceService
}

// NewReplayService creates a new ReplayService instance.
func NewReplayService(db *gorm.DB) *ReplayService {
	return &ReplayService{
		db:               db,
		workspaceService: NewWorkspaceService(db),
		traceService:     NewTraceService(db),
	}
}

// CreateReplay creates a new replay in a workspace with given configuration.
// Parameters:
// - workspaceID: ID of the workspace where replay is created
// - userID: ID of the user creating the replay
// - name, description: metadata for the replay
// - sourceTraceID: ID of the trace to replay
// - targetEnv: target environment for replay execution
// - config: replay-specific configuration (mutations, filters, etc.)
func (s *ReplayService) CreateReplay(
	workspaceID, userID uuid.UUID,
	name, description string,
	sourceTraceID uuid.UUID,
	targetEnv string,
	config map[string]interface{},
) (*models.Replay, error) {

	// Enforce workspace access control
	if !s.workspaceService.HasAccess(workspaceID, userID) {
		return nil, errors.New("access denied")
	}

	// Convert configuration to JSON string
	configJSON, _ := json.Marshal(config)

	// Create replay object
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

	// Save replay to database
	if err := s.db.Create(&replay).Error; err != nil {
		return nil, err
	}

	return &replay, nil
}

// GetReplay fetches a replay by ID and ensures the user has access.
func (s *ReplayService) GetReplay(replayID, userID uuid.UUID) (*models.Replay, error) {
	var replay models.Replay

	// Fetch replay from DB
	if err := s.db.First(&replay, replayID).Error; err != nil {
		return nil, err
	}

	// Enforce workspace access
	if !s.workspaceService.HasAccess(replay.WorkspaceID, userID) {
		return nil, errors.New("access denied")
	}

	return &replay, nil
}

// ExecuteReplay executes a replay and records its execution results.
// Simplified version: in real implementation, it would replay requests from source trace.
func (s *ReplayService) ExecuteReplay(replayID, userID uuid.UUID) (*models.ReplayExecution, error) {
	// Fetch replay and verify access
	replay, err := s.GetReplay(replayID, userID)
	if err != nil {
		return nil, err
	}

	// Mark replay as running
	s.db.Model(replay).Update("status", "running")

	startTime := time.Now()

	// Create a new trace for this execution
	trace, err := s.traceService.CreateTrace(replay.WorkspaceID, "replay-service", "success")
	if err != nil {
		return nil, err
	}

	// Execution logic placeholder:
	// In real implementation:
	// 1. Fetch original trace events
	// 2. Apply configuration/mutations
	// 3. Send requests in correct sequence
	// 4. Collect responses/results

	execution := models.ReplayExecution{
		ReplayID:         replayID,
		ExecutionTraceID: trace.ID,
		Status:           "success",
		StartTime:        startTime,
		EndTime:          time.Now(),
		DurationMs:       time.Since(startTime).Milliseconds(),
		Results:          "{}", // placeholder for actual results
	}

	// Save execution record
	if err := s.db.Create(&execution).Error; err != nil {
		return nil, err
	}

	// Mark replay as completed
	s.db.Model(replay).Update("status", "completed")

	return &execution, nil
}

// GetResults retrieves all executions/results for a given replay.
// Returns executions sorted by most recent first.
func (s *ReplayService) GetResults(replayID, userID uuid.UUID) ([]models.ReplayExecution, error) {
	// Verify replay and access
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
