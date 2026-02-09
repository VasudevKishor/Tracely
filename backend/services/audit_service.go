package services

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// AuditLog represents an entry in the audit trail for workspace actions.
type AuditLog struct {
	ID           uuid.UUID `gorm:"type:uuid;primary_key"`
	WorkspaceID  uuid.UUID `gorm:"type:uuid;not null"`
	UserID       uuid.UUID `gorm:"type:uuid;not null"`
	Action       string    `gorm:"not null"` // create, update, delete, execute, view
	ResourceType string    `gorm:"not null"` // request, trace, workspace, etc.
	ResourceID   uuid.UUID `gorm:"type:uuid"`
	Changes      string    `gorm:"type:jsonb"` // Before/after for updates
	IPAddress    string
	UserAgent    string
	Success      bool `gorm:"default:true"`
	ErrorMessage string
	CreatedAt    time.Time
}

// AuditService provides business logic for recording and analyzing audit logs.
type AuditService struct {
	db *gorm.DB
}

// NewAuditService creates a new instance of AuditService.
func NewAuditService(db *gorm.DB) *AuditService {
	return &AuditService{db: db}
}

// Log creates a new audit log entry in the database.
func (s *AuditService) Log(workspaceID, userID, resourceID uuid.UUID, action, resourceType, ipAddress, userAgent string, changes map[string]interface{}, success bool, errorMsg string) error {
	changesJSON, _ := json.Marshal(changes)

	log := AuditLog{
		ID:           uuid.New(),
		WorkspaceID:  workspaceID,
		UserID:       userID,
		Action:       action,
		ResourceType: resourceType,
		ResourceID:   resourceID,
		Changes:      string(changesJSON),
		IPAddress:    ipAddress,
		UserAgent:    userAgent,
		Success:      success,
		ErrorMessage: errorMsg,
	}

	return s.db.Create(&log).Error
}

// GetLogs retrieves audit logs for a workspace with optional filters and pagination.
func (s *AuditService) GetLogs(workspaceID uuid.UUID, filters map[string]interface{}, limit, offset int) ([]AuditLog, error) {
	var logs []AuditLog
	query := s.db.Where("workspace_id = ?", workspaceID)

	if userID, ok := filters["user_id"].(uuid.UUID); ok {
		query = query.Where("user_id = ?", userID)
	}
	if action, ok := filters["action"].(string); ok {
		query = query.Where("action = ?", action)
	}
	if resourceType, ok := filters["resource_type"].(string); ok {
		query = query.Where("resource_type = ?", resourceType)
	}

	err := query.Order("created_at DESC").Limit(limit).Offset(offset).Find(&logs).Error
	return logs, err
}

// DetectAnomalies analyzes audit logs for a user to identify suspicious activity patterns.
func (s *AuditService) DetectAnomalies(workspaceID, userID uuid.UUID) ([]string, error) {
	anomalies := []string{}

	// Check for rapid successive actions (e.g., potential automated abuse)
	var count int64
	s.db.Model(&AuditLog{}).
		Where("workspace_id = ? AND user_id = ? AND created_at > ?", workspaceID, userID, time.Now().Add(-5*time.Minute)).
		Count(&count)

	if count > 100 {
		anomalies = append(anomalies, "Unusually high activity (100+ actions in 5 minutes)")
	}

	// Check for access from multiple IPs in a short window (e.g., potential session hijacking or shared accounts)
	var ips []string
	s.db.Model(&AuditLog{}).
		Where("workspace_id = ? AND user_id = ? AND created_at > ?", workspaceID, userID, time.Now().Add(-1*time.Hour)).
		Distinct("ip_address").
		Pluck("ip_address", &ips)

	if len(ips) > 5 {
		anomalies = append(anomalies, "Access from multiple IP addresses (5+ IPs in 1 hour)")
	}

	// Check for a high frequency of failed actions (e.g., potential brute force or misconfiguration)
	var failedCount int64
	s.db.Model(&AuditLog{}).
		Where("workspace_id = ? AND user_id = ? AND success = false AND created_at > ?", workspaceID, userID, time.Now().Add(-10*time.Minute)).
		Count(&failedCount)

	if failedCount > 10 {
		anomalies = append(anomalies, "Multiple failed actions (10+ failures in 10 minutes)")
	}

	return anomalies, nil
}
