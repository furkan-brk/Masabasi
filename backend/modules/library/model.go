package library

import "gorm.io/gorm"

// Game is a board game in the club's collection.
type Game struct {
	gorm.Model
	Title         string  `gorm:"not null" json:"title"`
	CoverImageURL string  `json:"cover_image_url"`
	MinPlayers    int     `json:"min_players"`
	MaxPlayers    int     `json:"max_players"`
	DurationMin   int     `json:"duration_min"`
	Complexity    float64 `json:"complexity"`                           // 0.0-5.0 (BGG-style decimal)
	Genres        string  `json:"genres"`                               // JSON array string
	OwnedStatus   string  `gorm:"default:'Mevcut'" json:"owned_status"` // Mevcut / Kayıp / Ödünç
	Description   string  `json:"description"`
	RulesNotes    string  `json:"rules_notes"`
}
