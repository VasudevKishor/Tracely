package services

import (
	"testing"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

func loadTestServiceDB(t *testing.T) *gorm.DB {
	db, err := openTestSQLite()
	if err != nil {
		t.Fatalf("openTestSQLite: %v", err)
	}
	return db
}

func TestLoadTestService_CreateLoadTest(t *testing.T) {
	db := loadTestServiceDB(t)
	svc := NewLoadTestService(db)
	wsID := uuid.New()
	userID := uuid.New()
	requestID := uuid.New()
	// CreateLoadTest starts a goroutine that will call Execute; we only assert the created record
	lt, err := svc.CreateLoadTest(wsID, requestID, userID, "test-run", 2, 10, 0)
	if err != nil {
		t.Fatalf("CreateLoadTest: %v", err)
	}
	if lt.ID == uuid.Nil {
		t.Error("expected non-nil load test ID")
	}
	if lt.Status != "pending" {
		t.Errorf("status = %s; want pending", lt.Status)
	}
	if lt.Name != "test-run" || lt.Concurrency != 2 || lt.TotalRequests != 10 {
		t.Errorf("load test = %+v", lt)
	}
}
