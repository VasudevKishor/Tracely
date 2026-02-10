package services

import (
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupWorkspaceTestDB(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	dbSQL, mock, err := sqlmock.New()
	assert.NoError(t, err)

	db, err := gorm.Open(postgres.New(postgres.Config{
		Conn: dbSQL,
	}), &gorm.Config{})
	assert.NoError(t, err)

	return db, mock
}

func TestWorkspaceService_Create(t *testing.T) {
	db, mock := setupWorkspaceTestDB(t)
	service := NewWorkspaceService(db)

	ownerID := uuid.New()
	workspaceID := uuid.New()
	name := "Test Workspace"
	desc := "Testing description"

	// 1. Expect Workspace Creation - EXACTLY 6 ARGS
	mock.ExpectBegin()
	mock.ExpectQuery(`(?i)INSERT INTO "workspaces"`).
		WithArgs(
			name,             // 1
			desc,             // 2
			ownerID,          // 3
			sqlmock.AnyArg(), // 4 created_at
			sqlmock.AnyArg(), // 5 updated_at
			nil,              // 6 deleted_at
		).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(workspaceID))
	mock.ExpectCommit()

	// 2. Expect Member Creation
	mock.ExpectBegin()
	mock.ExpectQuery(`(?i)INSERT INTO "workspace_members"`).
		WithArgs(
			workspaceID,
			ownerID,
			"admin",
			sqlmock.AnyArg(),
			nil,
		).
		// CHANGE THIS LINE: Use a UUID instead of the integer 1
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	// 3. Expect Final Preloaded Fetch (The First() call)
	// Note: GORM uses (ID, 1) or (ID, ID, 1) depending on its mood.
	// Let's use AnyArg to be safe.
	mock.ExpectQuery(`(?i)SELECT \* FROM "workspaces" WHERE .*id.* = \$1`).
		WithArgs(workspaceID, sqlmock.AnyArg()).
		WillReturnRows(sqlmock.NewRows([]string{"id", "name", "owner_id"}).AddRow(workspaceID, name, ownerID))

	// Preload Owner
	mock.ExpectQuery(`(?i)SELECT \* FROM "users" WHERE "users"."id" = \$1`).
		WithArgs(ownerID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "email"}).AddRow(ownerID, "owner@test.com"))

	// Preload Members
	mock.ExpectQuery(`(?i)SELECT \* FROM "workspace_members" WHERE "workspace_members"."workspace_id" = \$1`).
		WithArgs(workspaceID).
		WillReturnRows(sqlmock.NewRows([]string{"workspace_id", "user_id"}).AddRow(workspaceID, ownerID))

	result, err := service.Create(name, desc, ownerID)

	assert.NoError(t, err)
	if assert.NotNil(t, result) {
		assert.Equal(t, name, result.Name)
	}
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestWorkspaceService_GetByID_AccessDenied(t *testing.T) {
	db, mock := setupWorkspaceTestDB(t)
	service := NewWorkspaceService(db)

	workspaceID := uuid.New()
	userID := uuid.New()

	// 1. Initial lookup to see if workspace exists
	mock.ExpectQuery(`(?i)SELECT \* FROM "workspaces" WHERE .*id.* = \$1`).
		WithArgs(workspaceID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(workspaceID))

	// 2. Access check (HasAccess)
	// We added .* at the start and end of the WHERE clause to handle GORM's
	// automatic (parentheses) and "deleted_at" IS NULL additions.
	mock.ExpectQuery(`(?i)SELECT count\(\*\) FROM "workspace_members" WHERE .*workspace_id = \$1 AND user_id = \$2.*`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(0))

	result, err := service.GetByID(workspaceID, userID)

	assert.Error(t, err)
	assert.Equal(t, "access denied", err.Error())
	assert.Nil(t, result)
}

func TestWorkspaceService_Delete_OnlyOwner(t *testing.T) {
	db, mock := setupWorkspaceTestDB(t)
	service := NewWorkspaceService(db)

	workspaceID := uuid.New()
	ownerID := uuid.New()
	intruderID := uuid.New()

	// Mock workspace where owner is someone else
	mock.ExpectQuery(`(?i)SELECT \* FROM "workspaces" WHERE .*id.* = \$1`).
		WithArgs(workspaceID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "owner_id"}).AddRow(workspaceID, ownerID))

	err := service.Delete(workspaceID, intruderID)

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "only owner can delete")
}
