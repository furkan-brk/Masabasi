package library_test

import (
	"errors"
	"testing"

	"github.com/masabasi/backend/internal/testutil"
	"github.com/masabasi/backend/modules/library"
)

func seedGames(t *testing.T, svc *library.Service) {
	t.Helper()
	games := []*library.Game{
		{Title: "Wingspan", MinPlayers: 1, MaxPlayers: 5, Complexity: 3, Genres: `["Motor Kurma","Aile"]`},
		{Title: "Gloomhaven", MinPlayers: 1, MaxPlayers: 4, Complexity: 5, Genres: `["Macera","Dövüş"]`},
		{Title: "Brass: Birmingham", MinPlayers: 2, MaxPlayers: 4, Complexity: 5, Genres: `["Ekonomi","Strateji"]`},
	}
	for _, g := range games {
		if _, err := svc.CreateGame(g); err != nil {
			t.Fatalf("seed game %q: %v", g.Title, err)
		}
	}
}

func intp(v int) *int           { return &v }
func floatp(v float64) *float64 { return &v }

func TestListGames(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := library.NewService(db)
	seedGames(t, svc)

	tests := []struct {
		name   string
		filter library.ListFilter
		want   int
	}{
		{name: "no filter returns all", filter: library.ListFilter{}, want: 3},
		{name: "title query", filter: library.ListFilter{Query: "brass"}, want: 1},
		{name: "complexity 5", filter: library.ListFilter{Complexity: floatp(5)}, want: 2},
		{name: "genre substring", filter: library.ListFilter{Genres: "strateji"}, want: 1},
		{name: "solo playable (max>=1, min<=1)", filter: library.ListFilter{MinPlayers: intp(1), MaxPlayers: intp(1)}, want: 2},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := svc.ListGames(tc.filter)
			if err != nil {
				t.Fatalf("list: %v", err)
			}
			if len(got) != tc.want {
				t.Fatalf("want %d games, got %d", tc.want, len(got))
			}
		})
	}

	// Ordering: results are sorted by title ascending.
	all, _ := svc.ListGames(library.ListFilter{})
	if all[0].Title != "Brass: Birmingham" {
		t.Fatalf("expected first game 'Brass: Birmingham', got %q", all[0].Title)
	}
}

func TestGetGame(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := library.NewService(db)
	seedGames(t, svc)

	all, _ := svc.ListGames(library.ListFilter{})
	first := all[0]

	got, err := svc.GetGame(first.ID)
	if err != nil {
		t.Fatalf("get game: %v", err)
	}
	if got.ID != first.ID {
		t.Fatalf("expected id %d, got %d", first.ID, got.ID)
	}

	if _, err := svc.GetGame(9999); !errors.Is(err, library.ErrNotFound) {
		t.Fatalf("expected ErrNotFound for missing game, got %v", err)
	}
}
