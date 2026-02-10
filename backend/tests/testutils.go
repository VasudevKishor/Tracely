package tests

import (
	"os"
	"testing"

	"backend/config"
)

// SetupTestEnvironment sets up the test environment
func SetupTestEnvironment(t *testing.T) *config.Config {
	t.Helper()

	// Set test environment variables
	os.Setenv("ENVIRONMENT", "test")
	os.Setenv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/test_db?sslmode=disable")
	os.Setenv("JWT_SECRET", "test-secret-key-for-testing-only")
	os.Setenv("LOG_LEVEL", "error")

	return config.Load()
}

// CleanupTestEnvironment cleans up after tests
func CleanupTestEnvironment(t *testing.T) {
	t.Helper()
	os.Clearenv()
}
