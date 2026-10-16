// Package database manages the shared GORM connection for the Masabaşı service.
package database

import (
	"fmt"

	"github.com/glebarez/sqlite"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// DB is the shared global database connection.
var DB *gorm.DB

// SetForTest swaps the global DB to a test instance.
func SetForTest(db *gorm.DB) {
	DB = db
}

// Connect opens a connection. If dbURL is empty, an in-memory sqlite database
// is used as a fallback (handy for local dev without Postgres).
func Connect(dbURL string) (*gorm.DB, error) {
	var dialector gorm.Dialector
	if dbURL == "" {
		dialector = sqlite.Open(":memory:")
	} else {
		dialector = postgres.Open(dbURL)
	}

	db, err := gorm.Open(dialector, &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		return nil, fmt.Errorf("open database: %w", err)
	}

	DB = db
	return db, nil
}
