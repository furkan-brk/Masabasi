package notification

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// Handler exposes HTTP endpoints for notifications.
type Handler struct {
	svc *Service
}

// NewHandler creates a notification Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// List returns the authenticated member's notifications.
func (h *Handler) List(c *gin.Context) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	ns, err := h.svc.List(mid)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not list notifications"})
		return
	}
	c.JSON(http.StatusOK, ns)
}

// MarkAllRead marks all notifications for the authenticated member as read.
func (h *Handler) MarkAllRead(c *gin.Context) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	if err := h.svc.MarkAllRead(mid); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not update notifications"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"ok": true})
}

// Accept marks an invite notification as accepted.
func (h *Handler) Accept(c *gin.Context) {
	h.handleAction(c, true)
}

// Reject marks an invite notification as rejected.
func (h *Handler) Reject(c *gin.Context) {
	h.handleAction(c, false)
}

func (h *Handler) handleAction(c *gin.Context, accept bool) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid notification id"})
		return
	}

	var actionErr error
	if accept {
		actionErr = h.svc.Accept(uint(id), mid)
	} else {
		actionErr = h.svc.Reject(uint(id), mid)
	}
	if actionErr != nil {
		if errors.Is(actionErr, ErrNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "notification not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not update notification"})
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
