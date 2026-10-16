// Package notification provides club notification storage and delivery.
package notification

import (
	"time"

	"gorm.io/gorm"
)

// Type values for notifications.
const (
	TypeInvite    = "davet"
	TypeVote      = "oylama"
	TypeTableFull = "masa-doldu"
	TypeGeneral   = "genel"
)

// Notification is a single in-app notification for a member.
type Notification struct {
	gorm.Model
	MemberID uint       `gorm:"not null;index" json:"member_id"`
	Type     string     `gorm:"not null;default:'genel'" json:"type"`
	Title    string     `gorm:"not null" json:"title"`
	Body     string     `json:"body"`
	Link     string     `json:"link"`
	TableID  *uint      `gorm:"index" json:"table_id,omitempty"` // for invite/table notifications
	ReadAt   *time.Time `json:"read_at,omitempty"`
	Actioned bool       `gorm:"default:false" json:"actioned"` // true after accept/reject
}
