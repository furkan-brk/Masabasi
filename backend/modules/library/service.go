package library

import (
	"errors"
	"fmt"
	"strings"

	"gorm.io/gorm"
)

// ErrNotFound is returned when a game does not exist.
var ErrNotFound = errors.New("game not found")

// Service holds library business logic backed by a GORM connection.
type Service struct {
	db *gorm.DB
}

// NewService creates a library Service.
func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

// ListFilter carries optional query filters for ListGames.
type ListFilter struct {
	Query      string   // matches Title (case-insensitive substring)
	MinPlayers *int     // games supporting at least this many players (MaxPlayers >= n)
	MaxPlayers *int     // games playable with at most this many players (MinPlayers <= n)
	Genres     string   // substring match on the genres JSON string
	Complexity *float64 // exact complexity match
}

// ListGames returns games matching the filter, ordered by title.
func (s *Service) ListGames(f ListFilter) ([]Game, error) {
	q := s.db.Model(&Game{})

	if t := strings.TrimSpace(f.Query); t != "" {
		q = q.Where("LOWER(title) LIKE ?", "%"+strings.ToLower(t)+"%")
	}
	if f.MinPlayers != nil {
		q = q.Where("max_players >= ?", *f.MinPlayers)
	}
	if f.MaxPlayers != nil {
		q = q.Where("min_players <= ?", *f.MaxPlayers)
	}
	if g := strings.TrimSpace(f.Genres); g != "" {
		q = q.Where("LOWER(genres) LIKE ?", "%"+strings.ToLower(g)+"%")
	}
	if f.Complexity != nil {
		q = q.Where("complexity = ?", *f.Complexity)
	}

	var games []Game
	if err := q.Order("title ASC").Find(&games).Error; err != nil {
		return nil, fmt.Errorf("list games: %w", err)
	}
	return games, nil
}

// GetGame returns a single game by primary key.
func (s *Service) GetGame(id uint) (*Game, error) {
	var g Game
	err := s.db.First(&g, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("get game: %w", err)
	}
	return &g, nil
}

// CreateGame persists a new game.
func (s *Service) CreateGame(g *Game) (*Game, error) {
	if err := s.db.Create(g).Error; err != nil {
		return nil, fmt.Errorf("create game: %w", err)
	}
	return g, nil
}

// UpdateGame applies partial updates to an existing game (admin only).
func (s *Service) UpdateGame(id uint, in *Game) (*Game, error) {
	result := s.db.Model(&Game{}).Where("id = ?", id).Updates(map[string]any{
		"title":           in.Title,
		"cover_image_url": in.CoverImageURL,
		"min_players":     in.MinPlayers,
		"max_players":     in.MaxPlayers,
		"duration_min":    in.DurationMin,
		"complexity":      in.Complexity,
		"genres":          in.Genres,
		"owned_status":    in.OwnedStatus,
		"description":     in.Description,
		"rules_notes":     in.RulesNotes,
	})
	if result.Error != nil {
		return nil, fmt.Errorf("update game: %w", result.Error)
	}
	if result.RowsAffected == 0 {
		return nil, ErrNotFound
	}
	return s.GetGame(id)
}

// DeleteGame removes a game from the collection.
func (s *Service) DeleteGame(id uint) error {
	result := s.db.Delete(&Game{}, id)
	if result.Error != nil {
		return fmt.Errorf("delete game: %w", result.Error)
	}
	if result.RowsAffected == 0 {
		return ErrNotFound
	}
	return nil
}
