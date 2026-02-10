package services

import (
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// --- Helper for Mock DB Setup ---

func setupTestDBMock(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherRegexp))
	require.NoError(t, err)

	gormDB, err := gorm.Open(postgres.New(postgres.Config{
		Conn: db,
	}), &gorm.Config{})
	require.NoError(t, err)

	return gormDB, mock
}

// --- Tests ---

func TestNewMockService(t *testing.T) {
	db, _ := setupTestDBMock(t)
	service := NewMockService(db)

	assert.NotNil(t, service)
	assert.NotNil(t, service.traceService)
	assert.Equal(t, db, service.db)
}

func TestMockService_GenerateFromTrace(t *testing.T) {
	db, mock := setupTestDBMock(t)
	service := NewMockService(db)

	workspaceID := uuid.New()
	userID := uuid.New()
	traceID := uuid.New()
	tagsJSON := `{"http.method": "GET", "http.url": "/api/users", "http.status_code": 200, "http.response.body": "{\"id\": 1}"}`

	// 1. FIRST Access Check (called by MockService)
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 2. Trace Retrieval (called by TraceService.GetTraceDetails)
	mock.ExpectQuery(`(?i)SELECT \* FROM "traces" WHERE .*id.* = \$1`).
		WithArgs(traceID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id"}).AddRow(traceID, workspaceID))

	// 3. SECOND Access Check (called internally by TraceService.GetTraceDetails)
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 4. Span Retrieval (called by TraceService.GetTraceDetails)
	mock.ExpectQuery(`(?i)SELECT \* FROM "spans" WHERE trace_id = \$1`).
		WithArgs(traceID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "operation_name", "duration_ms", "tags"}).
			AddRow(uuid.New(), "GetUser", 50.0, tagsJSON))

	// 5. Mock Insertion
	mock.ExpectBegin()
	mock.ExpectQuery(`(?i)INSERT INTO "mocks"`).
		WithArgs(workspaceID, "GetUser Mock", sqlmock.AnyArg(), "GET", "/api/users", "{\"id\": 1}", "{}", 200, 50, true, &traceID, sqlmock.AnyArg(), sqlmock.AnyArg(), nil).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	mocks, err := service.GenerateFromTrace(workspaceID, userID, traceID)
	require.NoError(t, err)
	require.Len(t, mocks, 1)
	assert.Equal(t, "GET", mocks[0].Method)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestMockService_GetAll(t *testing.T) {
	db, mock := setupTestDBMock(t)
	service := NewMockService(db)

	workspaceID := uuid.New()
	userID := uuid.New()

	// 1. Access Check
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 2. Fetch Mocks
	mock.ExpectQuery(`(?i)SELECT \* FROM "mocks" WHERE workspace_id = \$1`).
		WithArgs(workspaceID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "name"}).
			AddRow(uuid.New(), "Mock 1").
			AddRow(uuid.New(), "Mock 2"))

	results, err := service.GetAll(workspaceID, userID)
	require.NoError(t, err)
	assert.Len(t, results, 2)
}

func TestMockService_Update(t *testing.T) {
	db, mock := setupTestDBMock(t)
	service := NewMockService(db)

	mockID := uuid.New()
	workspaceID := uuid.New()
	userID := uuid.New()
	updates := map[string]interface{}{"status_code": 500}

	// 1. Fetch original Mock
	mock.ExpectQuery(`(?i)SELECT \* FROM "mocks" WHERE .*id.* = \$1`).
		WithArgs(mockID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id"}).AddRow(mockID, workspaceID))

	// 2. Access Check
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 3. Update - Matches: UPDATE "mocks" SET "status_code"=$1,"updated_at"=$2 WHERE "mocks"."deleted_at" IS NULL AND "id" = $3
	mock.ExpectBegin()
	mock.ExpectExec(`(?i)UPDATE "mocks" SET "status_code"=\$1,"updated_at"=\$2 WHERE .*id.* = \$3`).
		WithArgs(500, sqlmock.AnyArg(), mockID).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	updatedMock, err := service.Update(mockID, userID, updates)
	require.NoError(t, err)
	assert.NotNil(t, updatedMock)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestMockService_Delete(t *testing.T) {
	db, mock := setupTestDBMock(t)
	service := NewMockService(db)

	mockID := uuid.New()
	workspaceID := uuid.New()
	userID := uuid.New()

	// 1. Fetch original Mock
	mock.ExpectQuery(`(?i)SELECT \* FROM "mocks" WHERE .*id.* = \$1`).
		WithArgs(mockID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id"}).AddRow(mockID, workspaceID))

	// 2. Access Check
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 3. Delete - Matches: UPDATE "mocks" SET "deleted_at"=$1 WHERE "mocks"."id" = $2 AND "mocks"."deleted_at" IS NULL
	mock.ExpectBegin()
	mock.ExpectExec(`(?i)UPDATE "mocks" SET "deleted_at"=\$1 WHERE .*id.* = \$2`).
		WithArgs(sqlmock.AnyArg(), mockID).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	err := service.Delete(mockID, userID)
	require.NoError(t, err)
	assert.NoError(t, mock.ExpectationsWereMet())
}
