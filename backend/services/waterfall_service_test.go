package services

import (
	"testing"
	"time"

	"backend/models"

	"github.com/google/uuid"
)

func TestWaterfallService_GenerateWaterfall_NotFound(t *testing.T) {
	db, err := openTestSQLite()
	if err != nil {
		t.Fatalf("openTestSQLite: %v", err)
	}
	svc := NewWaterfallService(db)
	_, err = svc.GenerateWaterfall(uuid.New())
	if err == nil {
		t.Fatal("expected error for missing trace")
	}
}

func TestWaterfallService_GenerateWaterfall_NoRootSpan(t *testing.T) {
	db, err := openTestSQLite()
	if err != nil {
		t.Fatalf("openTestSQLite: %v", err)
	}
	wsID := uuid.New()
	tr := models.Trace{
		ID: uuid.New(), WorkspaceID: wsID, ServiceName: "svc",
		StartTime: time.Now(), EndTime: time.Now(), Status: "success",
	}
	db.Create(&tr)
	// Span with parent (no root)
	parentID := uuid.New()
	db.Create(&models.Span{
		ID: uuid.New(), TraceID: tr.ID, ParentSpanID: &parentID,
		OperationName: "op", ServiceName: "svc", StartTime: time.Now(), DurationMs: 1, Status: "ok",
	})

	svc := NewWaterfallService(db)
	_, err = svc.GenerateWaterfall(tr.ID)
	if err == nil {
		t.Fatal("expected error when no root span")
	}
}

func TestWaterfallService_GenerateWaterfall_Success(t *testing.T) {
	db, err := openTestSQLite()
	if err != nil {
		t.Fatalf("openTestSQLite: %v", err)
	}
	wsID := uuid.New()
	start := time.Now()
	tr := models.Trace{
		ID: uuid.New(), WorkspaceID: wsID, ServiceName: "api",
		StartTime: start, EndTime: start, Status: "success",
	}
	db.Create(&tr)
	rootID := uuid.New()
	db.Create(&models.Span{
		ID: rootID, TraceID: tr.ID, ParentSpanID: nil,
		OperationName: "GET /api", ServiceName: "api", StartTime: start, DurationMs: 50, Status: "ok",
	})
	childID := uuid.New()
	db.Create(&models.Span{
		ID: childID, TraceID: tr.ID, ParentSpanID: &rootID,
		OperationName: "query", ServiceName: "db", StartTime: start.Add(5 * time.Millisecond), DurationMs: 30, Status: "ok",
	})

	svc := NewWaterfallService(db)
	node, err := svc.GenerateWaterfall(tr.ID)
	if err != nil {
		t.Fatalf("GenerateWaterfall: %v", err)
	}
	if node.SpanID != rootID || node.Name != "GET /api" || node.ServiceName != "api" {
		t.Errorf("root node = %+v", node)
	}
	if node.Depth != 0 {
		t.Errorf("root depth = %d", node.Depth)
	}
	if len(node.Children) != 1 {
		t.Fatalf("expected 1 child, got %d", len(node.Children))
	}
	child := node.Children[0]
	if child.SpanID != childID || child.Name != "query" || child.ServiceName != "db" {
		t.Errorf("child node = %+v", child)
	}
	if child.Depth != 1 {
		t.Errorf("child depth = %d", child.Depth)
	}
}
