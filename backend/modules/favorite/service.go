package favorite

import (
	"errors"
	"fmt"

	"github.com/masabasi/backend/modules/library"
	"gorm.io/gorm"
)

var ErrGameNotFound = errors.New("game not found")

type Service struct{ db *gorm.DB }

func NewService(db *gorm.DB) *Service { return &Service{db: db} }

// Add idempotently adds gameID to memberID's favorites.
// Returns ErrGameNotFound if gameID does not exist in the library.
func (s *Service) Add(memberID, gameID uint) error {
	var g library.Game
	if err := s.db.First(&g, gameID).Error; errors.Is(err, gorm.ErrRecordNotFound) {
		return ErrGameNotFound
	} else if err != nil {
		return fmt.Errorf("check game: %w", err)
	}
	fav := Favorite{MemberID: memberID, GameID: gameID}
	if err := s.db.Where(fav).FirstOrCreate(&fav).Error; err != nil {
		return fmt.Errorf("add favorite: %w", err)
	}
	return nil
}

// Remove removes gameID from memberID's favorites. Idempotent (silent if not present).
func (s *Service) Remove(memberID, gameID uint) error {
	if err := s.db.Where("member_id = ? AND game_id = ?", memberID, gameID).
		Delete(&Favorite{}).Error; err != nil {
		return fmt.Errorf("remove favorite: %w", err)
	}
	return nil
}

// ListGames returns the full Game objects for all of memberID's favorites, ordered by title.
func (s *Service) ListGames(memberID uint) ([]library.Game, error) {
	var games []library.Game
	err := s.db.
		Joins("JOIN favorites ON favorites.game_id = games.id AND favorites.deleted_at IS NULL").
		Where("favorites.member_id = ?", memberID).
		Where("games.deleted_at IS NULL").
		Order("games.title ASC").
		Find(&games).Error
	if err != nil {
		return nil, fmt.Errorf("list favorites: %w", err)
	}
	return games, nil
}
