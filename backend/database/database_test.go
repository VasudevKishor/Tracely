package database

import (
	"testing"

	"backend/config"
)

func TestInitDB_InvalidURL(t *testing.T) {
	cfg := &config.Config{
		DatabaseURL: "postgres://invalid:invalid@localhost:99999/nonexistent?sslmode=disable",
		LogLevel:    "error",
	}
	_, err := InitDB(cfg)
	if err == nil {
		t.Fatal("InitDB with invalid URL should return error")
	}
}
