package services

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupTestDBRequest(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherRegexp))
	require.NoError(t, err)

	gormDB, err := gorm.Open(postgres.New(postgres.Config{
		Conn: db,
	}), &gorm.Config{})
	require.NoError(t, err)

	return gormDB, mock
}

func TestRequestService_Create(t *testing.T) {
	db, mock := setupTestDBRequest(t)
	service := NewRequestService(db)

	collectionID := uuid.New()
	workspaceID := uuid.New()
	userID := uuid.New()

	// 1. Fetch Collection
	mock.ExpectQuery(`(?i)SELECT \* FROM "collections" WHERE .*id.* = \$1`).
		WithArgs(collectionID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id"}).AddRow(collectionID, workspaceID))

	// 2. Permission Check
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 3. Insert Request
	mock.ExpectBegin()
	mock.ExpectQuery(`(?i)INSERT INTO "requests"`).
		WithArgs(sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), collectionID, sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg()).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	// 4. Update Collection Request Count
	mock.ExpectBegin()
	// Use .* to be flexible with the extra "updated_at" column GORM adds
	mock.ExpectExec(`(?i)UPDATE "collections" SET "request_count"=request_count \+ \$1.* WHERE .*id.* = \$3`).
		WithArgs(1, sqlmock.AnyArg(), collectionID).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	req, err := service.Create(collectionID, "Test Req", "GET", "http://api.com", "{}", "{}", "", "desc", userID)
	require.NoError(t, err)
	assert.NotNil(t, req)
}

func TestRequestService_Execute(t *testing.T) {
	db, mock := setupTestDBRequest(t)
	service := NewRequestService(db)

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok"}`))
	}))
	defer ts.Close()

	requestID := uuid.New()
	workspaceID := uuid.New()
	userID := uuid.New()

	// 2. Mock the DB queries
	collectionID := uuid.New() // Define this at the top of the func

	// First: Find the Request (Must include collection_id)
	mock.ExpectQuery(`(?i)SELECT \* FROM "requests"`).
		WithArgs(requestID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "collection_id", "url", "method"}).
			AddRow(requestID, collectionID, ts.URL, "POST"))

	// Second: GORM automatically fetches the Preloaded Collection
	mock.ExpectQuery(`(?i)SELECT \* FROM "collections"`).
		WithArgs(collectionID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id"}).
			AddRow(collectionID, workspaceID))

	// Third: Workspace Access Check
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 2. Insert Execution
	mock.ExpectBegin()
	mock.ExpectQuery(`(?i)INSERT INTO "executions"`).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	execution, err := service.Execute(requestID, userID, "", nil, uuid.New(), nil, nil)
	require.NoError(t, err)
	assert.Equal(t, 200, execution.StatusCode)
}

func TestRequestService_Update(t *testing.T) {
	db, mock := setupTestDBRequest(t)
	service := NewRequestService(db)

	requestID := uuid.New()
	workspaceID := uuid.New()
	userID := uuid.New()
	collectionID := uuid.New()

	// --- 1. THE LOOKUP PHASE ---
	// Before updating, the service calls GetByID which performs a SELECT with Preload
	mock.ExpectQuery(`(?i)SELECT \* FROM "requests"`).
		WithArgs(requestID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "collection_id", "url", "method"}).
			AddRow(requestID, collectionID, "http://api.com", "GET"))

	// GORM Preload of the Collection
	mock.ExpectQuery(`(?i)SELECT \* FROM "collections"`).
		WithArgs(collectionID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id"}).
			AddRow(collectionID, workspaceID))

	// --- 2. THE PERMISSION PHASE ---
	// Workspace access check happens before the transaction
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// --- 3. THE UPDATE PHASE ---
	mock.ExpectBegin()

	// GORM updates the association (Collection) because it's part of the struct
	mock.ExpectQuery(`(?i)INSERT INTO "collections"`).
		WithArgs(sqlmock.AnyArg(), sqlmock.AnyArg(), workspaceID, sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), collectionID).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(collectionID))

	// The actual Request UPDATE (must match all 4 arguments found in your logs)
	mock.ExpectExec(`(?i)UPDATE "requests"`).
		WithArgs(
			sqlmock.AnyArg(), // collection_id
			"New Name",       // name
			sqlmock.AnyArg(), // updated_at
			requestID,        // id (WHERE clause)
		).
		WillReturnResult(sqlmock.NewResult(1, 1))

	mock.ExpectCommit()

	// --- 4. EXECUTION ---
	_, err := service.Update(requestID, userID, map[string]interface{}{"name": "New Name"})

	// --- 5. ASSERTIONS ---
	assert.NoError(t, err)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestRequestService_Delete(t *testing.T) {
	db, mock := setupTestDBRequest(t)
	service := NewRequestService(db)

	requestID := uuid.New()
	userID := uuid.New()

	collectionID := uuid.New()
	workspaceID := uuid.New()

	// 1. Mock finding the Request (Crucial: include collection_id)
	mock.ExpectQuery(`(?i)SELECT \* FROM "requests"`).
		WithArgs(requestID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "collection_id"}).
			AddRow(requestID, collectionID))

	// 2. Mock finding the Preloaded Collection
	mock.ExpectQuery(`(?i)SELECT \* FROM "collections"`).
		WithArgs(collectionID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id"}).
			AddRow(collectionID, workspaceID))

	// 3. Mock the Access Check
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))
	// Mock Delete
	mock.ExpectBegin()
	mock.ExpectExec(`(?i)UPDATE "requests" SET "deleted_at"`).WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	err := service.Delete(requestID, userID)
	assert.NoError(t, err)
}

func TestRequestService_Execute_AccessDenied(t *testing.T) {
	db, mock := setupTestDBRequest(t)
	service := NewRequestService(db)

	requestID := uuid.New()
	collectionID := uuid.New()
	workspaceID := uuid.New()
	userID := uuid.New()

	// 1. Mock finding the request and its collection
	mock.ExpectQuery(`(?i)SELECT \* FROM "requests"`).
		WithArgs(requestID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "collection_id"}).AddRow(requestID, collectionID))

	mock.ExpectQuery(`(?i)SELECT \* FROM "collections"`).
		WithArgs(collectionID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id"}).AddRow(collectionID, workspaceID))

	// 2. MOCK ACCESS DENIED: Return 0 rows for workspace membership
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))

	// 3. Attempt execution
	execution, err := service.Execute(requestID, userID, "", nil, uuid.New(), nil, nil)

	// 4. Assertions
	assert.Error(t, err)
	assert.Equal(t, "access denied", err.Error())
	assert.Nil(t, execution) // No execution should be created

	assert.NoError(t, mock.ExpectationsWereMet())
}
