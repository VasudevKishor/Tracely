package services

import (
	"testing"
	"time"

	"backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

func testDB(t *testing.T) *gorm.DB {
	db, err := openTestSQLite()
	if err != nil {
		t.Fatalf("openTestSQLite: %v", err)
	}
	return db
}

func TestTraceService_CreateTrace(t *testing.T) {
	db := testDB(t)
	svc := NewTraceService(db)
	wsID := uuid.New()
	tr, err := svc.CreateTrace(wsID, "svc1", "success")
	if err != nil {
		t.Fatalf("CreateTrace: %v", err)
	}
	if tr.ID == uuid.Nil {
		t.Error("expected non-nil trace ID")
	}
	if tr.WorkspaceID != wsID || tr.ServiceName != "svc1" || tr.Status != "success" {
		t.Errorf("trace fields wrong: %+v", tr)
	}
}

func TestTraceService_AddSpan(t *testing.T) {
	db := testDB(t)
	svc := NewTraceService(db)
	wsID := uuid.New()
	tr, _ := svc.CreateTrace(wsID, "svc1", "success")
	span, err := svc.AddSpan(tr.ID, nil, "op1", "svc1", 10.5, nil, nil)
	if err != nil {
		t.Fatalf("AddSpan: %v", err)
	}
	if span.ID == uuid.Nil {
		t.Error("expected non-nil span ID")
	}
	if span.TraceID != tr.ID || span.OperationName != "op1" || span.DurationMs != 10.5 {
		t.Errorf("span fields wrong: %+v", span)
	}
}

func TestTraceService_GetTraces_AccessDenied(t *testing.T) {
	db := testDB(t)
	svc := NewTraceService(db)
	wsID := uuid.New()
	userID := uuid.New()
	// No workspace member -> access denied
	_, total, err := svc.GetTraces(wsID, userID, "", nil, nil, 10, 0)
	if err == nil {
		t.Fatal("expected access denied error")
	}
	if err.Error() != "access denied" {
		t.Errorf("err = %v", err)
	}
	if total != 0 {
		t.Errorf("total = %d", total)
	}
}

func TestTraceService_GetTraces_Success(t *testing.T) {
	db := testDB(t)
	// Create user, workspace, membership so HasAccess is true
	userID := uuid.New()
	wsID := uuid.New()
	db.Create(&models.User{ID: userID, Email: "u@test.com", Password: "x", Name: "U"})
	db.Create(&models.Workspace{ID: wsID, Name: "WS", OwnerID: userID})
	db.Create(&models.WorkspaceMember{ID: uuid.New(), WorkspaceID: wsID, UserID: userID, Role: "admin"})

	svc := NewTraceService(db)
	tr, _ := svc.CreateTrace(wsID, "svc1", "success")
	if tr.ID == uuid.Nil {
		t.Fatal("trace not created")
	}

	traces, total, err := svc.GetTraces(wsID, userID, "", nil, nil, 10, 0)
	if err != nil {
		t.Fatalf("GetTraces: %v", err)
	}
	if total != 1 || len(traces) != 1 {
		t.Errorf("total=%d len=%d", total, len(traces))
	}
	if traces[0].ServiceName != "svc1" {
		t.Errorf("ServiceName = %s", traces[0].ServiceName)
	}
}

func TestTraceService_GetTraceDetails_AccessDenied(t *testing.T) {
	db := testDB(t)
	userID := uuid.New()
	wsID := uuid.New()
	tr, _ := NewTraceService(db).CreateTrace(wsID, "svc1", "success")
	// User not member
	_, _, err := NewTraceService(db).GetTraceDetails(tr.ID, userID)
	if err == nil {
		t.Fatal("expected access denied")
	}
}

func TestTraceService_GetCriticalPath(t *testing.T) {
	db := testDB(t)
	userID := uuid.New()
	wsID := uuid.New()
	db.Create(&models.User{ID: userID, Email: "u@test.com", Password: "x", Name: "U"})
	db.Create(&models.Workspace{ID: wsID, Name: "WS", OwnerID: userID})
	db.Create(&models.WorkspaceMember{ID: uuid.New(), WorkspaceID: wsID, UserID: userID, Role: "admin"})

	svc := NewTraceService(db)
	tr, _ := svc.CreateTrace(wsID, "api", "success")
	root, _ := svc.AddSpan(tr.ID, nil, "root", "api", 5, nil, nil)
	child, _ := svc.AddSpan(tr.ID, &root.ID, "child", "db", 10, nil, nil)

	path, err := svc.GetCriticalPath(tr.ID, userID)
	if err != nil {
		t.Fatalf("GetCriticalPath: %v", err)
	}
	// Critical path should be root -> child (longest chain)
	if len(path) != 2 {
		t.Errorf("critical path len = %d; want 2", len(path))
	}
	if path[0].ID != root.ID || path[1].ID != child.ID {
		t.Errorf("path = %v", path)
	}
}

func TestCalculateTotalDuration(t *testing.T) {
	now := time.Now()
	spans := []models.Span{
		{DurationMs: 10},
		{DurationMs: 20},
		{DurationMs: 5},
	}
	got := calculateTotalDuration(spans)
	if got != 35 {
		t.Errorf("calculateTotalDuration = %v; want 35", got)
	}
	_ = now
}
