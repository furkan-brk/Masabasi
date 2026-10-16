package notification

import (
	"errors"
	"time"

	"gorm.io/gorm"
)

var ErrNotFound = errors.New("notification not found")

// Service holds notification business logic.
type Service struct {
	db *gorm.DB
}

// NewService creates a notification Service.
func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

// List returns all notifications for a member, newest first.
func (s *Service) List(memberID uint) ([]Notification, error) {
	var ns []Notification
	err := s.db.
		Where("member_id = ?", memberID).
		Order("created_at DESC").
		Find(&ns).Error
	return ns, err
}

// MarkAllRead sets read_at=now for all unread notifications of a member.
func (s *Service) MarkAllRead(memberID uint) error {
	now := time.Now()
	return s.db.
		Model(&Notification{}).
		Where("member_id = ? AND read_at IS NULL", memberID).
		Update("read_at", now).Error
}

// MarkRead marks a single notification read.
func (s *Service) MarkRead(id, memberID uint) error {
	now := time.Now()
	res := s.db.
		Model(&Notification{}).
		Where("id = ? AND member_id = ?", id, memberID).
		Update("read_at", now)
	if res.RowsAffected == 0 {
		return ErrNotFound
	}
	return res.Error
}

// Accept marks an invite notification as actioned (accepted).
func (s *Service) Accept(id, memberID uint) error {
	return s.setActioned(id, memberID)
}

// Reject marks an invite notification as actioned (rejected).
func (s *Service) Reject(id, memberID uint) error {
	return s.setActioned(id, memberID)
}

func (s *Service) setActioned(id, memberID uint) error {
	now := time.Now()
	res := s.db.
		Model(&Notification{}).
		Where("id = ? AND member_id = ? AND type = ?", id, memberID, TypeInvite).
		Updates(map[string]any{"actioned": true, "read_at": now})
	if res.RowsAffected == 0 {
		return ErrNotFound
	}
	return res.Error
}

// Create inserts a new notification.
func (s *Service) Create(n *Notification) error {
	return s.db.Create(n).Error
}

// UnreadCount returns the number of unread notifications for a member.
func (s *Service) UnreadCount(memberID uint) (int64, error) {
	var count int64
	err := s.db.Model(&Notification{}).
		Where("member_id = ? AND read_at IS NULL", memberID).
		Count(&count).Error
	return count, err
}
