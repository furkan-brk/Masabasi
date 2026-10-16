package favorite

import "gorm.io/gorm"

// Favorite is a member↔game join row (one row per favorited game per member).
type Favorite struct {
	gorm.Model
	MemberID uint `gorm:"not null;uniqueIndex:idx_member_game" json:"member_id"`
	GameID   uint `gorm:"not null;uniqueIndex:idx_member_game" json:"game_id"`
}
