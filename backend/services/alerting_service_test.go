package services

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

func alertingTestDB(t *testing.T) *gorm.DB {
	db, err := openTestSQLite()
	if err != nil {
		t.Fatalf("openTestSQLite: %v", err)
	}
	return db
}

func TestAlertingService_CreateRule(t *testing.T) {
	db := alertingTestDB(t)
	svc := NewAlertingService(db)
	userID := uuid.New()
	wsID := uuid.New()
	rule, err := svc.CreateRule(userID, wsID, "high-latency", "latency_threshold", 500, 5, "slack")
	if err != nil {
		t.Fatalf("CreateRule: %v", err)
	}
	if rule.ID == uuid.Nil {
		t.Error("expected non-nil rule ID")
	}
	if rule.Name != "high-latency" || rule.Threshold != 500 || rule.TimeWindow != 5 {
		t.Errorf("rule = %+v", rule)
	}
}

func TestAlertingService_GetActiveAlerts_Empty(t *testing.T) {
	db := alertingTestDB(t)
	svc := NewAlertingService(db)
	alerts, err := svc.GetActiveAlerts(uuid.New())
	if err != nil {
		t.Fatalf("GetActiveAlerts: %v", err)
	}
	if len(alerts) != 0 {
		t.Errorf("expected 0 alerts, got %d", len(alerts))
	}
}

func TestAlertingService_AcknowledgeAlert(t *testing.T) {
	db := alertingTestDB(t)
	svc := NewAlertingService(db)
	ruleID := uuid.New()
	wsID := uuid.New()
	alert := Alert{ID: uuid.New(), RuleID: ruleID, WorkspaceID: wsID, Severity: "critical", Message: "test", TriggeredAt: time.Now(), Status: "active"}
	db.Create(&alert)
	err := svc.AcknowledgeAlert(alert.ID)
	if err != nil {
		t.Fatalf("AcknowledgeAlert: %v", err)
	}
	var a Alert
	db.First(&a, alert.ID)
	if a.Status != "acknowledged" {
		t.Errorf("status = %s", a.Status)
	}
}
