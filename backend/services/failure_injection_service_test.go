package services

import (
	"encoding/json"
	"net/http"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupTestDBFailure(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	dbSQL, mock, err := sqlmock.New()
	assert.NoError(t, err) // Added 'err' here

	db, err := gorm.Open(postgres.New(postgres.Config{
		Conn: dbSQL,
	}), &gorm.Config{})
	assert.NoError(t, err) // Added 'err' here

	return db, mock
}

func TestFailureInjectionService_CreateRule(t *testing.T) {
	db, mock := setupTestDBFailure(t)
	service := NewFailureInjectionService(db)

	workspaceID := uuid.New()
	config := map[string]interface{}{"status_code": 500}

	mock.ExpectBegin()
	mock.ExpectExec(`(?i)INSERT INTO "failure_injection_rules"`).
		WithArgs(sqlmock.AnyArg(), workspaceID, "Test Rule", "error", 1.0, sqlmock.AnyArg(), true, sqlmock.AnyArg()).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	rule, err := service.CreateRule(workspaceID, "Test Rule", "error", 1.0, config)

	assert.NoError(t, err)
	assert.NotNil(t, rule)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestFailureInjectionService_InjectFailure_Latency(t *testing.T) {
	db, mock := setupTestDBFailure(t)
	service := NewFailureInjectionService(db)

	workspaceID := uuid.New()
	req, _ := http.NewRequest("GET", "http://api.test", nil)

	// Set a 200ms delay in config
	configJSON, _ := json.Marshal(map[string]interface{}{"delay_ms": 200})

	rows := sqlmock.NewRows([]string{"id", "workspace_id", "name", "type", "probability", "config", "enabled"}).
		AddRow(uuid.New(), workspaceID, "Slow API", "latency", 1.0, string(configJSON), true)

	mock.ExpectQuery(`(?i)SELECT \* FROM "failure_injection_rules"`).
		WithArgs(workspaceID).
		WillReturnRows(rows)

	start := time.Now()
	err := service.InjectFailure(workspaceID, req)
	duration := time.Since(start)

	assert.NoError(t, err)
	// Verify that the injectLatency actually caused a sleep
	assert.True(t, duration >= 200*time.Millisecond, "Execution should be delayed by at least 200ms")
}

func TestFailureInjectionService_InjectFailure_Unavailable(t *testing.T) {
	db, mock := setupTestDBFailure(t)
	service := NewFailureInjectionService(db)

	workspaceID := uuid.New()
	req, _ := http.NewRequest("GET", "http://api.test", nil)

	rows := sqlmock.NewRows([]string{"id", "workspace_id", "name", "type", "probability", "config", "enabled"}).
		AddRow(uuid.New(), workspaceID, "Down Rule", "unavailable", 1.0, "{}", true)

	mock.ExpectQuery(`(?i)SELECT \* FROM "failure_injection_rules"`).
		WithArgs(workspaceID).
		WillReturnRows(rows)

	err := service.InjectFailure(workspaceID, req)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "503 Service Unavailable")
}
