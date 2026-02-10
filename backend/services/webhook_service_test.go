package services

import (
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func setupWebhookTestDB(t *testing.T) (*gorm.DB, sqlmock.Sqlmock) {
	dbSQL, mock, err := sqlmock.New()
	assert.NoError(t, err)

	db, err := gorm.Open(postgres.New(postgres.Config{
		Conn: dbSQL,
	}), &gorm.Config{})
	assert.NoError(t, err)

	return db, mock
}

func TestWebhookService_CreateWebhook(t *testing.T) {
	db, mock := setupWebhookTestDB(t)
	service := NewWebhookService(db)

	workspaceID := uuid.New()
	events := []string{"trace.created", "alert.triggered"}

	mock.ExpectBegin()
	mock.ExpectExec(`(?i)INSERT INTO "webhooks"`).
		WithArgs(sqlmock.AnyArg(), workspaceID, "Slack Bot", "https://slack.com/hook", "secret123", `["trace.created","alert.triggered"]`, true, sqlmock.AnyArg()).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	result, err := service.CreateWebhook(workspaceID, "Slack Bot", "https://slack.com/hook", "secret123", events)

	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, "Slack Bot", result.Name)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestWebhookService_TriggerWebhook(t *testing.T) {
	db, mock := setupWebhookTestDB(t)
	service := NewWebhookService(db)

	workspaceID := uuid.New()
	webhookID := uuid.New()
	eventType := "trace.created"
	payload := map[string]interface{}{"id": "123"}

	// 1. Mock finding enabled webhooks for workspace
	webhookRows := sqlmock.NewRows([]string{"id", "workspace_id", "enabled", "events", "url"}).
		AddRow(webhookID, workspaceID, true, `["trace.created"]`, "https://api.test/hook")

	mock.ExpectQuery(`(?i)SELECT \* FROM "webhooks" WHERE workspace_id = \$1 AND enabled = true`).
		WithArgs(workspaceID).
		WillReturnRows(webhookRows)

	// 2. Mock creation of the WebhookEvent (status: pending)
	mock.ExpectBegin()
	mock.ExpectExec(`(?i)INSERT INTO "webhook_events"`).
		WithArgs(sqlmock.AnyArg(), webhookID, eventType, `{"id":"123"}`, "pending", 0, nil, "", sqlmock.AnyArg()).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	// 3. Mock the Async Update (sendWebhook)
	mock.ExpectBegin()
	mock.ExpectExec(`(?i)UPDATE "webhook_events"`).
		WithArgs(
			1,                // $1: attempts
			sqlmock.AnyArg(), // $2: last_attempt (time.Now)
			"sent",           // $3: status
			sqlmock.AnyArg(), // $4: id (WHERE clause)
		).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()
	err := service.TriggerWebhook(workspaceID, eventType, payload)
	assert.NoError(t, err)

	// Give the goroutine a tiny bit of time to execute before checking expectations
	time.Sleep(50 * time.Millisecond)

	assert.NoError(t, mock.ExpectationsWereMet())
}
