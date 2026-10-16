package table

import (
	"errors"
	"fmt"
	"time"

	"github.com/masabasi/backend/modules/library"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// Service-level errors.
var (
	ErrTableNotFound = errors.New("table not found")
	ErrTableFull     = errors.New("table is full")
	ErrAlreadyJoined = errors.New("already joined this table")
	ErrNotJoined     = errors.New("not in this table")
	ErrNotHost       = errors.New("only the host can do this")
	ErrConflict      = errors.New("table was modified concurrently")
	ErrGameNotFound  = errors.New("game not found")
	ErrInvalidInput  = errors.New("invalid input")
)

// Service holds game-table business logic backed by a GORM connection.
type Service struct {
	db *gorm.DB
}

// NewService creates a table Service.
func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

// ListFilter carries query filters for ListTables.
type ListFilter struct {
	Tab      string // "open" (default) | "mine"
	MemberID uint   // required for the "mine" tab
	GameID   uint   // optional game filter
}

// ListTables returns tables matching the filter, ordered by scheduled time.
func (s *Service) ListTables(f ListFilter) ([]GameTable, error) {
	q := s.db.Model(&GameTable{}).
		Preload("Game").
		Preload("Host").
		Preload("Seats").
		Preload("Seats.Member")

	if f.GameID != 0 {
		q = q.Where("game_id = ?", f.GameID)
	}

	switch f.Tab {
	case "mine":
		seatSub := s.db.Model(&TableSeat{}).
			Select("table_id").
			Where("member_id = ?", f.MemberID)
		q = q.Where("host_id = ? OR id IN (?)", f.MemberID, seatSub)
	case "all":
		// admin: tüm masalar, status filtresi yok
	default: // "open"
		q = q.Where("status = ? OR (status = ? AND scheduled_at > ?)",
			StatusWaiting, StatusFull, time.Now())
	}

	var tables []GameTable
	if err := q.Order("scheduled_at ASC").Find(&tables).Error; err != nil {
		return nil, fmt.Errorf("list tables: %w", err)
	}
	return tables, nil
}

// GetTable returns a single table with its game, host, and seated members.
func (s *Service) GetTable(id uint) (*GameTable, error) {
	var t GameTable
	err := s.db.
		Preload("Game").
		Preload("Host").
		Preload("Seats").
		Preload("Seats.Member").
		First(&t, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrTableNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("get table: %w", err)
	}
	return &t, nil
}

// CreateInput is the payload for CreateTable.
type CreateInput struct {
	GameID      uint
	HostID      uint
	ScheduledAt time.Time
	Location    string
	TableNo     string
	Capacity    int
	Notes       string
	HouseRules  []string
}

// CreateTable persists a new table and seats the host automatically.
func (s *Service) CreateTable(in CreateInput) (*GameTable, error) {
	if in.Capacity < 2 || in.Capacity > 8 {
		return nil, fmt.Errorf("%w: capacity must be between 2 and 8", ErrInvalidInput)
	}

	var game library.Game
	if err := s.db.First(&game, in.GameID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrGameNotFound
		}
		return nil, fmt.Errorf("create table: lookup game: %w", err)
	}

	t := &GameTable{
		GameID:      in.GameID,
		HostID:      in.HostID,
		ScheduledAt: in.ScheduledAt,
		Location:    in.Location,
		TableNo:     in.TableNo,
		Capacity:    in.Capacity,
		Notes:       in.Notes,
		HouseRules:  in.HouseRules,
		Status:      StatusWaiting,
	}
	if err := s.db.Create(t).Error; err != nil {
		return nil, fmt.Errorf("create table: %w", err)
	}

	if err := s.JoinTableTx(t.ID, in.HostID); err != nil {
		return nil, fmt.Errorf("create table: seat host: %w", err)
	}

	return s.GetTable(t.ID)
}

// JoinTableTx atomically seats a member at a table.
func (s *Service) JoinTableTx(tableID, memberID uint) error {
	return s.db.Transaction(func(tx *gorm.DB) error {
		var t GameTable
		err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&t, tableID).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrTableNotFound
		}
		if err != nil {
			return fmt.Errorf("join: load table: %w", err)
		}

		if t.Status == StatusFull || t.Status == StatusFinished {
			return ErrTableFull
		}

		var count int64
		if err := tx.Model(&TableSeat{}).Where("table_id = ?", tableID).Count(&count).Error; err != nil {
			return fmt.Errorf("join: count seats: %w", err)
		}
		if count >= int64(t.Capacity) {
			if err := tx.Model(&t).Update("status", StatusFull).Error; err != nil {
				return fmt.Errorf("join: mark full: %w", err)
			}
			return ErrTableFull
		}

		var existing int64
		if err := tx.Model(&TableSeat{}).
			Where("table_id = ? AND member_id = ?", tableID, memberID).
			Count(&existing).Error; err != nil {
			return fmt.Errorf("join: check existing: %w", err)
		}
		if existing > 0 {
			return ErrAlreadyJoined
		}

		if err := tx.Create(&TableSeat{TableID: tableID, MemberID: memberID}).Error; err != nil {
			return fmt.Errorf("join: insert seat: %w", err)
		}

		if count+1 >= int64(t.Capacity) {
			if err := tx.Model(&t).Update("status", StatusFull).Error; err != nil {
				return fmt.Errorf("join: mark full: %w", err)
			}
		}
		return nil
	})
}

// LeaveTableTx atomically removes a member's seat. The host cannot leave.
func (s *Service) LeaveTableTx(tableID, memberID uint) error {
	return s.db.Transaction(func(tx *gorm.DB) error {
		var t GameTable
		err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).First(&t, tableID).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrTableNotFound
		}
		if err != nil {
			return fmt.Errorf("leave: load table: %w", err)
		}

		if memberID == t.HostID {
			return ErrNotHost
		}

		res := tx.Where("table_id = ? AND member_id = ?", tableID, memberID).Delete(&TableSeat{})
		if res.Error != nil {
			return fmt.Errorf("leave: delete seat: %w", res.Error)
		}
		if res.RowsAffected == 0 {
			return ErrNotJoined
		}

		if t.Status == StatusFull {
			if err := tx.Model(&t).Update("status", StatusWaiting).Error; err != nil {
				return fmt.Errorf("leave: mark waiting: %w", err)
			}
		}
		return nil
	})
}

// DeleteTable atomically removes all seats then the table itself.
func (s *Service) DeleteTable(id uint) error {
	return s.db.Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("table_id = ?", id).Delete(&TableSeat{}).Error; err != nil {
			return fmt.Errorf("delete table: seats: %w", err)
		}
		result := tx.Delete(&GameTable{}, id)
		if result.Error != nil {
			return fmt.Errorf("delete table: %w", result.Error)
		}
		if result.RowsAffected == 0 {
			return ErrTableNotFound
		}
		return nil
	})
}

// UpdateInput is the payload for UpdateTable.
type UpdateInput struct {
	ScheduledAt time.Time
	Location    string
	TableNo     string
	Capacity    int
	Notes       string
	HouseRules  []string
}

// UpdateTable applies host-only edits guarded by optimistic concurrency.
func (s *Service) UpdateTable(id, hostID uint, ifMatch uint64, in UpdateInput) (*GameTable, error) {
	if in.Capacity < 2 || in.Capacity > 8 {
		return nil, fmt.Errorf("%w: capacity must be between 2 and 8", ErrInvalidInput)
	}

	var t GameTable
	err := s.db.First(&t, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrTableNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("update table: load: %w", err)
	}
	if t.HostID != hostID {
		return nil, ErrNotHost
	}

	res := s.db.Model(&GameTable{}).
		Where("id = ? AND revision_id = ?", id, ifMatch).
		Updates(map[string]any{
			"scheduled_at": in.ScheduledAt,
			"location":     in.Location,
			"table_no":     in.TableNo,
			"capacity":     in.Capacity,
			"notes":        in.Notes,
			"house_rules":  in.HouseRules,
			"revision_id":  ifMatch + 1,
		})
	if res.Error != nil {
		return nil, fmt.Errorf("update table: %w", res.Error)
	}
	if res.RowsAffected == 0 {
		return nil, ErrConflict
	}

	return s.GetTable(id)
}
