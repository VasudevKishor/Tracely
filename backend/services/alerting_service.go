package services

import (
	"backend/models"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AlertRule struct {
	ID                  uuid.UUID `gorm:"type:uuid;primary_key"`
	WorkspaceID         uuid.UUID `gorm:"type:uuid;not null"`
	Name                string    `gorm:"not null"`
	Condition           string    `gorm:"not null"` // latency_threshold, error_rate, etc.
	Threshold           float64   `gorm:"not null"`
	TimeWindow          int       `gorm:"not null"` // minutes
	Enabled             bool      `gorm:"default:true"`
	NotificationChannel string    `gorm:"not null"` // slack, email, pagerduty
	NotificationConfig  string    `gorm:"type:jsonb"`
	CreatedAt           time.Time
	UpdatedAt           time.Time
}

type Alert struct {
	ID          uuid.UUID `gorm:"type:uuid;primary_key"`
	RuleID      uuid.UUID `gorm:"type:uuid;not null"`
	WorkspaceID uuid.UUID `gorm:"type:uuid;not null"`
	Severity    string    `gorm:"not null"` // critical, warning, info
	Message     string    `gorm:"type:text"`
	TriggeredAt time.Time `gorm:"not null"`
	ResolvedAt  *time.Time
	Status      string `gorm:"default:'active'"` // active, resolved, acknowledged
	Metadata    string `gorm:"type:jsonb"`
	CreatedAt   time.Time
}

type AlertingService struct {
	db *gorm.DB
}

func NewAlertingService(db *gorm.DB) *AlertingService {
	return &AlertingService{db: db}
}

// CreateRule creates a new alert rule
func (s *AlertingService) CreateRule(userID uuid.UUID, workspaceID uuid.UUID, name, condition string, threshold float64, timeWindow int, channel string) (*AlertRule, error) {
	rule := AlertRule{
		ID:                  uuid.New(),
		WorkspaceID:         workspaceID,
		Name:                name,
		Condition:           condition,
		Threshold:           threshold,
		TimeWindow:          timeWindow,
		Enabled:             true,
		NotificationChannel: channel,
	}

	if err := s.db.Create(&rule).Error; err != nil {
		return nil, err
	}

	return &rule, nil
}

// CheckLatencyThreshold checks if latency exceeds threshold
func (s *AlertingService) CheckLatencyThreshold(workspaceID uuid.UUID) error {
	var rules []AlertRule
	s.db.Where("workspace_id = ? AND condition = 'latency_threshold' AND enabled = true", workspaceID).Find(&rules)

	for _, rule := range rules {
		// Get average latency in time window
		var avgLatency float64
		timeAgo := time.Now().Add(-time.Duration(rule.TimeWindow) * time.Minute)

		s.db.Model(&models.Execution{}).
			Select("AVG(response_time_ms)").
			Joins("JOIN requests ON requests.id = executions.request_id").
			Joins("JOIN collections ON collections.id = requests.collection_id").
			Where("collections.workspace_id = ? AND executions.timestamp >= ?", workspaceID, timeAgo).
			Row().Scan(&avgLatency)

		if avgLatency > rule.Threshold {
			// Trigger alert
			s.TriggerAlert(rule.ID, workspaceID, "critical",
				fmt.Sprintf("Average latency (%.2fms) exceeded threshold (%.2fms)", avgLatency, rule.Threshold),
				map[string]interface{}{
					"current_value": avgLatency,
					"threshold":     rule.Threshold,
					"time_window":   rule.TimeWindow,
				})
		}
	}

	return nil
}

// CheckErrorRate checks if error rate exceeds threshold
func (s *AlertingService) CheckErrorRate(workspaceID uuid.UUID) error {
	var rules []AlertRule
	s.db.Where("workspace_id = ? AND condition = 'error_rate' AND enabled = true", workspaceID).Find(&rules)

	for _, rule := range rules {
		timeAgo := time.Now().Add(-time.Duration(rule.TimeWindow) * time.Minute)

		var totalCount int64
		var errorCount int64

		// Get total requests
		s.db.Model(&models.Execution{}).
			Joins("JOIN requests ON requests.id = executions.request_id").
			Joins("JOIN collections ON collections.id = requests.collection_id").
			Where("collections.workspace_id = ? AND executions.timestamp >= ?", workspaceID, timeAgo).
			Count(&totalCount)

		// Get error requests (status >= 400)
		s.db.Model(&models.Execution{}).
			Joins("JOIN requests ON requests.id = executions.request_id").
			Joins("JOIN collections ON collections.id = requests.collection_id").
			Where("collections.workspace_id = ? AND executions.timestamp >= ? AND executions.status_code >= 400", workspaceID, timeAgo).
			Count(&errorCount)

		if totalCount > 0 {
			errorRate := float64(errorCount) / float64(totalCount) * 100

			if errorRate > rule.Threshold {
				s.TriggerAlert(rule.ID, workspaceID, "critical",
					fmt.Sprintf("Error rate (%.2f%%) exceeded threshold (%.2f%%)", errorRate, rule.Threshold),
					map[string]interface{}{
						"error_count": errorCount,
						"total_count": totalCount,
						"error_rate":  errorRate,
						"threshold":   rule.Threshold,
						"time_window": rule.TimeWindow,
					})
			}
		}
	}

	return nil
}

// TriggerAlert creates and sends an alert
func (s *AlertingService) TriggerAlert(ruleID, workspaceID uuid.UUID, severity, message string, metadata map[string]interface{}) error {
	metadataJSON, _ := json.Marshal(metadata)

	alert := Alert{
		ID:          uuid.New(),
		RuleID:      ruleID,
		WorkspaceID: workspaceID,
		Severity:    severity,
		Message:     message,
		TriggeredAt: time.Now(),
		Status:      "active",
		Metadata:    string(metadataJSON),
	}

	if err := s.db.Create(&alert).Error; err != nil {
		return err
	}

	// Get rule to determine notification channel
	var rule AlertRule
	if err := s.db.First(&rule, ruleID).Error; err != nil {
		return err
	}

	// Send notification based on channel
	switch rule.NotificationChannel {
	case "slack":
		return s.SendSlackNotification(&alert, &rule)
	case "email":
		return s.SendEmailNotification(&alert, &rule)
	case "pagerduty":
		return s.SendPagerDutyNotification(&alert, &rule)
	}

	return nil
}

// SendSlackNotification sends alert to Slack
func (s *AlertingService) SendSlackNotification(alert *Alert, rule *AlertRule) error {
	// Implementation would use Slack webhook
	// For now, just log
	fmt.Printf("SLACK ALERT: [%s] %s\n", alert.Severity, alert.Message)
	return nil
}

// SendEmailNotification sends alert via email
func (s *AlertingService) SendEmailNotification(alert *Alert, rule *AlertRule) error {
	// Implementation would use SMTP or email service
	fmt.Printf("EMAIL ALERT: [%s] %s\n", alert.Severity, alert.Message)
	return nil
}

// SendPagerDutyNotification sends alert to PagerDuty
func (s *AlertingService) SendPagerDutyNotification(alert *Alert, rule *AlertRule) error {
	// Implementation would use PagerDuty API
	fmt.Printf("PAGERDUTY ALERT: [%s] %s\n", alert.Severity, alert.Message)
	return nil
}

// AcknowledgeAlert marks an alert as acknowledged
func (s *AlertingService) AcknowledgeAlert(alertID uuid.UUID) error {
	return s.db.Model(&Alert{}).Where("id = ?", alertID).Update("status", "acknowledged").Error
}

// ResolveAlert marks an alert as resolved
func (s *AlertingService) ResolveAlert(alertID uuid.UUID) error {
	now := time.Now()
	return s.db.Model(&Alert{}).Where("id = ?", alertID).Updates(map[string]interface{}{
		"status":      "resolved",
		"resolved_at": now,
	}).Error
}

// GetActiveAlerts gets all active alerts for a workspace
func (s *AlertingService) GetActiveAlerts(workspaceID uuid.UUID) ([]Alert, error) {
	var alerts []Alert
	err := s.db.Where("workspace_id = ? AND status = 'active'", workspaceID).
		Order("triggered_at DESC").
		Find(&alerts).Error
	return alerts, err
}
