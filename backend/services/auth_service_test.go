package services

import (
	"testing"
	"time"

	"backend/tests"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupTestDB(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)

	gormDB, err := gorm.Open(postgres.New(postgres.Config{
		Conn: db,
	}), &gorm.Config{})
	require.NoError(t, err)

	return gormDB, mock
}

func TestNewAuthService(t *testing.T) {
	cfg := tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, _ := setupTestDB(t)

	service := NewAuthService(db, cfg)
	assert.NotNil(t, service)
	assert.Equal(t, db, service.db)
	assert.Equal(t, cfg, service.config)
}

func TestAuthService_Register_Success(t *testing.T) {
	cfg := tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDB(t)
	service := NewAuthService(db, cfg)

	email := "test@example.com"
	password := "password123"
	name := "Test User"
	userID := uuid.New()

	// User
	mock.ExpectQuery(`SELECT \* FROM "users" WHERE email = \$1`).
		WithArgs(email, 1).
		WillReturnRows(sqlmock.NewRows(nil)) // Return empty, user doesn't exist

	mock.ExpectBegin()
	mock.ExpectQuery(`INSERT INTO "users"`).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(userID))
	mock.ExpectCommit()

	// Refresh token
	mock.ExpectBegin()
	mock.ExpectQuery(`INSERT INTO "refresh_tokens"`).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	// Workspace
	mock.ExpectBegin()
	mock.ExpectQuery(`INSERT INTO "workspaces"`).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	// Workspace member
	mock.ExpectBegin()
	mock.ExpectQuery(`INSERT INTO "workspace_members"`).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	// User settings
	mock.ExpectBegin()
	mock.ExpectQuery(`INSERT INTO "user_settings"`).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	user, tokenPair, err := service.Register(email, password, name)

	require.NoError(t, err)
	require.NotNil(t, user)
	require.NotNil(t, tokenPair)

	assert.Equal(t, email, user.Email)
	assert.Equal(t, name, user.Name)
	assert.NotEmpty(t, tokenPair.AccessToken)
	assert.NotEmpty(t, tokenPair.RefreshToken)

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestAuthService_Login_Success(t *testing.T) {
	cfg := tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDB(t)

	service := NewAuthService(db, cfg)

	email := "test@example.com"
	password := "password123"
	hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	userID := uuid.New()

	// Mock find user
	mock.ExpectQuery(`SELECT \* FROM "users" WHERE email = \$1 AND "users"."deleted_at" IS NULL ORDER BY "users"."id" LIMIT \$2`).
		WithArgs(email, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "email", "password", "name", "deleted_at"}).
			AddRow(userID, email, string(hashedPassword), "Test User", nil))

	mock.ExpectBegin()

	mock.ExpectQuery(`INSERT INTO "refresh_tokens"`).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))

	mock.ExpectCommit()

	user, tokenPair, err := service.Login(email, password)

	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.Equal(t, email, user.Email)
	assert.NotNil(t, tokenPair)
	assert.NotEmpty(t, tokenPair.AccessToken)
	assert.NotEmpty(t, tokenPair.RefreshToken)

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestAuthService_Login_InvalidCredentials(t *testing.T) {
	cfg := tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDB(t)

	service := NewAuthService(db, cfg)

	email := "test@example.com"
	password := "wrongpassword"

	// Mock find user
	mock.ExpectQuery(
		`SELECT \* FROM "users" WHERE email = \$1 AND "users"."deleted_at" IS NULL ORDER BY "users"."id" LIMIT \$2`,
	).
		WithArgs(email, 1).
		WillReturnRows(sqlmock.NewRows([]string{
			"id", "email", "password", "name", "deleted_at",
		}).AddRow(uuid.New(), email, "hashed", "Test User", nil))

	_, _, err := service.Login(email, password)

	assert.Error(t, err)
	assert.Equal(t, "invalid credentials", err.Error())

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestAuthService_GenerateToken(t *testing.T) {
	cfg := tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, _ := setupTestDB(t)

	service := NewAuthService(db, cfg)

	userID := uuid.New()
	email := "test@example.com"

	token, err := service.GenerateToken(userID, email)

	assert.NoError(t, err)
	assert.NotEmpty(t, token)
}

func TestAuthService_ValidateToken_Valid(t *testing.T) {
	cfg := tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, _ := setupTestDB(t)

	service := NewAuthService(db, cfg)

	userID := uuid.New()
	email := "test@example.com"

	token, _ := service.GenerateToken(userID, email)

	claims, err := service.ValidateToken(token)

	assert.NoError(t, err)
	assert.NotNil(t, claims)
	assert.Equal(t, userID.String(), claims.UserID)
	assert.Equal(t, email, claims.Email)
}

func TestAuthService_ValidateToken_Invalid(t *testing.T) {
	cfg := tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, _ := setupTestDB(t)

	service := NewAuthService(db, cfg)

	_, err := service.ValidateToken("invalid.token.here")

	assert.Error(t, err)
}

func TestAuthService_GenerateRefreshToken(t *testing.T) {
	cfg := tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDB(t)

	service := NewAuthService(db, cfg)

	userID := uuid.New()

	// Mock create refresh token
	mock.ExpectBegin()
	mock.ExpectQuery(`INSERT INTO "refresh_tokens"`).
		WillReturnRows(sqlmock.NewRows([]string{"id"}).AddRow(uuid.New()))
	mock.ExpectCommit()

	token, err := service.GenerateRefreshToken(userID)

	assert.NoError(t, err)
	assert.NotEmpty(t, token)

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestAuthService_RefreshAccessToken_Success(t *testing.T) {
	cfg := tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDB(t)

	service := NewAuthService(db, cfg)

	userID := uuid.New()
	email := "test@example.com"
	refreshToken := "refresh-token-123"
	expiresAt := time.Now().Add(24 * time.Hour)

	// Mock find refresh token
	mock.ExpectQuery(`SELECT \* FROM "refresh_tokens" WHERE (.+)token = \$1 AND revoked_at IS NULL`).
		WithArgs(refreshToken, 1). // GORM adds LIMIT 1
		WillReturnRows(sqlmock.NewRows([]string{"id", "user_id", "token", "expires_at", "revoked_at"}).
			AddRow(uuid.New(), userID, refreshToken, expiresAt, nil))

	// Mock find user
	mock.ExpectQuery(`SELECT \* FROM "users" WHERE "users"."id" = \$1 AND "users"."deleted_at" IS NULL ORDER BY "users"."id" LIMIT \$2`).
		WithArgs(userID, 1).
		WillReturnRows(sqlmock.NewRows([]string{"id", "email", "password", "name", "deleted_at"}).
			AddRow(userID, email, "hashed", "Test User", nil))

	token, err := service.RefreshAccessToken(refreshToken)

	assert.NoError(t, err)
	assert.NotEmpty(t, token)

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestAuthService_RefreshAccessToken_Invalid(t *testing.T) {
	cfg := tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDB(t)

	service := NewAuthService(db, cfg)

	refreshToken := "invalid-refresh-token"

	// Mock no refresh token found
	mock.ExpectQuery(`SELECT \* FROM "refresh_tokens" WHERE (.+)token = \$1 AND revoked_at IS NULL`).
		WithArgs(refreshToken, 1).
		WillReturnRows(sqlmock.NewRows([]string{}))

	_, err := service.RefreshAccessToken(refreshToken)

	assert.Error(t, err)
	assert.Equal(t, "invalid refresh token", err.Error())

	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestAuthService_RevokeRefreshToken(t *testing.T) {
	cfg := tests.SetupTestEnvironment(t)
	defer tests.CleanupTestEnvironment(t)

	db, mock := setupTestDB(t)

	service := NewAuthService(db, cfg)

	refreshToken := "refresh-token-123"

	// Mock update
	mock.ExpectBegin()
	mock.ExpectExec(`UPDATE "refresh_tokens" SET "revoked_at"=\$1 WHERE token = \$2`).
		WithArgs(sqlmock.AnyArg(), refreshToken).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	err := service.RevokeRefreshToken(refreshToken)

	assert.NoError(t, err)

	assert.NoError(t, mock.ExpectationsWereMet())
}
