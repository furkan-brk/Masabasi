package table

import (
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// Handler exposes HTTP endpoints for game tables.
type Handler struct {
	svc *Service
}

// NewHandler creates a table Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// tableResponse augments a GameTable with the current seat count.
type tableResponse struct {
	*GameTable
	SeatCount int `json:"seat_count"`
}

func toResponse(t *GameTable) tableResponse {
	return tableResponse{GameTable: t, SeatCount: len(t.Seats)}
}

// ListTables returns tables for the requested tab.
func (h *Handler) ListTables(c *gin.Context) {
	tab := c.Query("tab")
	if tab == "all" {
		role, _ := c.Get("role")
		if role != "admin" {
			tab = "open"
		}
	}
	f := ListFilter{Tab: tab}
	if v, err := strconv.ParseUint(c.Query("game_id"), 10, 64); err == nil {
		f.GameID = uint(v)
	}

	if f.Tab == "mine" {
		mid, ok := memberID(c)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required for mine tab"})
			return
		}
		f.MemberID = mid
	}

	tables, err := h.svc.ListTables(f)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not list tables"})
		return
	}

	out := make([]tableResponse, 0, len(tables))
	for i := range tables {
		out = append(out, toResponse(&tables[i]))
	}
	c.JSON(http.StatusOK, out)
}

// GetTable returns a single table by id.
func (h *Handler) GetTable(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid table id"})
		return
	}
	t, err := h.svc.GetTable(uint(id))
	if err != nil {
		if errors.Is(err, ErrTableNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "table not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not get table"})
		return
	}
	c.JSON(http.StatusOK, toResponse(t))
}

type createReq struct {
	GameID      uint      `json:"game_id" binding:"required"`
	ScheduledAt time.Time `json:"scheduled_at" binding:"required"`
	Location    string    `json:"location"`
	TableNo     string    `json:"table_no"`
	Capacity    int       `json:"capacity"`
	Notes       string    `json:"notes"`
	HouseRules  []string  `json:"house_rules"`
}

// CreateTable creates a new table hosted by the authenticated member.
func (h *Handler) CreateTable(c *gin.Context) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	var req createReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Capacity == 0 {
		req.Capacity = 4
	}

	t, err := h.svc.CreateTable(CreateInput{
		GameID:      req.GameID,
		HostID:      mid,
		ScheduledAt: req.ScheduledAt,
		Location:    req.Location,
		TableNo:     req.TableNo,
		Capacity:    req.Capacity,
		Notes:       req.Notes,
		HouseRules:  req.HouseRules,
	})
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidInput):
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		case errors.Is(err, ErrGameNotFound):
			c.JSON(http.StatusBadRequest, gin.H{"error": "game not found"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "could not create table"})
		}
		return
	}
	c.JSON(http.StatusCreated, toResponse(t))
}

// JoinTable seats the authenticated member at a table.
func (h *Handler) JoinTable(c *gin.Context) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid table id"})
		return
	}

	err = h.svc.JoinTableTx(uint(id), mid)
	switch {
	case err == nil:
	case errors.Is(err, ErrTableNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "table not found"})
		return
	case errors.Is(err, ErrTableFull):
		c.JSON(http.StatusConflict, gin.H{"error": "table is full"})
		return
	case errors.Is(err, ErrAlreadyJoined):
		c.JSON(http.StatusConflict, gin.H{"error": "already joined this table"})
		return
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not join table"})
		return
	}

	t, err := h.svc.GetTable(uint(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not load table"})
		return
	}
	c.JSON(http.StatusOK, toResponse(t))
}

// LeaveTable removes the authenticated member's seat.
func (h *Handler) LeaveTable(c *gin.Context) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid table id"})
		return
	}

	err = h.svc.LeaveTableTx(uint(id), mid)
	switch {
	case err == nil:
	case errors.Is(err, ErrTableNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "table not found"})
		return
	case errors.Is(err, ErrNotHost):
		c.JSON(http.StatusForbidden, gin.H{"error": "host cannot leave the table"})
		return
	case errors.Is(err, ErrNotJoined):
		c.JSON(http.StatusConflict, gin.H{"error": "not in this table"})
		return
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not leave table"})
		return
	}

	t, err := h.svc.GetTable(uint(id))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not load table"})
		return
	}
	c.JSON(http.StatusOK, toResponse(t))
}

type updateReq struct {
	ScheduledAt time.Time `json:"scheduled_at" binding:"required"`
	Location    string    `json:"location"`
	TableNo     string    `json:"table_no"`
	Capacity    int       `json:"capacity"`
	Notes       string    `json:"notes"`
	HouseRules  []string  `json:"house_rules"`
}

// UpdateTable applies host-only edits guarded by the If-Match header.
func (h *Handler) UpdateTable(c *gin.Context) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid table id"})
		return
	}
	ifMatch, err := strconv.ParseUint(c.GetHeader("If-Match"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "missing or invalid If-Match header"})
		return
	}

	var req updateReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if req.Capacity == 0 {
		req.Capacity = 4
	}

	t, err := h.svc.UpdateTable(uint(id), mid, ifMatch, UpdateInput{
		ScheduledAt: req.ScheduledAt,
		Location:    req.Location,
		TableNo:     req.TableNo,
		Capacity:    req.Capacity,
		Notes:       req.Notes,
		HouseRules:  req.HouseRules,
	})
	switch {
	case err == nil:
	case errors.Is(err, ErrTableNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "table not found"})
		return
	case errors.Is(err, ErrNotHost):
		c.JSON(http.StatusForbidden, gin.H{"error": "only the host can edit this table"})
		return
	case errors.Is(err, ErrConflict):
		c.JSON(http.StatusConflict, gin.H{"error": "table was modified concurrently"})
		return
	case errors.Is(err, ErrInvalidInput):
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not update table"})
		return
	}
	c.JSON(http.StatusOK, toResponse(t))
}

// DeleteTable removes a table and all its seats (admin only).
func (h *Handler) DeleteTable(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid table id"})
		return
	}
	// Only admin can delete any table.
	role, _ := c.Get("role")
	if role != "admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "admin only"})
		return
	}
	if err := h.svc.DeleteTable(uint(id)); err != nil {
		if errors.Is(err, ErrTableNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "table not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not delete table"})
		return
	}
	c.Status(http.StatusNoContent)
}

// memberID extracts the authenticated member id set by RequireAuth.
func memberID(c *gin.Context) (uint, bool) {
	v, ok := c.Get("member_id")
	if !ok {
		return 0, false
	}
	id, ok := v.(uint)
	return id, ok
}
