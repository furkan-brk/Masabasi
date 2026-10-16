// Package table provides game-table scheduling and atomic seat management.
package table

import (
	"time"

	"github.com/masabasi/backend/modules/library"
	"github.com/masabasi/backend/modules/member"
	"gorm.io/gorm"
)

// Status values for a GameTable.
const (
	StatusWaiting  = "bekliyor"
	StatusFull     = "dolu"
	StatusFinished = "bitti"
)

// GameTable is a scheduled play session for a game, hosted by a member.
type GameTable struct {
	gorm.Model
	GameID      uint      `gorm:"not null;index" json:"game_id"`
	HostID      uint      `gorm:"not null;index" json:"host_id"`
	ScheduledAt time.Time `gorm:"not null" json:"scheduled_at"`
	Location    string    `json:"location"`
	TableNo     string    `json:"table_no"`
	Capacity    int       `gorm:"not null;default:4" json:"capacity"`
	Notes       string    `json:"notes"`
	HouseRules  []string  `gorm:"serializer:json" json:"house_rules"`
	Status      string    `gorm:"not null;default:'bekliyor'" json:"status"`
	RevisionID  uint64    `gorm:"not null;default:0" json:"revision_id"`

	// Preload associations (not stored as columns).
	Game  library.Game  `gorm:"foreignKey:GameID" json:"game"`
	Host  member.Member `gorm:"foreignKey:HostID" json:"host"`
	Seats []TableSeat   `gorm:"foreignKey:TableID" json:"seats"`
}

// BeforeUpdate increments RevisionID for optimistic concurrency.
func (t *GameTable) BeforeUpdate(tx *gorm.DB) error {
	t.RevisionID++
	return nil
}

// TableSeat links a member to a table; the (table, member) pair is unique.
type TableSeat struct {
	gorm.Model
	TableID  uint `gorm:"not null;uniqueIndex:idx_table_member" json:"table_id"`
	MemberID uint `gorm:"not null;uniqueIndex:idx_table_member" json:"member_id"`

	Member member.Member `gorm:"foreignKey:MemberID" json:"member"`
}
