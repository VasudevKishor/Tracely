package config

import (
	"os"
	"testing"
)

func TestLoad_Defaults(t *testing.T) {
	// Clear env to get defaults (avoid Fatal in production check)
	os.Unsetenv("ENVIRONMENT")
	os.Unsetenv("JWT_SECRET")
	cfg := Load()
	if cfg == nil {
		t.Fatal("Load() returned nil")
	}
	if cfg.Port != "8081" {
		t.Errorf("default Port = %q; want 8081", cfg.Port)
	}
	if cfg.Environment != "development" {
		t.Errorf("default Environment = %q; want development", cfg.Environment)
	}
	if len(cfg.CORSOrigins) == 0 {
		t.Error("CORSOrigins should not be empty")
	}
}

func TestLoad_FromEnv(t *testing.T) {
	os.Setenv("PORT", "9999")
	os.Setenv("ENVIRONMENT", "test")
	defer func() {
		os.Unsetenv("PORT")
		os.Unsetenv("ENVIRONMENT")
	}()
	cfg := Load()
	if cfg.Port != "9999" {
		t.Errorf("Port = %q; want 9999", cfg.Port)
	}
	if cfg.Environment != "test" {
		t.Errorf("Environment = %q; want test", cfg.Environment)
	}
}
