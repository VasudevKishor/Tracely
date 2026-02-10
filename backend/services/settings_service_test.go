package services

import (
	"testing"

	"backend/tests"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupTestDBSettings(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)

	gormDB, err := gorm.Open(postgres.New(postgres.Config{
		Conn: db,
	}), &gorm.Config{})
	require.NoError(t, err)

	return gormDB, mock
}

func TestNewSettingsService(t *testing.T) {
	tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, _ := setupTestDBSettings(t)

	service := NewSettingsService(db)
	assert.NotNil(t, service)
	assert.Equal(t, db, service.db)
}
