package favorite

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

// List returns all favorited games for the authenticated member.
func (h *Handler) List(c *gin.Context) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	games, err := h.svc.ListGames(mid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not list favorites"})
		return
	}
	c.JSON(http.StatusOK, games)
}

// Add adds a game to the authenticated member's favorites.
func (h *Handler) Add(c *gin.Context) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	gameID, err := strconv.ParseUint(c.Param("gameId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid game id"})
		return
	}
	if err := h.svc.Add(mid, uint(gameID)); err != nil {
		if errors.Is(err, ErrGameNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "game not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not add favorite"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"ok": true})
}

// Remove removes a game from the authenticated member's favorites.
func (h *Handler) Remove(c *gin.Context) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	gameID, err := strconv.ParseUint(c.Param("gameId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid game id"})
		return
	}
	if err := h.svc.Remove(mid, uint(gameID)); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not remove favorite"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

func memberID(c *gin.Context) (uint, bool) {
	v, ok := c.Get("member_id")
	if !ok {
		return 0, false
	}
	id, ok := v.(uint)
	return id, ok
}
