/*
Package services contains the business logic layer for the application.
This file implements the AuditService, which provides comprehensive audit logging
for security and compliance. It logs all user actions (create, update, delete, execute, view)
across resources like requests, traces, workspaces, etc., including metadata like IP,
user agent, and success/failure status. It also includes anomaly detection for unusual
access patterns, such as high activity or multi-IP access, enhancing security monitoring.
*/
package services

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// AuditLog represents a single audit entry in the system.
type AuditLog struct {
	ID           uuid.UUID `gorm:"type:uuid;primary_key"` // Unique ID for this log
	WorkspaceID  uuid.UUID `gorm:"type:uuid;not null"`    // Workspace associated with this action
	UserID       uuid.UUID `gorm:"type:uuid;not null"`    // User performing the action
	Action       string    `gorm:"not null"`              // Type of action: create, update, delete, execute, view
	ResourceType string    `gorm:"not null"`              // Resource type: request, trace, workspace, etc.
	ResourceID   uuid.UUID `gorm:"type:uuid"`             // Optional: the specific resource affected
	Changes      string    `gorm:"type:jsonb"`            // JSON string representing changes (before/after) for updates
	IPAddress    string    // IP address of the user
	UserAgent    string    // Browser / client information
	Success      bool      `gorm:"default:true"` // Whether the action succeeded
	ErrorMessage string    // Error message if the action failed
	CreatedAt    time.Time // Timestamp of the action
}

// AuditService provides methods to create and query audit logs.
type AuditService struct {
	db *gorm.DB
}

// NewAuditService initializes a new AuditService with the given database connection.
func NewAuditService(db *gorm.DB) *AuditService {
	return &AuditService{db: db}
}

// Log creates an audit log entry

/*
Parameters:
- workspaceID: the workspace where the action occurred
- userID: the user performing the action
- resourceID: the ID of the resource affected
- action: type of action (create, update, delete, etc.)
- resourceType: type of resource (request, trace, workspace, etc.)
- ipAddress: IP address of the user
- userAgent: client/browser details
- changes: map of changes made (before/after)
- success: whether the action succeeded
- errorMsg: error message if the action failed
*/
func (s *AuditService) Log(workspaceID, userID, resourceID uuid.UUID, action, resourceType, ipAddress, userAgent string, changes map[string]interface{}, success bool, errorMsg string) error {
	// Convert changes map to JSON string
	changesJSON, _ := json.Marshal(changes)

	// Create an AuditLog struct
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
	// Insert into database
	return s.db.Create(&log).Error
}

// GetLogs retrieves audit logs with filters
/*Parameters:
- workspaceID: filter logs by workspace
- filters: optional map with keys like "user_id", "action", "resource_type"
- limit: maximum number of logs to return
- offset: skip first N logs*/
func (s *AuditService) GetLogs(workspaceID uuid.UUID, filters map[string]interface{}, limit, offset int) ([]AuditLog, error) {
	var logs []AuditLog
	// Start query filtered by workspace
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
	// Order by most recent logs, apply limit and offset
	err := query.Order("created_at DESC").Limit(limit).Offset(offset).Find(&logs).Error
	return logs, err
}

// DetectAnomalies detects unusual access patterns
/*Example anomalies:
- Very high activity in a short time
- Access from multiple IP addresses
- Multiple failed actions*/
func (s *AuditService) DetectAnomalies(workspaceID, userID uuid.UUID) ([]string, error) {
	anomalies := []string{}

	// Check for rapid successive actions (more than 100 in 5 minutes)
	var count int64
	s.db.Model(&AuditLog{}).
		Where("workspace_id = ? AND user_id = ? AND created_at > ?", workspaceID, userID, time.Now().Add(-5*time.Minute)).
		Count(&count)

	if count > 100 {
		anomalies = append(anomalies, "Unusually high activity (100+ actions in 5 minutes)")
	}

	// Check for access from multiple IPs (more than 5 IPs in 1 hour)
	var ips []string
	s.db.Model(&AuditLog{}).
		Where("workspace_id = ? AND user_id = ? AND created_at > ?", workspaceID, userID, time.Now().Add(-1*time.Hour)).
		Distinct("ip_address").
		Pluck("ip_address", &ips)

	if len(ips) > 5 {
		anomalies = append(anomalies, "Access from multiple IP addresses (5+ IPs in 1 hour)")
	}

	// Check for multiple failed actions (more than 10 failures in 10 minutes)
	var failedCount int64
	s.db.Model(&AuditLog{}).
		Where("workspace_id = ? AND user_id = ? AND success = false AND created_at > ?", workspaceID, userID, time.Now().Add(-10*time.Minute)).
		Count(&failedCount)

	if failedCount > 10 {
		anomalies = append(anomalies, "Multiple failed actions (10+ failures in 10 minutes)")
	}

	return anomalies, nil
}
