// Package services: test helper for SQLite. Models use Postgres defaults (gen_random_uuid())
// which SQLite does not support, so we create tables with raw DDL for tests.
package services

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// sqliteDDL creates tables compatible with SQLite (no gen_random_uuid).
func sqliteDDL(db *gorm.DB) error {
	ddl := []string{
		`CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, email TEXT NOT NULL, password TEXT NOT NULL, name TEXT NOT NULL, created_at DATETIME, updated_at DATETIME, deleted_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS workspaces (id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT, owner_id TEXT NOT NULL, created_at DATETIME, updated_at DATETIME, deleted_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS workspace_members (id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL, user_id TEXT NOT NULL, role TEXT NOT NULL, created_at DATETIME, deleted_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS traces (id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL, service_name TEXT NOT NULL, span_count INTEGER DEFAULT 0, total_duration_ms REAL, start_time DATETIME NOT NULL, end_time DATETIME, status TEXT NOT NULL DEFAULT 'success', created_at DATETIME, deleted_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS spans (id TEXT PRIMARY KEY, trace_id TEXT NOT NULL, parent_span_id TEXT, operation_name TEXT NOT NULL, service_name TEXT NOT NULL, start_time DATETIME NOT NULL, duration_ms REAL, tags TEXT, logs TEXT, status TEXT DEFAULT 'ok', created_at DATETIME, deleted_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS annotations (id TEXT PRIMARY KEY, span_id TEXT NOT NULL, user_id TEXT NOT NULL, comment TEXT NOT NULL, highlight INTEGER DEFAULT 0, created_at DATETIME, updated_at DATETIME, deleted_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS executions (id TEXT PRIMARY KEY, request_id TEXT NOT NULL, status_code INTEGER, response_time_ms INTEGER, response_body TEXT, response_headers TEXT, trace_id TEXT, span_id TEXT, parent_span_id TEXT, error_message TEXT, timestamp DATETIME NOT NULL, created_at DATETIME, deleted_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS collections (id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT, workspace_id TEXT NOT NULL, request_count INTEGER DEFAULT 0, created_at DATETIME, updated_at DATETIME, deleted_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS requests (id TEXT PRIMARY KEY, name TEXT NOT NULL, method TEXT NOT NULL, url TEXT NOT NULL, headers TEXT, query_params TEXT, body TEXT, description TEXT, collection_id TEXT NOT NULL, created_at DATETIME, updated_at DATETIME, deleted_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS alert_rules (id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL, name TEXT NOT NULL, condition TEXT NOT NULL, threshold REAL NOT NULL, time_window INTEGER NOT NULL, enabled INTEGER DEFAULT 1, notification_channel TEXT NOT NULL, notification_config TEXT, created_at DATETIME, updated_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS alerts (id TEXT PRIMARY KEY, rule_id TEXT NOT NULL, workspace_id TEXT NOT NULL, severity TEXT NOT NULL, message TEXT, triggered_at DATETIME NOT NULL, resolved_at DATETIME, status TEXT DEFAULT 'active', metadata TEXT, created_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS failure_injection_rules (id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL, name TEXT NOT NULL, type TEXT NOT NULL, probability REAL DEFAULT 1.0, config TEXT, enabled INTEGER DEFAULT 1, created_at DATETIME)`,
		`CREATE TABLE IF NOT EXISTS load_tests (id TEXT PRIMARY KEY, workspace_id TEXT NOT NULL, name TEXT NOT NULL, request_id TEXT NOT NULL, concurrency INTEGER NOT NULL, total_requests INTEGER NOT NULL, ramp_up_seconds INTEGER DEFAULT 0, duration INTEGER, status TEXT DEFAULT 'pending', success_count INTEGER DEFAULT 0, failure_count INTEGER DEFAULT 0, avg_response_time REAL, p95_response_time REAL, p99_response_time REAL, created_at DATETIME, started_at DATETIME, completed_at DATETIME)`,
	}
	for _, s := range ddl {
		if err := db.Exec(s).Error; err != nil {
			return err
		}
	}
	return nil
}

// OpenTestSQLite opens in-memory SQLite and creates tables via raw DDL (SQLite-compatible).
// Exported for use from handler tests.
func OpenTestSQLite() (*gorm.DB, error) {
	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
	if err != nil {
		return nil, err
	}
	return db, sqliteDDL(db)
}

func openTestSQLite() (*gorm.DB, error) {
	return OpenTestSQLite()
}
