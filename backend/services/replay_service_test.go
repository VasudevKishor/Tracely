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

func setupTestDBReplay(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherRegexp))
	require.NoError(t, err)

	gormDB, err := gorm.Open(postgres.New(postgres.Config{
		Conn: db,
	}), &gorm.Config{})
	require.NoError(t, err)

	return gormDB, mock
}

// --- Tests ---

func TestNewReplayService(t *testing.T) {
	db, _ := setupTestDBReplay(t)
	service := NewReplayService(db)

	assert.NotNil(t, service)
	assert.NotNil(t, service.workspaceService)
	assert.NotNil(t, service.traceService)
}

func TestReplayService_CreateReplay(t *testing.T) {
	db, mock := setupTestDBReplay(t)
	service := NewReplayService(db)

	workspaceID := uuid.New()
	userID := uuid.New()
	sourceTraceID := uuid.New()
	config := map[string]interface{}{"delay": 100}

	// 1. Permission Check
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 2. Insert Replay
	// Use sqlmock.AnyArg() for all 12 fields to handle source_request_id and timestamps
	mock.ExpectBegin()
	mock.ExpectQuery(`(?i)INSERT INTO "replays"`).
		WithArgs(
			workspaceID,      // 1: workspace_id
			"Test Replay",    // 2: name
			"Desc",           // 3: description
			sourceTraceID,    // 4: source_trace_id
			sqlmock.AnyArg(), // 5: source_request_id (This was the missing one!)
			"staging",        // 6: target_environment
			`{"delay":100}`,  // 7: configuration
			"pending",        // 8: status
			userID,           // 9: created_by
			sqlmock.AnyArg(), // 10: created_at
			sqlmock.AnyArg(), // 11: updated_at
			sqlmock.AnyArg(), // 12: deleted_at
		).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	replay, err := service.CreateReplay(workspaceID, userID, "Test Replay", "Desc", sourceTraceID, "staging", config)

	require.NoError(t, err)
	assert.Equal(t, "Test Replay", replay.Name)
	assert.NoError(t, mock.ExpectationsWereMet())
}
func TestReplayService_GetReplay(t *testing.T) {
	db, mock := setupTestDBReplay(t)
	service := NewReplayService(db)

	replayID := uuid.New()
	workspaceID := uuid.New()
	userID := uuid.New()

	// 1. Fetch Replay
	mock.ExpectQuery(`(?i)SELECT \* FROM "replays" WHERE .*id.* = \$1`).
		WithArgs(replayID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id"}).AddRow(replayID, workspaceID))

	// 2. Permission Check
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	replay, err := service.GetReplay(replayID, userID)

	require.NoError(t, err)
	assert.Equal(t, replayID, replay.ID)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestReplayService_ExecuteReplay(t *testing.T) {
	db, mock := setupTestDBReplay(t)
	service := NewReplayService(db)

	workspaceID := uuid.New()
	userID := uuid.New()
	replayID := uuid.New()

	// Step 1 & 2: GetReplay (Fetch + Permission)
	mock.ExpectQuery(`(?i)SELECT \* FROM "replays" WHERE .*id.* = \$1`).
		WithArgs(replayID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id", "status"}).AddRow(replayID, workspaceID, "pending"))

	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// Step 3: Update status to "running"
	mock.ExpectBegin()
	mock.ExpectExec(`(?i)UPDATE "replays"`).
		WithArgs("running", sqlmock.AnyArg(), replayID).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	// Step 4: Create Trace
	mock.ExpectBegin()
	mock.ExpectQuery(`(?i)INSERT INTO "traces"`).
		WithArgs(workspaceID, "replay-service", 0, 0.0, sqlmock.AnyArg(), sqlmock.AnyArg(), "success", sqlmock.AnyArg(), nil).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	// Step 5: Insert Execution Result
	mock.ExpectBegin()
	mock.ExpectQuery(`(?i)INSERT INTO "replay_executions"`).
		WithArgs(sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg()).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	// Step 6: Update status to "completed"
	mock.ExpectBegin()
	mock.ExpectExec(`(?i)UPDATE "replays"`).
		WithArgs("completed", sqlmock.AnyArg(), replayID).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	execution, err := service.ExecuteReplay(replayID, userID)

	require.NoError(t, err)
	assert.Equal(t, "success", execution.Status)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestReplayService_GetResults(t *testing.T) {
	db, mock := setupTestDBReplay(t)
	service := NewReplayService(db)

	replayID := uuid.New()
	workspaceID := uuid.New()
	userID := uuid.New()

	// 1. GetReplay logic first
	mock.ExpectQuery(`(?i)SELECT \* FROM "replays" WHERE .*id.* = \$1`).
		WithArgs(replayID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id"}).AddRow(replayID, workspaceID))

	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 2. Fetch executions
	mock.ExpectQuery(`(?i)SELECT \* FROM "replay_executions" WHERE replay_id = \$1`).
		WithArgs(replayID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "status"}).
			AddRow(uuid.New(), "success").
			AddRow(uuid.New(), "failed"))

	results, err := service.GetResults(replayID, userID)

	require.NoError(t, err)
	assert.Len(t, results, 2)
	assert.NoError(t, mock.ExpectationsWereMet())
}

/*
The "Chain Reaction" in ExecuteReplay
Find the Script: It looks for the Replay record in the database.

ID Check: It asks the WorkspaceService if you are allowed to see it.

Status Change: It updates the status to "running".

New Recording: It tells the TraceService to start a new trace for this specific replay.

Save Results: It creates a ReplayExecution record with the final outcome.

Mission Complete: It updates the status to "completed".
*/
