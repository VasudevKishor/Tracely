package services

import (
	"testing"
	"time"

	"backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

func monitoringTestDB(t *testing.T) *gorm.DB {
	db, err := openTestSQLite()
	if err != nil {
		t.Fatalf("openTestSQLite: %v", err)
	}
	return db
}

func TestMonitoringService_GetDashboard_AccessDenied(t *testing.T) {
	db := monitoringTestDB(t)
	svc := NewMonitoringService(db)
	_, err := svc.GetDashboard(uuid.New(), uuid.New(), "last_hour")
	if err == nil {
		t.Fatal("expected access denied")
	}
	if err.Error() != "access denied" {
		t.Errorf("err = %v", err)
	}
}

func TestMonitoringService_GetDashboard_Success(t *testing.T) {
	db := monitoringTestDB(t)
	userID := uuid.New()
	wsID := uuid.New()
	db.Create(&models.User{ID: userID, Email: "u@test.com", Password: "x", Name: "U"})
	db.Create(&models.Workspace{ID: wsID, Name: "WS", OwnerID: userID})
	db.Create(&models.WorkspaceMember{ID: uuid.New(), WorkspaceID: wsID, UserID: userID, Role: "admin"})

	svc := NewMonitoringService(db)
	dash, err := svc.GetDashboard(wsID, userID, "last_hour")
	if err != nil {
		t.Fatalf("GetDashboard: %v", err)
	}
	if dash == nil {
		t.Fatal("dashboard nil")
	}
	if dash.TotalRequests != 0 {
		t.Errorf("TotalRequests = %d", dash.TotalRequests)
	}
}

func TestMonitoringService_GetTopology_AccessDenied(t *testing.T) {
	db := monitoringTestDB(t)
	svc := NewMonitoringService(db)
	_, err := svc.GetTopology(uuid.New(), uuid.New())
	if err == nil {
		t.Fatal("expected access denied")
	}
}

func TestMonitoringService_GetTopology_Success(t *testing.T) {
	db := monitoringTestDB(t)
	userID := uuid.New()
	wsID := uuid.New()
	db.Create(&models.User{ID: userID, Email: "u@test.com", Password: "x", Name: "U"})
	db.Create(&models.Workspace{ID: wsID, Name: "WS", OwnerID: userID})
	db.Create(&models.WorkspaceMember{ID: uuid.New(), WorkspaceID: wsID, UserID: userID, Role: "admin"})

	tr := models.Trace{ID: uuid.New(), WorkspaceID: wsID, ServiceName: "api", StartTime: time.Now(), EndTime: time.Now(), Status: "ok"}
	db.Create(&tr)
	rootID := uuid.New()
	db.Create(&models.Span{ID: rootID, TraceID: tr.ID, OperationName: "r", ServiceName: "api", StartTime: time.Now(), DurationMs: 1, Status: "ok"})
	db.Create(&models.Span{ID: uuid.New(), TraceID: tr.ID, ParentSpanID: &rootID, OperationName: "c", ServiceName: "db", StartTime: time.Now(), DurationMs: 1, Status: "ok"})

	svc := NewMonitoringService(db)
	topo, err := svc.GetTopology(wsID, userID)
	if err != nil {
		t.Fatalf("GetTopology: %v", err)
	}
	nodes := topo["nodes"].([]map[string]string)
	edges := topo["edges"].([]map[string]string)
	if len(nodes) < 2 {
		t.Errorf("nodes len = %d", len(nodes))
	}
	if len(edges) < 1 {
		t.Errorf("edges len = %d", len(edges))
	}
}

func TestMonitoringService_GetServiceLatencies_AccessDenied(t *testing.T) {
	db := monitoringTestDB(t)
	svc := NewMonitoringService(db)
	_, err := svc.GetServiceLatencies(uuid.New(), uuid.New(), "last_hour")
	if err == nil {
		t.Fatal("expected access denied")
	}
}
