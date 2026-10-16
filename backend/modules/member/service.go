package member

import (
	"errors"
	"fmt"
	"strings"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// Errors surfaced by the member service. Handlers map these to HTTP statuses.
var (
	ErrEmailTaken         = errors.New("email already registered")
	ErrInvalidCredentials = errors.New("invalid email or password")
	ErrNotFound           = errors.New("member not found")
)

const bcryptCost = 12

// Service holds member business logic backed by a GORM connection.
type Service struct {
	db *gorm.DB
}

// NewService creates a member Service.
func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

// RegisterInput carries the fields needed to create a member.
type RegisterInput struct {
	Email       string
	Password    string
	DisplayName string
}

// Register creates a new member with a bcrypt-hashed password.
func (s *Service) Register(in RegisterInput) (*Member, error) {
	email := strings.ToLower(strings.TrimSpace(in.Email))

	var existing Member
	err := s.db.Where("email = ?", email).First(&existing).Error
	if err == nil {
		return nil, ErrEmailTaken
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, fmt.Errorf("lookup email: %w", err)
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(in.Password), bcryptCost)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	m := &Member{
		Email:        email,
		PasswordHash: string(hash),
		DisplayName:  strings.TrimSpace(in.DisplayName),
	}
	if err := s.db.Create(m).Error; err != nil {
		return nil, fmt.Errorf("create member: %w", err)
	}
	return m, nil
}

// Login verifies credentials and returns the member on success.
func (s *Service) Login(email, password string) (*Member, error) {
	email = strings.ToLower(strings.TrimSpace(email))

	var m Member
	err := s.db.Where("email = ?", email).First(&m).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrInvalidCredentials
	}
	if err != nil {
		return nil, fmt.Errorf("lookup member: %w", err)
	}
	if bcrypt.CompareHashAndPassword([]byte(m.PasswordHash), []byte(password)) != nil {
		return nil, ErrInvalidCredentials
	}
	return &m, nil
}

// GetByID returns a member by primary key.
func (s *Service) GetByID(id uint) (*Member, error) {
	var m Member
	err := s.db.First(&m, id).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("get member: %w", err)
	}
	return &m, nil
}

// UpdateInput carries optional profile fields. Nil pointers are left unchanged.
type UpdateInput struct {
	DisplayName     *string
	AvatarURL       *string
	Bio             *string
	ExperienceLevel *string
	FavoriteGenres  *string
}

// UpdateMe applies a partial profile update for the given member.
func (s *Service) UpdateMe(id uint, in UpdateInput) (*Member, error) {
	m, err := s.GetByID(id)
	if err != nil {
		return nil, err
	}

	updates := map[string]any{}
	if in.DisplayName != nil {
		updates["display_name"] = strings.TrimSpace(*in.DisplayName)
	}
	if in.AvatarURL != nil {
		updates["avatar_url"] = *in.AvatarURL
	}
	if in.Bio != nil {
		updates["bio"] = *in.Bio
	}
	if in.ExperienceLevel != nil {
		updates["experience_level"] = *in.ExperienceLevel
	}
	if in.FavoriteGenres != nil {
		updates["favorite_genres"] = *in.FavoriteGenres
	}

	if len(updates) == 0 {
		return m, nil
	}
	if err := s.db.Model(m).Updates(updates).Error; err != nil {
		return nil, fmt.Errorf("update member: %w", err)
	}
	return m, nil
}
