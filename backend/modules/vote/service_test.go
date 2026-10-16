package vote_test

import (
	"testing"
	"time"

	"github.com/masabasi/backend/internal/testutil"
	"github.com/masabasi/backend/modules/library"
	"github.com/masabasi/backend/modules/member"
	"github.com/masabasi/backend/modules/vote"
)

func newSvc(t *testing.T) *vote.Service {
	db := testutil.NewTestDB(t)
	return vote.NewService(db)
}

// seedPollWithGames creates a poll with two real game options.
func seedPollWithGames(t *testing.T) (*vote.Service, *vote.VotePoll, uint, uint) {
	t.Helper()
	db := testutil.NewTestDB(t)
	svc := vote.NewService(db)

	m := member.Member{Email: "admin@test.com", PasswordHash: "x", DisplayName: "Admin", Role: "admin"}
	if err := db.Create(&m).Error; err != nil {
		t.Fatalf("seed member: %v", err)
	}

	g1 := library.Game{Title: "Catan", MinPlayers: 3, MaxPlayers: 4}
	g2 := library.Game{Title: "Wingspan", MinPlayers: 1, MaxPlayers: 5}
	db.Create(&g1)
	db.Create(&g2)

	p, err := svc.CreatePoll(vote.CreatePollInput{
		Title:   "Test Anketi",
		EndsAt:  time.Now().Add(24 * time.Hour),
		GameIDs: []uint{g1.ID, g2.ID},
	}, m.ID)
	if err != nil {
		t.Fatalf("seed poll: %v", err)
	}
	return svc, p, g1.ID, m.ID
}

// ── CreatePoll ──────────────────────────────────────────────────────────────

func TestCreatePoll_HappyPath(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := vote.NewService(db)

	m := member.Member{Email: "a@b.com", PasswordHash: "x", DisplayName: "A", Role: "admin"}
	db.Create(&m)

	g1 := library.Game{Title: "G1", MinPlayers: 2, MaxPlayers: 4}
	g2 := library.Game{Title: "G2", MinPlayers: 2, MaxPlayers: 4}
	db.Create(&g1)
	db.Create(&g2)

	p, err := svc.CreatePoll(vote.CreatePollInput{
		Title:   "Sprint Anketi",
		EndsAt:  time.Now().Add(time.Hour),
		GameIDs: []uint{g1.ID, g2.ID},
	}, m.ID)
	if err != nil {
		t.Fatalf("CreatePoll: %v", err)
	}
	if p.Title != "Sprint Anketi" {
		t.Errorf("title: got %q", p.Title)
	}
	if len(p.Options) != 2 {
		t.Errorf("options: want 2, got %d", len(p.Options))
	}
}

func TestCreatePoll_TooFewGames(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := vote.NewService(db)

	m := member.Member{Email: "b@b.com", PasswordHash: "x", DisplayName: "B", Role: "admin"}
	db.Create(&m)

	g1 := library.Game{Title: "Solo", MinPlayers: 1, MaxPlayers: 1}
	db.Create(&g1)

	_, err := svc.CreatePoll(vote.CreatePollInput{
		Title:   "Tek Seçenek",
		EndsAt:  time.Now().Add(time.Hour),
		GameIDs: []uint{g1.ID},
	}, m.ID)
	if err == nil {
		t.Fatal("expected error for < 2 games")
	}
}

func TestCreatePoll_PastEndsAt(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := vote.NewService(db)

	m := member.Member{Email: "c@b.com", PasswordHash: "x", DisplayName: "C", Role: "admin"}
	db.Create(&m)

	g1 := library.Game{Title: "G1", MinPlayers: 2, MaxPlayers: 4}
	g2 := library.Game{Title: "G2", MinPlayers: 2, MaxPlayers: 4}
	db.Create(&g1)
	db.Create(&g2)

	_, err := svc.CreatePoll(vote.CreatePollInput{
		Title:   "Geçmiş Tarih",
		EndsAt:  time.Now().Add(-time.Hour),
		GameIDs: []uint{g1.ID, g2.ID},
	}, m.ID)
	if err == nil {
		t.Fatal("expected error for past ends_at")
	}
}

// ── GetCurrentPoll ──────────────────────────────────────────────────────────

func TestGetCurrentPoll_ReturnsActivePoll(t *testing.T) {
	svc, p, _, _ := seedPollWithGames(t)

	got, err := svc.GetCurrentPoll()
	if err != nil {
		t.Fatalf("GetCurrentPoll: %v", err)
	}
	if got.ID != p.ID {
		t.Errorf("poll id: want %d, got %d", p.ID, got.ID)
	}
}

func TestGetCurrentPoll_NoActivePoll(t *testing.T) {
	svc := newSvc(t)

	_, err := svc.GetCurrentPoll()
	if err == nil {
		t.Fatal("expected ErrPollNotFound")
	}
}

// ── CastVote ────────────────────────────────────────────────────────────────

func TestCastVote_HappyPath(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := vote.NewService(db)

	m1 := member.Member{Email: "voter@b.com", PasswordHash: "x", DisplayName: "Voter", Role: "member"}
	admin := member.Member{Email: "adm@b.com", PasswordHash: "x", DisplayName: "Admin", Role: "admin"}
	db.Create(&m1)
	db.Create(&admin)

	g1 := library.Game{Title: "A", MinPlayers: 2, MaxPlayers: 4}
	g2 := library.Game{Title: "B", MinPlayers: 2, MaxPlayers: 4}
	db.Create(&g1)
	db.Create(&g2)

	p, _ := svc.CreatePoll(vote.CreatePollInput{
		Title:   "Vote Test",
		EndsAt:  time.Now().Add(time.Hour),
		GameIDs: []uint{g1.ID, g2.ID},
	}, admin.ID)

	optID := p.Options[0].ID
	err := svc.CastVote(p.ID, optID, m1.ID)
	if err != nil {
		t.Fatalf("CastVote: %v", err)
	}

	res, _ := svc.GetResults(p.ID)
	total := 0
	for _, o := range res.Options {
		total += o.VoteCount
	}
	if total != 1 {
		t.Errorf("total votes: want 1, got %d", total)
	}
}

func TestCastVote_AlreadyVoted(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := vote.NewService(db)

	m1 := member.Member{Email: "v2@b.com", PasswordHash: "x", DisplayName: "V2", Role: "member"}
	admin := member.Member{Email: "a2@b.com", PasswordHash: "x", DisplayName: "A2", Role: "admin"}
	db.Create(&m1)
	db.Create(&admin)

	g1 := library.Game{Title: "A", MinPlayers: 2, MaxPlayers: 4}
	g2 := library.Game{Title: "B", MinPlayers: 2, MaxPlayers: 4}
	db.Create(&g1)
	db.Create(&g2)

	p, _ := svc.CreatePoll(vote.CreatePollInput{
		Title:   "Double Vote",
		EndsAt:  time.Now().Add(time.Hour),
		GameIDs: []uint{g1.ID, g2.ID},
	}, admin.ID)

	optID := p.Options[0].ID
	_ = svc.CastVote(p.ID, optID, m1.ID)

	err := svc.CastVote(p.ID, optID, m1.ID)
	if err == nil {
		t.Fatal("expected ErrAlreadyVoted")
	}
}

func TestCastVote_OptionNotInPoll(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := vote.NewService(db)

	admin := member.Member{Email: "a3@b.com", PasswordHash: "x", DisplayName: "A3", Role: "admin"}
	m1 := member.Member{Email: "v3@b.com", PasswordHash: "x", DisplayName: "V3", Role: "member"}
	db.Create(&admin)
	db.Create(&m1)

	g1 := library.Game{Title: "A", MinPlayers: 2, MaxPlayers: 4}
	g2 := library.Game{Title: "B", MinPlayers: 2, MaxPlayers: 4}
	db.Create(&g1)
	db.Create(&g2)

	p, _ := svc.CreatePoll(vote.CreatePollInput{
		Title:   "Wrong Option",
		EndsAt:  time.Now().Add(time.Hour),
		GameIDs: []uint{g1.ID, g2.ID},
	}, admin.ID)

	// Use a non-existent option ID.
	err := svc.CastVote(p.ID, 99999, m1.ID)
	if err == nil {
		t.Fatal("expected ErrOptionNotInPoll")
	}
}

// ── GetResults ──────────────────────────────────────────────────────────────

func TestGetResults_Tally(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := vote.NewService(db)

	admin := member.Member{Email: "a4@b.com", PasswordHash: "x", DisplayName: "A4", Role: "admin"}
	m1 := member.Member{Email: "v4@b.com", PasswordHash: "x", DisplayName: "V4", Role: "member"}
	m2 := member.Member{Email: "v5@b.com", PasswordHash: "x", DisplayName: "V5", Role: "member"}
	db.Create(&admin)
	db.Create(&m1)
	db.Create(&m2)

	g1 := library.Game{Title: "A", MinPlayers: 2, MaxPlayers: 4}
	g2 := library.Game{Title: "B", MinPlayers: 2, MaxPlayers: 4}
	db.Create(&g1)
	db.Create(&g2)

	p, _ := svc.CreatePoll(vote.CreatePollInput{
		Title:   "Tally Test",
		EndsAt:  time.Now().Add(time.Hour),
		GameIDs: []uint{g1.ID, g2.ID},
	}, admin.ID)

	_ = svc.CastVote(p.ID, p.Options[0].ID, m1.ID)
	_ = svc.CastVote(p.ID, p.Options[0].ID, m2.ID)

	res, err := svc.GetResults(p.ID)
	if err != nil {
		t.Fatalf("GetResults: %v", err)
	}
	if res.Options[0].VoteCount != 2 {
		t.Errorf("opt[0] votes: want 2, got %d", res.Options[0].VoteCount)
	}
	if res.Options[1].VoteCount != 0 {
		t.Errorf("opt[1] votes: want 0, got %d", res.Options[1].VoteCount)
	}
	if res.Options[0].Pct != 100.0 {
		t.Errorf("opt[0] pct: want 100, got %f", res.Options[0].Pct)
	}
}

// ── ListPolls ───────────────────────────────────────────────────────────────

func TestListPolls(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := vote.NewService(db)

	admin := member.Member{Email: "a5@b.com", PasswordHash: "x", DisplayName: "A5", Role: "admin"}
	db.Create(&admin)

	g1 := library.Game{Title: "A", MinPlayers: 2, MaxPlayers: 4}
	g2 := library.Game{Title: "B", MinPlayers: 2, MaxPlayers: 4}
	db.Create(&g1)
	db.Create(&g2)

	svc.CreatePoll(vote.CreatePollInput{Title: "P1", EndsAt: time.Now().Add(time.Hour), GameIDs: []uint{g1.ID, g2.ID}}, admin.ID) //nolint:errcheck
	svc.CreatePoll(vote.CreatePollInput{Title: "P2", EndsAt: time.Now().Add(time.Hour), GameIDs: []uint{g1.ID, g2.ID}}, admin.ID) //nolint:errcheck

	polls, err := svc.ListPolls()
	if err != nil {
		t.Fatalf("ListPolls: %v", err)
	}
	if len(polls) < 2 {
		t.Errorf("want >= 2 polls, got %d", len(polls))
	}
}
