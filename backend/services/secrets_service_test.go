package services

import (
	"testing"
	"time"

	"backend/tests"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupTestDBSecrets(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)

	gormDB, err := gorm.Open(postgres.New(postgres.Config{
		Conn: db,
	}), &gorm.Config{})
	require.NoError(t, err)

	return gormDB, mock
}

func TestNewSecretsService(t *testing.T) {
	tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, _ := setupTestDBSecrets(t)
	key := "test-encryption-key-32-characters"

	service := NewSecretsService(db, key)
	assert.NotNil(t, service)
	assert.Equal(t, db, service.db)
}

func TestSecretsService_CreateSecret(t *testing.T) {
	db, mock := setupTestDBSecrets(t) // Ensure this creates a fresh mock
	key := "test-encryption-key-32-characters"
	service := NewSecretsService(db, key)

	workspaceID := uuid.New()
	userID := uuid.New()
	secretKey := "test-key"
	value := "test-value"
	description := "test description"

	mock.ExpectBegin()
	// 1. Use a Regex that is very forgiving
	mock.ExpectQuery(`(?i)INSERT INTO "secrets"`).
		WithArgs(
			sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(),
			sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(),
			sqlmock.AnyArg(), sqlmock.AnyArg(), sqlmock.AnyArg(),
		).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow("5397a17a-03fd-49e3-8dd3-00d37728a622"))
	mock.ExpectCommit()

	// Execution
	secret, err := service.CreateSecret(workspaceID, userID, secretKey, value, description)

	// Assertions
	assert.NoError(t, err)
	assert.NotNil(t, secret)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestSecretsService_GetSecret(t *testing.T) {
	tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDBSecrets(t)
	key := "test-encryption-key-32-characters"
	service := NewSecretsService(db, key)

	secretID := uuid.New()
	workspaceID := uuid.New()
	plainValue := "test-value"
	encryptedValue, _ := service.encrypt(plainValue) // Encrypt properly for test

	// Mock find secret
	// Match the 3 arguments GORM sends: secretID, workspaceID, and the LIMIT (1)
	mock.ExpectQuery(`SELECT \* FROM "secrets" WHERE id = \$1 AND workspace_id = \$2 ORDER BY "secrets"\."id" LIMIT \$3`).
		WithArgs(secretID, workspaceID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "workspace_id", "key", "value", "description", "created_by", "created_at", "updated_at", "expires_at"}).
			AddRow(secretID, workspaceID, "test-key", encryptedValue, "desc", uuid.New(), time.Now(), time.Now(), nil))

	value, err := service.GetSecret(secretID, workspaceID)

	assert.NoError(t, err)
	assert.Equal(t, plainValue, value)

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestSecretsService_RotateSecret(t *testing.T) {
	tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDBSecrets(t)
	key := "test-encryption-key-32-characters"
	service := NewSecretsService(db, key)

	secretID := uuid.New()
	workspaceID := uuid.New()
	newValue := "new-test-value"

	// Mock update
	mock.ExpectBegin()
	// Updated regex to include updated_at and 4 total arguments
	mock.ExpectExec(`UPDATE "secrets" SET "value"=\$1,"updated_at"=\$2 WHERE id = \$3 AND workspace_id = \$4`).
		WithArgs(
			sqlmock.AnyArg(), // new encrypted value
			sqlmock.AnyArg(), // updated_at timestamp
			secretID,
			workspaceID,
		).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	err := service.RotateSecret(secretID, workspaceID, newValue)

	assert.NoError(t, err)

	assert.NoError(t, mock.ExpectationsWereMet())
}
