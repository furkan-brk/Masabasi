package library

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// Handler exposes HTTP endpoints for the club game library.
type Handler struct {
	svc *Service
}

// NewHandler creates a library Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// ListGames returns games filtered by the query parameters.
func (h *Handler) ListGames(c *gin.Context) {
	f := ListFilter{
		Query:  c.Query("q"),
		Genres: c.Query("genres"),
	}
	if v, ok := parseIntQuery(c, "min_players"); ok {
		f.MinPlayers = &v
	}
	if v, ok := parseIntQuery(c, "max_players"); ok {
		f.MaxPlayers = &v
	}
	if v, ok := parseFloatQuery(c, "complexity"); ok {
		f.Complexity = &v
	}

	games, err := h.svc.ListGames(f)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not list games"})
		return
	}
	c.JSON(http.StatusOK, games)
}

// GetGame returns a single game by id.
func (h *Handler) GetGame(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid game id"})
		return
	}
	g, err := h.svc.GetGame(uint(id))
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "game not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not get game"})
		return
	}
	c.JSON(http.StatusOK, g)
}

type createReq struct {
	Title         string  `json:"title" binding:"required"`
	CoverImageURL string  `json:"cover_image_url"`
	MinPlayers    int     `json:"min_players"`
	MaxPlayers    int     `json:"max_players"`
	DurationMin   int     `json:"duration_min"`
	Complexity    float64 `json:"complexity"`
	Genres        string  `json:"genres"`
	OwnedStatus   string  `json:"owned_status"`
	Description   string  `json:"description"`
	RulesNotes    string  `json:"rules_notes"`
}

// CreateGame adds a new game to the collection (admin only).
func (h *Handler) CreateGame(c *gin.Context) {
	var req createReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	g := &Game{
		Title:         req.Title,
		CoverImageURL: req.CoverImageURL,
		MinPlayers:    req.MinPlayers,
		MaxPlayers:    req.MaxPlayers,
		DurationMin:   req.DurationMin,
		Complexity:    req.Complexity,
		Genres:        req.Genres,
		OwnedStatus:   req.OwnedStatus,
		Description:   req.Description,
		RulesNotes:    req.RulesNotes,
	}
	created, err := h.svc.CreateGame(g)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not create game"})
		return
	}
	c.JSON(http.StatusCreated, created)
}

// UpdateGame applies partial edits to a game (admin only).
func (h *Handler) UpdateGame(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid game id"})
		return
	}
	var req createReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	updated, err := h.svc.UpdateGame(uint(id), &Game{
		Title:         req.Title,
		CoverImageURL: req.CoverImageURL,
		MinPlayers:    req.MinPlayers,
		MaxPlayers:    req.MaxPlayers,
		DurationMin:   req.DurationMin,
		Complexity:    req.Complexity,
		Genres:        req.Genres,
		OwnedStatus:   req.OwnedStatus,
		Description:   req.Description,
		RulesNotes:    req.RulesNotes,
	})
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "game not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not update game"})
		return
	}
	c.JSON(http.StatusOK, updated)
}

// DeleteGame removes a game (admin only).
func (h *Handler) DeleteGame(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid game id"})
		return
	}
	if err := h.svc.DeleteGame(uint(id)); err != nil {
		if errors.Is(err, ErrNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "game not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not delete game"})
		return
	}
	c.Status(http.StatusNoContent)
}

func parseIntQuery(c *gin.Context, key string) (int, bool) {
	raw := c.Query(key)
	if raw == "" {
		return 0, false
	}
	v, err := strconv.Atoi(raw)
	if err != nil {
		return 0, false
	}
	return v, true
}

func parseFloatQuery(c *gin.Context, key string) (float64, bool) {
	raw := c.Query(key)
	if raw == "" {
		return 0, false
	}
	v, err := strconv.ParseFloat(raw, 64)
	if err != nil {
		return 0, false
	}
	return v, true
}
