package config

import (
	"log"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	Environment       string
	Port              string
	DatabaseURL       string
	JWTSecret         string
	JWTExpiration     string
	RefreshExpiration string
	CORSOrigins       []string
	LogLevel          string
	TraceStorageDir   string
	MaxReplayWorkers  int
	EncryptionKey     string
}

func Load() *Config {
	// Load .env file if exists
	_ = godotenv.Load()

	config := &Config{
		Environment:       getEnv("ENVIRONMENT", "development"),
		Port:              getEnv("PORT", "8081"),
		DatabaseURL:       getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/tracely_dev?sslmode=disable"),
		JWTSecret:         getEnv("JWT_SECRET", "your-secret-key-change-in-production"),
		JWTExpiration:     getEnv("JWT_EXPIRATION", "1h"),
		RefreshExpiration: getEnv("REFRESH_EXPIRATION", "720h"), // 30 days
		CORSOrigins:       strings.Split(getEnv("CORS_ORIGINS", "http://localhost"), ","),
		LogLevel:          getEnv("LOG_LEVEL", "info"),
		TraceStorageDir:   getEnv("TRACE_STORAGE_DIR", "./traces"),
		MaxReplayWorkers:  10,
		EncryptionKey:     getEnv("ENCRYPTION_KEY", "default-encryption-key-change-in-production"),
	}

	// Validate required fields
	if config.JWTSecret == "your-secret-key-change-in-production" && config.Environment == "production" {
		log.Fatal("JWT_SECRET must be set in production environment")
	}

	return config
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
