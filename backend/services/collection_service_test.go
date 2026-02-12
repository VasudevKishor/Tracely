package services

import (
	"testing"

	"backend/tests"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupTestDBCollection(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)

	gormDB, err := gorm.Open(postgres.New(postgres.Config{
		Conn: db,
	}), &gorm.Config{})
	require.NoError(t, err)

	return gormDB, mock
}

func TestNewCollectionService(t *testing.T) {
	tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, _ := setupTestDBCollection(t)

	service := NewCollectionService(db)
	assert.NotNil(t, service)
	assert.Equal(t, db, service.db)
	assert.NotNil(t, service.workspaceService)
}

func TestCollectionService_Create_Success(t *testing.T) {

	tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)
	// ARRANGE - Set up test data
	db, mock := setupTestDBCollection(t)
	service := NewCollectionService(db)

	workspaceID := uuid.New()
	userID := uuid.New()
	name := "Test Collection"
	description := "Test Description"

	// 1.GORM calls count(*) for access checks. Use regex wildcard for deleted_at.
	mock.ExpectQuery(`SELECT count\(\*\) FROM "workspace_members" WHERE (.+)workspace_id = \$1 AND user_id = \$2`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 2. Since ID is auto-gen UUID, GORM uses RETURNING "id". Use ExpectQuery.
	mock.ExpectBegin()
	mock.ExpectQuery(`INSERT INTO "collections"`).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	collection, err := service.Create(workspaceID, name, description, userID)

	require.NoError(t, err) // require stops execution if nil to avoid panic
	assert.NotNil(t, collection)
	assert.Equal(t, name, collection.Name)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestCollectionService_GetAll_Success(t *testing.T) {
	tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDBCollection(t)
	service := NewCollectionService(db)

	workspaceID := uuid.New()
	userID := uuid.New()

	// Mock access check (count)
	mock.ExpectQuery(`SELECT count\(\*\) FROM "workspace_members" WHERE (.+)workspace_id = \$1 AND user_id = \$2`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

		// Mock get collections with soft-delete support
		// The log showed: SELECT * FROM "collections" WHERE workspace_id = $1 AND "collections"."deleted_at" IS NULL
	mock.ExpectQuery(`SELECT \* FROM "collections" WHERE workspace_id = \$1 AND "collections"\."deleted_at" IS NULL`).
		WithArgs(workspaceID).
		WillReturnRows(sqlmock.NewRows([]string{"id", "name", "description", "workspace_id"}).
			AddRow(uuid.New(), "Collection 1", "Desc 1", workspaceID))

	collections, err := service.GetAll(workspaceID, userID)

	assert.NoError(t, err)
	assert.Len(t, collections, 1)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestCollectionService_Update_Success(t *testing.T) {
	tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDBCollection(t)
	service := NewCollectionService(db)

	collectionID := uuid.New()
	userID := uuid.New()
	workspaceID := uuid.New()

	// 1. Get collection (Soft delete + Order by id + Limit 1)
	mock.ExpectQuery(`SELECT \* FROM "collections" WHERE "collections"."id" = \$1 AND "collections"."deleted_at" IS NULL (.+) LIMIT \$2`).
		WithArgs(collectionID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "name", "description", "workspace_id"}).
			AddRow(collectionID, "Old Name", "Old Desc", workspaceID))

	// 2. Access check
	mock.ExpectQuery(`SELECT count\(\*\) FROM "workspace_members" WHERE (.+)workspace_id = \$1 AND user_id = \$2`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// 3. Update
	mock.ExpectBegin()
	mock.ExpectExec(`UPDATE "collections" SET`).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	collection, err := service.Update(collectionID, userID, "New Name", "New Desc")

	assert.NoError(t, err)
	assert.NotNil(t, collection)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestCollectionService_Delete_Success(t *testing.T) {
	tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDBCollection(t)

	service := NewCollectionService(db)

	collectionID := uuid.New()
	userID := uuid.New()
	workspaceID := uuid.New()

	// Mock get collection
	// The log showed the ID check must include the deleted_at check for the initial find
	mock.ExpectQuery(`SELECT \* FROM "collections" WHERE "collections"\."id" = \$1 AND "collections"\."deleted_at" IS NULL ORDER BY "collections"\."id" LIMIT \$2`).
		WithArgs(collectionID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "name", "description", "workspace_id"}).
			AddRow(collectionID, "Test Collection", "Desc", workspaceID))

		// Replace the membership check mock with this:
	mock.ExpectQuery(`SELECT count\(\*\) FROM "workspace_members" WHERE \(workspace_id = \$1 AND user_id = \$2\) AND "workspace_members"\."deleted_at" IS NULL`).
		WithArgs(workspaceID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"count"}).AddRow(1))

	// Mock delete
	mock.ExpectBegin()
	mock.ExpectExec(`UPDATE "collections" SET "deleted_at"=\$1 WHERE "collections"\."id" = \$2 AND "collections"\."deleted_at" IS NULL`).
		WithArgs(sqlmock.AnyArg(), collectionID). // $1 is the timestamp, $2 is the ID
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	err := service.Delete(collectionID, userID)

	assert.NoError(t, err)

	assert.NoError(t, mock.ExpectationsWereMet())
}
