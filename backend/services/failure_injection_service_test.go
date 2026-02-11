package services

import (
	"net/http"
	"testing"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

func failureInjectionTestDB(t *testing.T) *gorm.DB {
	db, err := openTestSQLite()
	if err != nil {
		t.Fatalf("openTestSQLite: %v", err)
	}
	return db
}

func TestFailureInjectionService_CreateRule(t *testing.T) {
	db := failureInjectionTestDB(t)
	svc := NewFailureInjectionService(db)
	wsID := uuid.New()
	config := map[string]interface{}{"status_code": 500, "message": "injected"}
	rule, err := svc.CreateRule(wsID, "test-rule", "error", 1.0, config)
	if err != nil {
		t.Fatalf("CreateRule: %v", err)
	}
	if rule.ID == uuid.Nil {
		t.Error("expected non-nil rule ID")
	}
	if rule.Type != "error" || rule.Probability != 1.0 {
		t.Errorf("rule = %+v", rule)
	}
}

func TestFailureInjectionService_InjectFailure_NoRules(t *testing.T) {
	db := failureInjectionTestDB(t)
	svc := NewFailureInjectionService(db)
	req, _ := http.NewRequest(http.MethodGet, "http://test/", nil)
	err := svc.InjectFailure(uuid.New(), req)
	if err != nil {
		t.Errorf("InjectFailure with no rules: %v", err)
	}
}
