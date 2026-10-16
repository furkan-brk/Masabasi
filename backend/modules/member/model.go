package member

import "gorm.io/gorm"

// Member is a registered Masabaşı Oyun Kulübü member.
type Member struct {
	gorm.Model
	Email           string `gorm:"uniqueIndex;not null" json:"email"`
	PasswordHash    string `gorm:"not null" json:"-"`
	DisplayName     string `gorm:"not null" json:"display_name"`
	AvatarURL       string `json:"avatar_url"`
	Bio             string `json:"bio"`
	ExperienceLevel string `gorm:"default:'Çırak'" json:"experience_level"` // Çırak / Maceracı / Usta
	FavoriteGenres  string `json:"favorite_genres"`                         // JSON array string
	ClubStatus      string `gorm:"default:'Aktif Üye'" json:"club_status"`
	Role            string `gorm:"default:'member'" json:"role"` // member / admin
}
