package services

import (
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupTestDBTracing(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	dbSQL, mock, err := sqlmock.New()
	assert.NoError(t, err)

	db, err := gorm.Open(postgres.New(postgres.Config{
		Conn: dbSQL,
	}), &gorm.Config{})
	assert.NoError(t, err)

	return db, mock
}

func TestTracingConfigService_UpdateConfig(t *testing.T) {
	db, mock := setupTestDBTracing(t)
	service := NewTracingConfigService(db)
	configID := uuid.New()
	workspaceID := uuid.New()
	userID := uuid.New()

	// 1. Initial Lookup
	// Log shows 3 args: ID, ID, and LIMIT 1
	mock.ExpectQuery(`(?i)SELECT \* FROM "service_tracing_configs" WHERE .*id.* = \$1.*id.* = \$2.*`).
		WithArgs(configID, configID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id"}).AddRow(configID, workspaceID))

	// 2. Access Check
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members"`).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 3. Perform Update
	mock.ExpectBegin()
	mock.ExpectExec(`(?i)UPDATE "service_tracing_configs"`).
		WithArgs(0.5, sqlmock.AnyArg(), configID).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	// 4. Reload after update
	// Matches the same 3-argument pattern
	mock.ExpectQuery(`(?i)SELECT \* FROM "service_tracing_configs" WHERE .*id.* = \$1.*id.* = \$2.*`).
		WithArgs(configID, configID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "sampling_rate"}).AddRow(configID, 0.5))

	updates := map[string]interface{}{"sampling_rate": 0.5}
	result, err := service.UpdateConfig(configID, userID, updates)

	assert.NoError(t, err)
	if assert.NotNil(t, result) {
		assert.Equal(t, 0.5, result.SamplingRate)
	}
	assert.NoError(t, mock.ExpectationsWereMet())
}
func TestTracingConfigService_ShouldSample(t *testing.T) {
	db, mock := setupTestDBTracing(t)
	service := NewTracingConfigService(db)
	workspaceID := uuid.New()

	t.Run("Sampling Disabled", func(t *testing.T) {
		mock.ExpectQuery(`(?i)SELECT \* FROM "service_tracing_configs" WHERE .*workspace_id.*service_name.*`).
			WithArgs(workspaceID, "auth-service", 1).
			WillReturnRows(sqlmock.NewRows([]string{"enabled", "sampling_rate"}).
				AddRow(false, 1.0))

		sampled := service.ShouldSample(workspaceID, "auth-service")
		assert.False(t, sampled)
	})

	t.Run("Sampling Enabled 100%", func(t *testing.T) {
		mock.ExpectQuery(`(?i)SELECT \* FROM "service_tracing_configs" WHERE .*workspace_id.*service_name.*`).
			WithArgs(workspaceID, "auth-service", 1).
			WillReturnRows(sqlmock.NewRows([]string{"enabled", "sampling_rate"}).
				AddRow(true, 1.0))

		sampled := service.ShouldSample(workspaceID, "auth-service")
		assert.True(t, sampled)
	})
}
