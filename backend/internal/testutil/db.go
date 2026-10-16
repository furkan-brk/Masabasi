// Package testutil provides shared test helpers for masabasi-service.
package testutil

import (
	"testing"

	"github.com/glebarez/sqlite"
	"github.com/masabasi/backend/modules/favorite"
	"github.com/masabasi/backend/modules/library"
	"github.com/masabasi/backend/modules/member"
	"github.com/masabasi/backend/modules/notification"
	"github.com/masabasi/backend/modules/table"
	"github.com/masabasi/backend/modules/vote"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// NewTestDB returns an in-memory SQLite database (no CGO) with all tables migrated.
// Add new models to the AutoMigrate call below when they are introduced.
func NewTestDB(t *testing.T) *gorm.DB {
	t.Helper()
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	if err != nil {
		t.Fatalf("testutil: open sqlite: %v", err)
	}
	if err := db.AutoMigrate(
		&member.Member{},
		&library.Game{},
		&table.GameTable{},
		&table.TableSeat{},
		&vote.VotePoll{},
		&vote.VoteOption{},
		&vote.Vote{},
		&notification.Notification{},
		&favorite.Favorite{},
	); err != nil {
		t.Fatalf("testutil: auto migrate: %v", err)
	}
	return db
}
