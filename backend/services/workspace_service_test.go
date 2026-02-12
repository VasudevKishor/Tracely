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
	// MUST be false because GORM preload order is non-deterministic
	mock.MatchExpectationsInOrder(false)

	service := NewWorkspaceService(db)

	ownerID := uuid.New()
	workspaceID := uuid.New()
	name := "Test Workspace"
	desc := "Testing description"
	wsType := "internal"
	isPublic := false
	accessType := "team"

	// 1. Expect Workspace Creation
	mock.ExpectBegin()
	mock.ExpectQuery(`(?i)INSERT INTO "workspaces"`).
		WithArgs(
			name,
			desc,
			ownerID,          // owner_id (Struct order)
			sqlmock.AnyArg(), // created_at
			sqlmock.AnyArg(), // updated_at
			nil,              // deleted_at
			wsType,
			isPublic,
			accessType,
		).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(workspaceID))
	mock.ExpectCommit()

	// 2. Expect Member Creation (Owner as Admin)
	mock.ExpectBegin()
	mock.ExpectQuery(`(?i)INSERT INTO "workspace_members"`).
		WithArgs(workspaceID, ownerID, "admin", sqlmock.AnyArg(), nil).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	// 3. Expect Main Workspace Fetch
	mock.ExpectQuery(`(?i)SELECT \* FROM "workspaces" WHERE .*id.* = \$1`).
		WithArgs(workspaceID, workspaceID, sqlmock.AnyArg()).
		WillReturnRows(sqlmock.NewRows([]string{
			"id", "name", "description", "type", "is_public", "access_type", "owner_id",
		}).AddRow(workspaceID, name, desc, wsType, isPublic, accessType, ownerID))

	// 4. Preload Members
	mock.ExpectQuery(`(?i)SELECT \* FROM "workspace_members" WHERE .*workspace_id.* = \$1`).
		WithArgs(workspaceID).
		WillReturnRows(sqlmock.NewRows([]string{"workspace_id", "user_id"}).AddRow(workspaceID, ownerID))

	// 5. Preload Users (Matched twice for Owner and Members.User)
	// We use a very broad regex '(?i)SELECT \* FROM "users" WHERE .*id.*'
	// to match both "=" and "IN" syntaxes.
	mock.ExpectQuery(`(?i)SELECT \* FROM "users" WHERE .*id.*`).
		WithArgs(ownerID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "email"}).AddRow(ownerID, "owner@test.com"))

	mock.ExpectQuery(`(?i)SELECT \* FROM "users" WHERE .*id.*`).
		WithArgs(ownerID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "email"}).AddRow(ownerID, "owner@test.com"))

	// EXECUTE
	result, err := service.Create(name, desc, wsType, isPublic, accessType, ownerID)

	// ASSERTIONS
	assert.NoError(t, err)
	if assert.NotNil(t, result) {
		assert.Equal(t, name, result.Name)
		assert.Equal(t, wsType, result.Type)
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
