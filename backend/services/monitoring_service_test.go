package services

import (
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupTestDBMonitoring(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	dbSQL, mock, err := sqlmock.New()
	assert.NoError(t, err)

	db, err := gorm.Open(postgres.New(postgres.Config{
		Conn: dbSQL,
	}), &gorm.Config{})
	assert.NoError(t, err)

	return db, mock
}

func TestMonitoringService_GetDashboard(t *testing.T) {
	db, mock := setupTestDBMonitoring(t)
	service := NewMonitoringService(db)

	workspaceID := uuid.New()
	userID := uuid.New()

	// 1. Mock Workspace Access Check
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 2. Mock Total Requests Count (Added .* to handle soft delete and parens)
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "executions" WHERE .*timestamp.*`).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(100))

	// 3. Mock Successful Requests Count
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "executions" WHERE .*status_code >= 200.*status_code < 400.*`).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(80))

	// 4. Mock Average Response Time (AVG)
	// Important: This matches Row().Scan()
	mock.ExpectQuery(`(?i)SELECT AVG\(response_time_ms\) FROM "executions"`).
		WillReturnRows(sqlmock.NewRows([]string{"avg"}).AddRow(150.5))

	// 5. Mock Services List (Group By)
	mock.ExpectQuery(`(?i)SELECT \* FROM "traces" WHERE .*workspace_id.*GROUP BY "service_name"`).
		WithArgs(workspaceID, sqlmock.AnyArg()).
		WillReturnRows(sqlmock.NewRows([]string{"service_name"}).AddRow("auth-service"))

	// 6. Mock Individual Service Request Count
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "traces" WHERE .*workspace_id.*service_name.*`).
		WithArgs(workspaceID, "auth-service", sqlmock.AnyArg()).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(50))

	// --- Execute ---
	dashboard, err := service.GetDashboard(workspaceID, userID, "last_hour")

	// --- Assertions ---
	assert.NoError(t, err)
	assert.NotNil(t, dashboard)
	assert.Equal(t, int64(100), dashboard.TotalRequests)
	assert.Equal(t, int64(80), dashboard.SuccessfulRequests)
	assert.Equal(t, 20.0, dashboard.ErrorRate)
	assert.Equal(t, 150.5, dashboard.AvgResponseTimeMs)

	if assert.Len(t, dashboard.Services, 1) {
		assert.Equal(t, "auth-service", dashboard.Services[0]["name"])
	}
}

func TestMonitoringService_GetTopology(t *testing.T) {
	db, mock := setupTestDBMonitoring(t)
	service := NewMonitoringService(db)

	workspaceID := uuid.New()
	userID := uuid.New()
	traceID := uuid.New()
	parentSpanID := uuid.New()
	childSpanID := uuid.New()

	// 1. Mock Access Check
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 2. Mock Joins query to get all spans
	// Note: Added .* to handle the JOIN and WHERE complexity
	spanRows := sqlmock.NewRows([]string{"id", "trace_id", "service_name", "parent_span_id"}).
		AddRow(parentSpanID, traceID, "gateway", nil).
		AddRow(childSpanID, traceID, "user-service", parentSpanID)

	mock.ExpectQuery(`(?i)SELECT spans\.\* FROM "spans" .*JOIN traces.* WHERE .*workspace_id.*`).
		WithArgs(workspaceID).
		WillReturnRows(spanRows)

	// 3. THE FIX: Mock the lookup for the parent span
	// GORM's First() adds LIMIT 1, so we expect two arguments: [ID, 1]
	mock.ExpectQuery(`(?i)SELECT \* FROM "spans" WHERE .*id.* = \$1.*`).
		WithArgs(parentSpanID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "service_name"}).
			AddRow(parentSpanID, "gateway"))

	// --- Execute ---
	topology, err := service.GetTopology(workspaceID, userID)

	// --- Assertions ---
	assert.NoError(t, err)
	nodes := topology["nodes"].([]map[string]string)
	edges := topology["edges"].([]map[string]string)

	assert.Len(t, nodes, 2)
	if assert.Len(t, edges, 1) {
		assert.Equal(t, "gateway", edges[0]["source"])
		assert.Equal(t, "user-service", edges[0]["target"])
	}
}
