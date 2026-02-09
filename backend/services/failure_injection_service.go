package services

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type FailureInjectionRule struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key"`
	WorkspaceID uuid.UUID `gorm:"type:uuid;not null"`
	Name        string    `gorm:"not null"`
	Type        string    `gorm:"not null"`    // timeout, error, latency, unavailable
	Probability float64   `gorm:"default:1.0"` // 0-1
	Config      string    `gorm:"type:jsonb"`
	Enabled     bool      `gorm:"default:true"`
	CreatedAt   time.Time
}

type FailureInjectionService struct {
	db *gorm.DB
}

func NewFailureInjectionService(db *gorm.DB) *FailureInjectionService {
	return &FailureInjectionService{db: db}
}

// InjectFailure applies failure injection to HTTP request
func (s *FailureInjectionService) InjectFailure(workspaceID uuid.UUID, req *http.Request) error {
	var rules []FailureInjectionRule
	s.db.Where("workspace_id = ? AND enabled = true", workspaceID).Find(&rules)

	for _, rule := range rules {
		// Check probability
		if rand.Float64() > rule.Probability {
			continue
		}

		switch rule.Type {
		case "timeout":
			return s.injectTimeout(rule)
		case "error":
			return s.injectError(rule)
		case "latency":
			return s.injectLatency(rule)
		case "unavailable":
			return s.injectUnavailable(rule)
		}
	}

	return nil
}

func (s *FailureInjectionService) injectTimeout(rule FailureInjectionRule) error {
	// Simulate timeout by waiting longer than client timeout
	time.Sleep(35 * time.Second)
	return fmt.Errorf("timeout injected")
}

func (s *FailureInjectionService) injectError(rule FailureInjectionRule) error {
	var config struct {
		StatusCode int    `json:"status_code"`
		Message    string `json:"message"`
	}
	json.Unmarshal([]byte(rule.Config), &config)

	return fmt.Errorf("HTTP %d: %s", config.StatusCode, config.Message)
}

func (s *FailureInjectionService) injectLatency(rule FailureInjectionRule) error {
	var config struct {
		DelayMs int `json:"delay_ms"`
	}
	json.Unmarshal([]byte(rule.Config), &config)

	time.Sleep(time.Duration(config.DelayMs) * time.Millisecond)
	return nil
}

func (s *FailureInjectionService) injectUnavailable(rule FailureInjectionRule) error {
	return fmt.Errorf("503 Service Unavailable (injected)")
}

// CreateRule creates a new failure injection rule
func (s *FailureInjectionService) CreateRule(workspaceID uuid.UUID, name, failureType string, probability float64, config map[string]interface{}) (*FailureInjectionRule, error) {
	configJSON, _ := json.Marshal(config)

	rule := FailureInjectionRule{
		ID:          uuid.New(),
		WorkspaceID: workspaceID,
		Name:        name,
		Type:        failureType,
		Probability: probability,
		Config:      string(configJSON),
		Enabled:     true,
	}

	if err := s.db.Create(&rule).Error; err != nil {
		return nil, err
	}

	return &rule, nil
}
