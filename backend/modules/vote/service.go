package vote

import (
	"errors"
	"fmt"
	"time"

	"gorm.io/gorm"
)

// Service-level errors.
var (
	ErrPollNotFound    = errors.New("poll not found")
	ErrPollClosed      = errors.New("poll is closed")
	ErrAlreadyVoted    = errors.New("already voted in this poll")
	ErrOptionNotInPoll = errors.New("option does not belong to this poll")
	ErrInvalidInput    = errors.New("invalid input")
)

// Service holds voting business logic backed by a GORM connection.
type Service struct {
	db *gorm.DB
}

// NewService creates a vote Service.
func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

// GetCurrentPoll returns the newest active poll that has not yet ended, with
// options, their games, and votes preloaded.
func (s *Service) GetCurrentPoll() (*VotePoll, error) {
	var p VotePoll
	err := s.db.
		Preload("Options", func(db *gorm.DB) *gorm.DB {
			return db.Order("display_order ASC")
		}).
		Preload("Options.Game").
		Preload("Options.Votes").
		Where("status = ? AND ends_at > ?", StatusActive, time.Now()).
		Order("created_at DESC").
		First(&p).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrPollNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("get current poll: %w", err)
	}
	return &p, nil
}

// CastVote atomically records one member's vote on an option of a poll.
func (s *Service) CastVote(pollID, optionID, memberID uint) error {
	return s.db.Transaction(func(tx *gorm.DB) error {
		var p VotePoll
		err := tx.First(&p, pollID).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrPollNotFound
		}
		if err != nil {
			return fmt.Errorf("cast: load poll: %w", err)
		}
		if p.Status != StatusActive || !p.EndsAt.After(time.Now()) {
			return ErrPollClosed
		}

		var opt VoteOption
		err = tx.Where("id = ? AND poll_id = ?", optionID, pollID).First(&opt).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrOptionNotInPoll
		}
		if err != nil {
			return fmt.Errorf("cast: load option: %w", err)
		}

		var voted int64
		err = tx.Model(&Vote{}).
			Joins("JOIN vote_options ON vote_options.id = votes.option_id").
			Where("vote_options.poll_id = ? AND votes.member_id = ?", pollID, memberID).
			Count(&voted).Error
		if err != nil {
			return fmt.Errorf("cast: check existing: %w", err)
		}
		if voted > 0 {
			return ErrAlreadyVoted
		}

		if err := tx.Create(&Vote{OptionID: optionID, MemberID: memberID}).Error; err != nil {
			return fmt.Errorf("cast: insert vote: %w", err)
		}
		return nil
	})
}

// CreatePollInput is the payload for CreatePoll.
type CreatePollInput struct {
	Title       string
	Description string
	EndsAt      time.Time
	GameIDs     []uint
}

// CreatePoll persists a new poll with one option per provided game id.
func (s *Service) CreatePoll(in CreatePollInput, adminID uint) (*VotePoll, error) {
	if in.Title == "" {
		return nil, fmt.Errorf("%w: title is required", ErrInvalidInput)
	}
	if !in.EndsAt.After(time.Now()) {
		return nil, fmt.Errorf("%w: ends_at must be in the future", ErrInvalidInput)
	}
	if len(in.GameIDs) < 2 {
		return nil, fmt.Errorf("%w: at least two game options are required", ErrInvalidInput)
	}

	var p VotePoll
	err := s.db.Transaction(func(tx *gorm.DB) error {
		p = VotePoll{
			Title:       in.Title,
			Description: in.Description,
			EndsAt:      in.EndsAt,
			Status:      StatusActive,
			CreatedByID: adminID,
		}
		if err := tx.Create(&p).Error; err != nil {
			return fmt.Errorf("create poll: %w", err)
		}
		opts := make([]VoteOption, 0, len(in.GameIDs))
		for i, gid := range in.GameIDs {
			opts = append(opts, VoteOption{PollID: p.ID, GameID: gid, DisplayOrder: i})
		}
		if err := tx.Create(&opts).Error; err != nil {
			return fmt.Errorf("create poll options: %w", err)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	return s.getPoll(p.ID)
}

func (s *Service) getPoll(id uint) (*VotePoll, error) {
	var p VotePoll
	err := s.db.
		Preload("Options", func(db *gorm.DB) *gorm.DB {
			return db.Order("display_order ASC")
		}).
		Preload("Options.Game").
		Preload("Options.Votes").
		First(&p, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrPollNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("get poll: %w", err)
	}
	return &p, nil
}

// OptionResult is the tally for a single option.
type OptionResult struct {
	Option    VoteOption `json:"option"`
	VoteCount int        `json:"vote_count"`
	Pct       float64    `json:"pct"`
}

// PollResults is the full breakdown for a poll.
type PollResults struct {
	Poll    *VotePoll      `json:"poll"`
	Options []OptionResult `json:"options"`
}

// GetResults returns vote counts and percentages per option.
func (s *Service) GetResults(pollID uint) (*PollResults, error) {
	p, err := s.getPoll(pollID)
	if err != nil {
		return nil, err
	}

	total := 0
	for i := range p.Options {
		total += len(p.Options[i].Votes)
	}

	results := make([]OptionResult, 0, len(p.Options))
	for i := range p.Options {
		count := len(p.Options[i].Votes)
		pct := 0.0
		if total > 0 {
			pct = float64(count) / float64(total) * 100
		}
		results = append(results, OptionResult{
			Option:    p.Options[i],
			VoteCount: count,
			Pct:       pct,
		})
	}

	return &PollResults{Poll: p, Options: results}, nil
}

// ListPolls returns all polls (newest first) with options and tallies preloaded.
func (s *Service) ListPolls() ([]VotePoll, error) {
	var polls []VotePoll
	err := s.db.
		Preload("Options", func(db *gorm.DB) *gorm.DB {
			return db.Order("display_order ASC")
		}).
		Preload("Options.Game").
		Preload("Options.Votes").
		Order("created_at DESC").
		Find(&polls).Error
	if err != nil {
		return nil, fmt.Errorf("list polls: %w", err)
	}
	return polls, nil
}
