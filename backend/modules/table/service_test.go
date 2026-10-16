package table_test

import (
	"errors"
	"testing"
	"time"

	"github.com/masabasi/backend/internal/testutil"
	"github.com/masabasi/backend/modules/library"
	"github.com/masabasi/backend/modules/member"
	"github.com/masabasi/backend/modules/table"
	"gorm.io/gorm"
)

func seedGame(t *testing.T, db *gorm.DB) library.Game {
	t.Helper()
	g := library.Game{Title: "Catan", MinPlayers: 3, MaxPlayers: 4, Complexity: 2}
	if err := db.Create(&g).Error; err != nil {
		t.Fatalf("seed game: %v", err)
	}
	return g
}

func seedMember(t *testing.T, db *gorm.DB, email string) member.Member {
	t.Helper()
	m := member.Member{Email: email, PasswordHash: "x", DisplayName: email}
	if err := db.Create(&m).Error; err != nil {
		t.Fatalf("seed member %q: %v", email, err)
	}
	return m
}

func newTable(t *testing.T, svc *table.Service, gameID, hostID uint, capacity int) *table.GameTable {
	t.Helper()
	gt, err := svc.CreateTable(table.CreateInput{
		GameID:      gameID,
		HostID:      hostID,
		ScheduledAt: time.Now().Add(24 * time.Hour),
		Capacity:    capacity,
	})
	if err != nil {
		t.Fatalf("create table: %v", err)
	}
	return gt
}

func TestCreateAndListTables(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := table.NewService(db)
	g := seedGame(t, db)
	host := seedMember(t, db, "host@x")

	gt := newTable(t, svc, g.ID, host.ID, 4)
	if gt.Status != table.StatusWaiting {
		t.Fatalf("expected status %q, got %q", table.StatusWaiting, gt.Status)
	}
	if len(gt.Seats) != 1 {
		t.Fatalf("expected host auto-seated (1 seat), got %d", len(gt.Seats))
	}

	open, err := svc.ListTables(table.ListFilter{Tab: "open"})
	if err != nil {
		t.Fatalf("list open: %v", err)
	}
	if len(open) != 1 {
		t.Fatalf("expected 1 open table, got %d", len(open))
	}
	if open[0].Game.Title != "Catan" || open[0].Host.ID != host.ID {
		t.Fatalf("preloads missing: game=%q host=%d", open[0].Game.Title, open[0].Host.ID)
	}
}

func TestCreateTable_InvalidCapacity(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := table.NewService(db)
	g := seedGame(t, db)
	host := seedMember(t, db, "host@x")

	if _, err := svc.CreateTable(table.CreateInput{
		GameID: g.ID, HostID: host.ID, ScheduledAt: time.Now(), Capacity: 1,
	}); !errors.Is(err, table.ErrInvalidInput) {
		t.Fatalf("expected ErrInvalidInput, got %v", err)
	}
}

func TestJoinTable_HappyPath(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := table.NewService(db)
	g := seedGame(t, db)
	host := seedMember(t, db, "host@x")
	guest := seedMember(t, db, "guest@x")

	gt := newTable(t, svc, g.ID, host.ID, 4)

	if err := svc.JoinTableTx(gt.ID, guest.ID); err != nil {
		t.Fatalf("join: %v", err)
	}

	loaded, err := svc.GetTable(gt.ID)
	if err != nil {
		t.Fatalf("get: %v", err)
	}
	if len(loaded.Seats) != 2 {
		t.Fatalf("expected 2 seats, got %d", len(loaded.Seats))
	}
	if loaded.Status != table.StatusWaiting {
		t.Fatalf("expected still waiting, got %q", loaded.Status)
	}
}

func TestJoinTable_TableFull(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := table.NewService(db)
	g := seedGame(t, db)
	host := seedMember(t, db, "host@x")

	// capacity 2: host fills seat 1, one guest fills seat 2 -> full.
	gt := newTable(t, svc, g.ID, host.ID, 2)
	guest1 := seedMember(t, db, "g1@x")
	guest2 := seedMember(t, db, "g2@x")

	if err := svc.JoinTableTx(gt.ID, guest1.ID); err != nil {
		t.Fatalf("join guest1: %v", err)
	}

	loaded, _ := svc.GetTable(gt.ID)
	if loaded.Status != table.StatusFull {
		t.Fatalf("expected full after capacity reached, got %q", loaded.Status)
	}

	if err := svc.JoinTableTx(gt.ID, guest2.ID); !errors.Is(err, table.ErrTableFull) {
		t.Fatalf("expected ErrTableFull, got %v", err)
	}
}

func TestJoinTable_AlreadyJoined(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := table.NewService(db)
	g := seedGame(t, db)
	host := seedMember(t, db, "host@x")
	guest := seedMember(t, db, "guest@x")

	gt := newTable(t, svc, g.ID, host.ID, 4)
	if err := svc.JoinTableTx(gt.ID, guest.ID); err != nil {
		t.Fatalf("join: %v", err)
	}
	if err := svc.JoinTableTx(gt.ID, guest.ID); !errors.Is(err, table.ErrAlreadyJoined) {
		t.Fatalf("expected ErrAlreadyJoined, got %v", err)
	}
	// Host re-joining is also a duplicate.
	if err := svc.JoinTableTx(gt.ID, host.ID); !errors.Is(err, table.ErrAlreadyJoined) {
		t.Fatalf("expected ErrAlreadyJoined for host, got %v", err)
	}
}

func TestLeaveTable(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := table.NewService(db)
	g := seedGame(t, db)
	host := seedMember(t, db, "host@x")
	guest := seedMember(t, db, "guest@x")

	gt := newTable(t, svc, g.ID, host.ID, 2)
	if err := svc.JoinTableTx(gt.ID, guest.ID); err != nil {
		t.Fatalf("join: %v", err)
	}

	// Now full; guest leaves -> seat count drops, status back to waiting.
	if err := svc.LeaveTableTx(gt.ID, guest.ID); err != nil {
		t.Fatalf("leave: %v", err)
	}
	loaded, _ := svc.GetTable(gt.ID)
	if len(loaded.Seats) != 1 {
		t.Fatalf("expected 1 seat after leave, got %d", len(loaded.Seats))
	}
	if loaded.Status != table.StatusWaiting {
		t.Fatalf("expected waiting after leave, got %q", loaded.Status)
	}

	// Host cannot leave.
	if err := svc.LeaveTableTx(gt.ID, host.ID); !errors.Is(err, table.ErrNotHost) {
		t.Fatalf("expected ErrNotHost, got %v", err)
	}

	// Non-member leaving -> ErrNotJoined.
	if err := svc.LeaveTableTx(gt.ID, guest.ID); !errors.Is(err, table.ErrNotJoined) {
		t.Fatalf("expected ErrNotJoined, got %v", err)
	}
}

func TestUpdateTable_OptimisticConcurrency(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := table.NewService(db)
	g := seedGame(t, db)
	host := seedMember(t, db, "host@x")
	other := seedMember(t, db, "other@x")

	gt := newTable(t, svc, g.ID, host.ID, 4)
	rev := gt.RevisionID

	updated, err := svc.UpdateTable(gt.ID, host.ID, rev, table.UpdateInput{
		ScheduledAt: time.Now().Add(72 * time.Hour),
		Location:    "Yeni Salon",
		Capacity:    6,
	})
	if err != nil {
		t.Fatalf("update: %v", err)
	}
	if updated.Location != "Yeni Salon" || updated.Capacity != 6 {
		t.Fatalf("update not applied: %+v", updated)
	}
	if updated.RevisionID != rev+1 {
		t.Fatalf("expected revision %d, got %d", rev+1, updated.RevisionID)
	}

	// Stale revision -> conflict.
	if _, err := svc.UpdateTable(gt.ID, host.ID, rev, table.UpdateInput{
		ScheduledAt: time.Now(), Capacity: 4,
	}); !errors.Is(err, table.ErrConflict) {
		t.Fatalf("expected ErrConflict, got %v", err)
	}

	// Non-host -> ErrNotHost.
	if _, err := svc.UpdateTable(gt.ID, other.ID, updated.RevisionID, table.UpdateInput{
		ScheduledAt: time.Now(), Capacity: 4,
	}); !errors.Is(err, table.ErrNotHost) {
		t.Fatalf("expected ErrNotHost, got %v", err)
	}
}

func TestListTables_MineTab(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := table.NewService(db)
	g := seedGame(t, db)
	host := seedMember(t, db, "host@x")
	guest := seedMember(t, db, "guest@x")
	stranger := seedMember(t, db, "stranger@x")

	hosted := newTable(t, svc, g.ID, host.ID, 4)
	joined := newTable(t, svc, g.ID, stranger.ID, 4)
	if err := svc.JoinTableTx(joined.ID, guest.ID); err != nil {
		t.Fatalf("join: %v", err)
	}
	_ = newTable(t, svc, g.ID, stranger.ID, 4) // unrelated to guest

	// guest's "mine": one hosted-by? no; joined as guest -> 1.
	mine, err := svc.ListTables(table.ListFilter{Tab: "mine", MemberID: guest.ID})
	if err != nil {
		t.Fatalf("list mine: %v", err)
	}
	if len(mine) != 1 || mine[0].ID != joined.ID {
		t.Fatalf("expected guest mine=[joined], got %d tables", len(mine))
	}

	// host's "mine": the table they host.
	mineHost, _ := svc.ListTables(table.ListFilter{Tab: "mine", MemberID: host.ID})
	if len(mineHost) != 1 || mineHost[0].ID != hosted.ID {
		t.Fatalf("expected host mine=[hosted], got %d tables", len(mineHost))
	}
}
