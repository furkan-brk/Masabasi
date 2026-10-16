package notification_test

import (
	"testing"

	"github.com/masabasi/backend/internal/testutil"
	"github.com/masabasi/backend/modules/notification"
)

func newSvc(t *testing.T) (*notification.Service, uint, uint) {
	t.Helper()
	db := testutil.NewTestDB(t)
	svc := notification.NewService(db)
	// Two member IDs — we don't need actual Member rows for notification tests
	// because there is no FK constraint enforced in SQLite by default.
	return svc, 1, 2
}

func createNotif(t *testing.T, svc *notification.Service, memberID uint, ntype string) uint {
	t.Helper()
	n := &notification.Notification{
		MemberID: memberID,
		Type:     ntype,
		Title:    "Test " + ntype,
		Body:     "body",
	}
	if err := svc.Create(n); err != nil {
		t.Fatalf("create notif: %v", err)
	}
	return n.ID
}

// ── List ────────────────────────────────────────────────────────────────────

func TestList_ReturnsMemberNotifications(t *testing.T) {
	svc, m1, m2 := newSvc(t)

	createNotif(t, svc, m1, notification.TypeGeneral)
	createNotif(t, svc, m1, notification.TypeVote)
	createNotif(t, svc, m2, notification.TypeGeneral) // belongs to other member

	ns, err := svc.List(m1)
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(ns) != 2 {
		t.Errorf("want 2 notifications for m1, got %d", len(ns))
	}
}

func TestList_EmptyForNewMember(t *testing.T) {
	svc, _, _ := newSvc(t)
	ns, err := svc.List(999)
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(ns) != 0 {
		t.Errorf("want 0 notifications, got %d", len(ns))
	}
}

// ── MarkAllRead ──────────────────────────────────────────────────────────────

func TestMarkAllRead(t *testing.T) {
	svc, m1, _ := newSvc(t)

	createNotif(t, svc, m1, notification.TypeGeneral)
	createNotif(t, svc, m1, notification.TypeGeneral)

	if err := svc.MarkAllRead(m1); err != nil {
		t.Fatalf("MarkAllRead: %v", err)
	}

	ns, _ := svc.List(m1)
	for _, n := range ns {
		if n.ReadAt == nil {
			t.Errorf("notification %d should be read", n.ID)
		}
	}
}

func TestMarkAllRead_DoesNotAffectOtherMembers(t *testing.T) {
	svc, m1, m2 := newSvc(t)

	createNotif(t, svc, m1, notification.TypeGeneral)
	createNotif(t, svc, m2, notification.TypeGeneral)

	_ = svc.MarkAllRead(m1)

	ns2, _ := svc.List(m2)
	for _, n := range ns2 {
		if n.ReadAt != nil {
			t.Errorf("m2 notification %d should NOT be read", n.ID)
		}
	}
}

// ── Accept (ownership enforcement) ──────────────────────────────────────────

func TestAccept_OwnershipEnforced(t *testing.T) {
	svc, m1, m2 := newSvc(t)

	id := createNotif(t, svc, m1, notification.TypeInvite)

	// m2 tries to accept m1's notification — must fail.
	err := svc.Accept(id, m2)
	if err == nil {
		t.Fatal("expected ErrNotFound when another member tries to accept")
	}
}

func TestAccept_HappyPath(t *testing.T) {
	svc, m1, _ := newSvc(t)

	id := createNotif(t, svc, m1, notification.TypeInvite)

	if err := svc.Accept(id, m1); err != nil {
		t.Fatalf("Accept: %v", err)
	}

	ns, _ := svc.List(m1)
	for _, n := range ns {
		if n.ID == id && !n.Actioned {
			t.Error("notification should be actioned after Accept")
		}
	}
}

// ── Reject ───────────────────────────────────────────────────────────────────

func TestReject_HappyPath(t *testing.T) {
	svc, m1, _ := newSvc(t)

	id := createNotif(t, svc, m1, notification.TypeInvite)

	if err := svc.Reject(id, m1); err != nil {
		t.Fatalf("Reject: %v", err)
	}

	ns, _ := svc.List(m1)
	for _, n := range ns {
		if n.ID == id && !n.Actioned {
			t.Error("notification should be actioned after Reject")
		}
	}
}

func TestReject_OwnershipEnforced(t *testing.T) {
	svc, m1, m2 := newSvc(t)

	id := createNotif(t, svc, m1, notification.TypeInvite)

	err := svc.Reject(id, m2)
	if err == nil {
		t.Fatal("expected ErrNotFound when another member tries to reject")
	}
}

// ── UnreadCount ──────────────────────────────────────────────────────────────

func TestUnreadCount(t *testing.T) {
	svc, m1, _ := newSvc(t)

	createNotif(t, svc, m1, notification.TypeGeneral)
	createNotif(t, svc, m1, notification.TypeGeneral)

	count, err := svc.UnreadCount(m1)
	if err != nil {
		t.Fatalf("UnreadCount: %v", err)
	}
	if count != 2 {
		t.Errorf("want 2 unread, got %d", count)
	}

	_ = svc.MarkAllRead(m1)
	count, _ = svc.UnreadCount(m1)
	if count != 0 {
		t.Errorf("want 0 unread after MarkAllRead, got %d", count)
	}
}
