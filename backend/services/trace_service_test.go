package services

import (
	"testing"

	"backend/models"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupTestDBTrace(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherRegexp))
	require.NoError(t, err)

	gormDB, err := gorm.Open(postgres.New(postgres.Config{
		Conn: db,
	}), &gorm.Config{})
	require.NoError(t, err)

	return gormDB, mock
}

func TestNewTraceService(t *testing.T) {
	db, _ := setupTestDBTrace(t)
	service := NewTraceService(db)

	assert.NotNil(t, service)
	assert.Equal(t, db, service.db)
}

func TestTraceService_CreateTrace(t *testing.T) {
	db, mock := setupTestDBTrace(t)
	service := NewTraceService(db)

	workspaceID := uuid.New()
	serviceName := "billing-api"
	status := "active"

	mock.ExpectBegin()
	// GORM is sending 9 args: workspace_id, service_name, span_count, total_duration_ms,
	// start_time, end_time, status, created_at, deleted_at
	mock.ExpectQuery(`INSERT INTO "traces" .* RETURNING "id"`).
		WithArgs(
			workspaceID,      // 1: workspace_id
			serviceName,      // 2: service_name
			0,                // 3: span_count
			0.0,              // 4: total_duration_ms
			sqlmock.AnyArg(), // 5: start_time
			sqlmock.AnyArg(), // 6: end_time
			status,           // 7: status
			sqlmock.AnyArg(), // 8: created_at
			nil,              // 9: deleted_at
		).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	trace, err := service.CreateTrace(workspaceID, serviceName, status)

	// Check error first to prevent panic
	require.NoError(t, err)
	require.NotNil(t, trace)
	assert.Equal(t, serviceName, trace.ServiceName)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestTraceService_GetCriticalPath(t *testing.T) {
	// No DB setup needed for logic-only tests
	service := &TraceService{}

	traceID := uuid.New()
	rootID := uuid.New()
	slowChildID := uuid.New()
	fastChildID := uuid.New()

	//
	spans := []models.Span{
		{ID: rootID, TraceID: traceID, DurationMs: 10, ParentSpanID: nil},
		{ID: slowChildID, TraceID: traceID, DurationMs: 100, ParentSpanID: &rootID}, // This is the bottleneck
		{ID: fastChildID, TraceID: traceID, DurationMs: 5, ParentSpanID: &rootID},
	}

	criticalPath := service.findCriticalPath(spans)

	assert.Len(t, criticalPath, 2)
	assert.Equal(t, rootID, criticalPath[0].ID)
	assert.Equal(t, slowChildID, criticalPath[1].ID)

	totalTime := calculateTotalDuration(criticalPath)
	assert.Equal(t, 110.0, totalTime)
}
