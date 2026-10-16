package favorite_test

import (
	"errors"
	"testing"

	"github.com/masabasi/backend/internal/testutil"
	"github.com/masabasi/backend/modules/favorite"
	"github.com/masabasi/backend/modules/library"
	"gorm.io/gorm"
)

func seedGame(t *testing.T, db *gorm.DB, title string) library.Game {
	t.Helper()
	g := library.Game{Title: title, OwnedStatus: "Mevcut"}
	if err := db.Create(&g).Error; err != nil {
		t.Fatalf("seed game: %v", err)
	}
	return g
}

func TestAdd_ListGames(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := favorite.NewService(db)
	g := seedGame(t, db, "Catan")

	if err := svc.Add(1, g.ID); err != nil {
		t.Fatalf("add: %v", err)
	}
	games, err := svc.ListGames(1)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(games) != 1 || games[0].ID != g.ID {
		t.Fatalf("expected [%d], got %+v", g.ID, games)
	}
}

func TestAdd_Idempotent(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := favorite.NewService(db)
	g := seedGame(t, db, "Wingspan")

	if err := svc.Add(1, g.ID); err != nil {
		t.Fatalf("add 1: %v", err)
	}
	if err := svc.Add(1, g.ID); err != nil {
		t.Fatalf("add 2: %v", err)
	}
	games, err := svc.ListGames(1)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(games) != 1 {
		t.Fatalf("expected 1 favorite, got %d", len(games))
	}
}

func TestRemove(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := favorite.NewService(db)
	g := seedGame(t, db, "Azul")

	if err := svc.Add(1, g.ID); err != nil {
		t.Fatalf("add: %v", err)
	}
	if err := svc.Remove(1, g.ID); err != nil {
		t.Fatalf("remove: %v", err)
	}
	games, err := svc.ListGames(1)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(games) != 0 {
		t.Fatalf("expected empty list, got %d", len(games))
	}
}

func TestAdd_GameNotFound(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := favorite.NewService(db)

	err := svc.Add(1, 9999)
	if !errors.Is(err, favorite.ErrGameNotFound) {
		t.Fatalf("expected ErrGameNotFound, got %v", err)
	}
}

func TestListGames_MemberIsolation(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := favorite.NewService(db)
	g := seedGame(t, db, "Terraforming Mars")

	if err := svc.Add(1, g.ID); err != nil {
		t.Fatalf("add: %v", err)
	}
	games, err := svc.ListGames(2)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(games) != 0 {
		t.Fatalf("member 2 should see no favorites, got %d", len(games))
	}
}
