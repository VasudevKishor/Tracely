package services

import (
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupWaterfallTestDB(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	dbSQL, mock, err := sqlmock.New()
	assert.NoError(t, err)

	db, err := gorm.Open(postgres.New(postgres.Config{
		Conn: dbSQL,
	}), &gorm.Config{})
	assert.NoError(t, err)

	return db, mock
}

func TestWaterfallService_GenerateWaterfall(t *testing.T) {
	db, mock := setupWaterfallTestDB(t)
	service := NewWaterfallService(db)

	traceID := uuid.New()
	rootSpanID := uuid.New()
	childSpanID := uuid.New()
	now := time.Now()

	// 1. Prepare Mock Data
	// Root Span starts at T+0ms, duration 100ms
	// Child Span starts at T+20ms, duration 50ms
	traceRow := sqlmock.NewRows([]string{"id", "start_time"}).
		AddRow(traceID, now)

	spanRows := sqlmock.NewRows([]string{"id", "trace_id", "operation_name", "service_name", "start_time", "duration_ms", "parent_span_id", "tags"}).
		AddRow(rootSpanID, traceID, "GET /api/users", "gateway", now, 100, nil, `{"env":"prod"}`).
		AddRow(childSpanID, traceID, "SELECT users", "user-db", now.Add(20*time.Millisecond), 50, &rootSpanID, `{"db.table":"users"}`)

	// 2. Mock the DB Expectations
	// GORM Preload runs two queries: one for Trace, one for Spans
	mock.ExpectQuery(`(?i)SELECT \* FROM "traces" WHERE .*id.* = \$1`).
		WithArgs(traceID, 1).
		WillReturnRows(traceRow)

	mock.ExpectQuery(`(?i)SELECT \* FROM "spans" WHERE "spans"."trace_id" = \$1`).
		WithArgs(traceID).
		WillReturnRows(spanRows)

	// 3. Execute
	result, err := service.GenerateWaterfall(traceID)

	// 4. Assertions
	assert.NoError(t, err)
	assert.NotNil(t, result)

	// Verify Root Node
	assert.Equal(t, rootSpanID, result.SpanID)
	assert.Equal(t, int64(0), result.Offset) // Root should start at offset 0
	assert.Equal(t, 0, result.Depth)
	assert.Equal(t, "prod", result.Tags["env"])

	// Verify Child Node
	assert.Len(t, result.Children, 1)
	child := result.Children[0]
	assert.Equal(t, childSpanID, child.SpanID)
	assert.Equal(t, int64(20), child.Offset) // Offset should be 20ms
	assert.Equal(t, 1, child.Depth)
	assert.Equal(t, "users", child.Tags["db.table"])

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestWaterfallService_NoRootSpan(t *testing.T) {
	db, mock := setupWaterfallTestDB(t)
	service := NewWaterfallService(db)

	traceID := uuid.New()
	parentID := uuid.New()

	// 1. Mock the Trace - must return the ID we generated
	mock.ExpectQuery(`(?i)SELECT \* FROM "traces"`).
		WithArgs(traceID, 1). // GORM adds LIMIT 1
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(traceID))

	// 2. Mock the Spans - ensure the trace_id matches!
	// We provide a span that has a parent, so there is no "Root" (ParentSpanID == nil)
	mock.ExpectQuery(`(?i)SELECT \* FROM "spans"`).
		WithArgs(traceID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "trace_id", "parent_span_id"}).
			AddRow(uuid.New(), traceID, &parentID)) // trace_id MUST match traceID

	result, err := service.GenerateWaterfall(traceID)

	// Now GORM will succeed in the Preload, allowing our logic to reach the root check
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "no root span found")
	assert.Nil(t, result)
}
