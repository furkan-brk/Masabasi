package member_test

import (
	"testing"

	"github.com/masabasi/backend/internal/testutil"
	"github.com/masabasi/backend/modules/member"
)

func TestRegisterAndLogin(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := member.NewService(db)

	m, err := svc.Register(member.RegisterInput{
		Email:       "test@masabasi.com",
		Password:    "secret123",
		DisplayName: "Test Kullanici",
	})
	if err != nil {
		t.Fatalf("Register: %v", err)
	}
	if m.Email != "test@masabasi.com" {
		t.Errorf("email mismatch: got %q", m.Email)
	}

	_, err = svc.Register(member.RegisterInput{Email: "test@masabasi.com", Password: "x", DisplayName: "y"})
	if err != member.ErrEmailTaken {
		t.Errorf("expected ErrEmailTaken, got %v", err)
	}

	logged, err := svc.Login("test@masabasi.com", "secret123")
	if err != nil {
		t.Fatalf("Login: %v", err)
	}
	if logged.ID != m.ID {
		t.Errorf("id mismatch after login")
	}

	_, err = svc.Login("test@masabasi.com", "wrongpass")
	if err != member.ErrInvalidCredentials {
		t.Errorf("expected ErrInvalidCredentials, got %v", err)
	}
}

func TestGetByID(t *testing.T) {
	db := testutil.NewTestDB(t)
	svc := member.NewService(db)

	m, _ := svc.Register(member.RegisterInput{Email: "a@b.com", Password: "pw", DisplayName: "A"})
	got, err := svc.GetByID(m.ID)
	if err != nil {
		t.Fatalf("GetByID: %v", err)
	}
	if got.Email != m.Email {
		t.Errorf("email mismatch")
	}

	_, err = svc.GetByID(99999)
	if err != member.ErrNotFound {
		t.Errorf("expected ErrNotFound, got %v", err)
	}
}
