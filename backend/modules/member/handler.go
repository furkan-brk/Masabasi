package member

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/masabasi/backend/pkg/auth"
	"github.com/masabasi/backend/pkg/storage"
)

// Handler exposes HTTP endpoints for member auth and profile management.
type Handler struct {
	svc       *Service
	jwtSecret string
	storage   *storage.Client
}

// NewHandler creates a member Handler.
func NewHandler(svc *Service, jwtSecret string, storage *storage.Client) *Handler {
	return &Handler{svc: svc, jwtSecret: jwtSecret, storage: storage}
}

type registerReq struct {
	Email       string `json:"email" binding:"required,email"`
	Password    string `json:"password" binding:"required,min=6"`
	DisplayName string `json:"display_name" binding:"required"`
}

// Register creates a member and returns a JWT.
func (h *Handler) Register(c *gin.Context) {
	var req registerReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	m, err := h.svc.Register(RegisterInput{
		Email:       req.Email,
		Password:    req.Password,
		DisplayName: req.DisplayName,
	})
	if err != nil {
		if errors.Is(err, ErrEmailTaken) {
			c.JSON(http.StatusConflict, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not register member"})
		return
	}
	h.respondWithToken(c, http.StatusCreated, m)
}

type loginReq struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

// Login verifies credentials and returns a JWT.
func (h *Handler) Login(c *gin.Context) {
	var req loginReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	m, err := h.svc.Login(req.Email, req.Password)
	if err != nil {
		if errors.Is(err, ErrInvalidCredentials) {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not log in"})
		return
	}
	h.respondWithToken(c, http.StatusOK, m)
}

// GetMe returns the authenticated member.
func (h *Handler) GetMe(c *gin.Context) {
	id := c.GetUint("member_id")
	m, err := h.svc.GetByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "member not found"})
		return
	}
	c.JSON(http.StatusOK, m)
}

type updateReq struct {
	DisplayName     *string `json:"display_name"`
	AvatarURL       *string `json:"avatar_url"`
	Bio             *string `json:"bio"`
	ExperienceLevel *string `json:"experience_level"`
	FavoriteGenres  *string `json:"favorite_genres"`
}

// UpdateMe applies a partial profile update for the authenticated member.
func (h *Handler) UpdateMe(c *gin.Context) {
	var req updateReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	id := c.GetUint("member_id")
	m, err := h.svc.UpdateMe(id, UpdateInput{
		DisplayName:     req.DisplayName,
		AvatarURL:       req.AvatarURL,
		Bio:             req.Bio,
		ExperienceLevel: req.ExperienceLevel,
		FavoriteGenres:  req.FavoriteGenres,
	})
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "member not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not update member"})
		return
	}
	c.JSON(http.StatusOK, m)
}

// UploadAvatar handles POST /me/avatar — uploads profile image to MinIO, updates avatar_url.
func (h *Handler) UploadAvatar(c *gin.Context) {
	if h.storage == nil {
		c.JSON(http.StatusNotImplemented, gin.H{"error": "avatar upload not configured"})
		return
	}
	id := c.GetUint("member_id")

	if err := c.Request.ParseMultipartForm(5 << 20); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "file too large (max 5MB) or invalid request"})
		return
	}
	file, header, err := c.Request.FormFile("avatar")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "avatar field required"})
		return
	}
	defer file.Close()

	ext := strings.ToLower(filepath.Ext(header.Filename))
	var contentType string
	switch ext {
	case ".jpg", ".jpeg":
		contentType = "image/jpeg"
	case ".png":
		contentType = "image/png"
	case ".webp":
		contentType = "image/webp"
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "only jpg, png, webp images are allowed"})
		return
	}

	data, err := io.ReadAll(file)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not read file"})
		return
	}

	objectName := fmt.Sprintf("avatars/%d%s", id, ext)
	url, err := h.storage.UploadAvatar(c.Request.Context(), objectName, data, contentType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not upload avatar"})
		return
	}

	m, err := h.svc.UpdateMe(id, UpdateInput{AvatarURL: &url})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not update profile"})
		return
	}
	c.JSON(http.StatusOK, m)
}

func (h *Handler) respondWithToken(c *gin.Context, status int, m *Member) {
	token, err := auth.Generate(h.jwtSecret, m.ID, m.Role)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not issue token"})
		return
	}
	c.JSON(status, gin.H{"token": token, "member": m})
}
