// Package vote provides poll-based game voting for the club.
package vote

import (
	"time"

	"github.com/masabasi/backend/modules/library"
	"gorm.io/gorm"
)

// Status values for a VotePoll.
const (
	StatusActive = "active"
	StatusClosed = "closed"
)

// VotePoll is a single voting round over a set of game options.
type VotePoll struct {
	gorm.Model
	Title       string    `gorm:"not null" json:"title"`
	Description string    `json:"description"`
	EndsAt      time.Time `gorm:"not null" json:"ends_at"`
	Status      string    `gorm:"not null;default:'active'" json:"status"`
	CreatedByID uint      `gorm:"not null;index" json:"created_by_id"`

	Options []VoteOption `gorm:"foreignKey:PollID" json:"options"`
}

// VoteOption is one game choice within a poll.
type VoteOption struct {
	gorm.Model
	PollID       uint `gorm:"not null;index" json:"poll_id"`
	GameID       uint `gorm:"not null" json:"game_id"`
	DisplayOrder int  `gorm:"default:0" json:"display_order"`

	Game  library.Game `gorm:"foreignKey:GameID" json:"game"`
	Votes []Vote       `gorm:"foreignKey:OptionID" json:"votes,omitempty"`
}

// Vote is a single member's ballot for one option.
type Vote struct {
	gorm.Model
	OptionID uint `gorm:"not null;index" json:"option_id"`
	MemberID uint `gorm:"not null;index" json:"member_id"`
}
