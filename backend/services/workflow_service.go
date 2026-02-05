package services

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Workflow struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key"`
	WorkspaceID uuid.UUID `gorm:"type:uuid;not null"`
	Name        string    `gorm:"not null"`
	Description string
	Steps       string    `gorm:"type:jsonb;not null"` // JSON array of steps
	Enabled     bool      `gorm:"default:true"`
	Schedule    string    // Cron expression
	CreatedBy   uuid.UUID `gorm:"type:uuid"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type WorkflowStep struct {
	ID           string                 `json:"id"`
	Type         string                 `json:"type"` // request, condition, loop, wait
	RequestID    *uuid.UUID             `json:"request_id,omitempty"`
	Condition    string                 `json:"condition,omitempty"` // JSONPath expression
	TrueBranch   []string               `json:"true_branch,omitempty"`
	FalseBranch  []string               `json:"false_branch,omitempty"`
	LoopCount    int                    `json:"loop_count,omitempty"`
	WaitDuration int                    `json:"wait_duration,omitempty"` // seconds
	Variables    map[string]interface{} `json:"variables,omitempty"`
}

type WorkflowExecution struct {
	ID           uuid.UUID `gorm:"type:uuid;primary_key"`
	WorkflowID   uuid.UUID `gorm:"type:uuid;not null"`
	Status       string    `gorm:"not null"` // running, completed, failed
	StartTime    time.Time `gorm:"not null"`
	EndTime      *time.Time
	Results      string `gorm:"type:jsonb"`
	ErrorMessage string
	CreatedAt    time.Time
}

type WorkflowService struct {
	db             *gorm.DB
	requestService *RequestService
}

func NewWorkflowService(db *gorm.DB) *WorkflowService {
	return &WorkflowService{
		db:             db,
		requestService: NewRequestService(db, nil),
	}
}

func (s *WorkflowService) CreateWorkflow(workspaceID, userID uuid.UUID, name, description string, steps []WorkflowStep) (*Workflow, error) {
	stepsJSON, err := json.Marshal(steps)
	if err != nil {
		return nil, err
	}

	workflow := Workflow{
		ID:          uuid.New(),
		WorkspaceID: workspaceID,
		Name:        name,
		Description: description,
		Steps:       string(stepsJSON),
		Enabled:     true,
		CreatedBy:   userID,
	}

	if err := s.db.Create(&workflow).Error; err != nil {
		return nil, err
	}

	return &workflow, nil
}

func (s *WorkflowService) ExecuteWorkflow(workflowID, userID uuid.UUID) (*WorkflowExecution, error) {
	var workflow Workflow
	if err := s.db.First(&workflow, workflowID).Error; err != nil {
		return nil, err
	}

	execution := WorkflowExecution{
		ID:         uuid.New(),
		WorkflowID: workflowID,
		Status:     "running",
		StartTime:  time.Now(),
	}

	if err := s.db.Create(&execution).Error; err != nil {
		return nil, err
	}

	// Parse steps
	var steps []WorkflowStep
	if err := json.Unmarshal([]byte(workflow.Steps), &steps); err != nil {
		s.updateExecutionStatus(execution.ID, "failed", err.Error())
		return nil, err
	}

	// Execute steps
	go s.executeSteps(execution.ID, steps, userID, make(map[string]interface{}))

	return &execution, nil
}

func (s *WorkflowService) executeSteps(executionID uuid.UUID, steps []WorkflowStep, userID uuid.UUID, context map[string]interface{}) {
	results := make(map[string]interface{})

	for _, step := range steps {
		switch step.Type {
		case "request":
			if step.RequestID != nil {
				// Execute API request
				execution, err := s.requestService.Execute(*step.RequestID, userID, "", nil, uuid.New(), nil)
				if err != nil {
					s.updateExecutionStatus(executionID, "failed", fmt.Sprintf("Step %s failed: %v", step.ID, err))
					return
				}
				results[step.ID] = execution
				context[step.ID] = execution
			}

		case "wait":
			time.Sleep(time.Duration(step.WaitDuration) * time.Second)

		case "loop":
			for i := 0; i < step.LoopCount; i++ {
				// Execute loop body (simplified)
				context["loop_index"] = i
			}

		case "condition":
			// Evaluate condition (simplified - would use JSONPath library)
			// For now, just continue
			continue
		}
	}

	resultsJSON, _ := json.Marshal(results)
	s.updateExecutionStatus(executionID, "completed", "")
	s.db.Model(&WorkflowExecution{}).Where("id = ?", executionID).Update("results", string(resultsJSON))
}

func (s *WorkflowService) updateExecutionStatus(executionID uuid.UUID, status, errorMsg string) {
	now := time.Now()
	updates := map[string]interface{}{
		"status":   status,
		"end_time": now,
	}
	if errorMsg != "" {
		updates["error_message"] = errorMsg
	}
	s.db.Model(&WorkflowExecution{}).Where("id = ?", executionID).Updates(updates)
}
