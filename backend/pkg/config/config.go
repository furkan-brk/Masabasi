// Package config loads environment-based configuration for the Masabaşı service.
package config

import "os"

// Config holds runtime configuration read from the environment.
type Config struct {
	Port           string
	DBURL          string
	JWTSecret      string
	CORSOrigin     string
	ClaudeAPIKey   string
	GameMasterMode string
	// Vertex AI / Gemini (used when GameMasterMode == "gemini")
	GeminiServiceAccountJSON string // raw JSON content of the service account key
	GeminiProjectID          string // GCP project ID (falls back to project_id in SA JSON)
	GeminiRegion             string // Vertex AI region, default us-central1
	GeminiModel              string // model ID, default gemini-2.0-flash
	MinioEndpoint            string
	MinioAccessKey           string
	MinioSecretKey           string
	MinioBucket              string
	MinioPublicURL           string
}

// Load reads configuration from the environment, applying sensible defaults.
func Load() Config {
	return Config{
		Port:                     getEnv("PORT", "8080"),
		DBURL:                    getEnv("DB_URL", ""),
		JWTSecret:                getEnv("JWT_SECRET", "masabasi-dev-secret-change-me"),
		CORSOrigin:               getEnv("CORS_ORIGIN", "*"),
		ClaudeAPIKey:             getEnv("CLAUDE_API_KEY", ""),
		GameMasterMode:           getEnv("GAMEMASTER_MODE", "claude"),
		GeminiServiceAccountJSON: loadGeminiSA(),
		GeminiProjectID:          getEnv("GCP_PROJECT_ID", ""),
		GeminiRegion:             getEnv("GCP_REGION", "us-central1"),
		GeminiModel:              getEnv("GEMINI_MODEL", "gemini-2.0-flash"),
		MinioEndpoint:            getEnv("MINIO_ENDPOINT", "masabasi-minio:9000"),
		MinioAccessKey:           getEnv("MINIO_ACCESS_KEY", "masabasi_minio"),
		MinioSecretKey:           getEnv("MINIO_SECRET_KEY", "masabasi_minio_dev_pw"),
		MinioBucket:              getEnv("MINIO_BUCKET", "masabasi"),
		MinioPublicURL:           getEnv("MINIO_PUBLIC_URL", "http://localhost:9000/masabasi"),
	}
}

// loadGeminiSA returns the service account JSON.
// Prefers GCP_SERVICE_ACCOUNT_JSON (inline), falls back to reading GCP_SERVICE_ACCOUNT_FILE.
func loadGeminiSA() string {
	if v := os.Getenv("GCP_SERVICE_ACCOUNT_JSON"); v != "" {
		return v
	}
	if path := os.Getenv("GCP_SERVICE_ACCOUNT_FILE"); path != "" {
		b, err := os.ReadFile(path)
		if err == nil {
			return string(b)
		}
	}
	return ""
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
