package vote

import (
	"errors"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// Handler exposes HTTP endpoints for voting.
type Handler struct {
	svc *Service
}

// NewHandler creates a vote Handler.
func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// pollResponse augments a poll option list with computed vote counts.
type optionResponse struct {
	VoteOption
	VoteCount int `json:"vote_count"`
}

type pollResponse struct {
	*VotePoll
	Options []optionResponse `json:"options"`
}

func toPollResponse(p *VotePoll) pollResponse {
	opts := make([]optionResponse, 0, len(p.Options))
	for i := range p.Options {
		opts = append(opts, optionResponse{
			VoteOption: p.Options[i],
			VoteCount:  len(p.Options[i].Votes),
		})
	}
	return pollResponse{VotePoll: p, Options: opts}
}

// GetCurrentPoll returns the active poll (public).
func (h *Handler) GetCurrentPoll(c *gin.Context) {
	p, err := h.svc.GetCurrentPoll()
	if err != nil {
		if errors.Is(err, ErrPollNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "no active poll"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not get poll"})
		return
	}
	c.JSON(http.StatusOK, toPollResponse(p))
}

type castReq struct {
	OptionID uint `json:"option_id" binding:"required"`
}

// CastVote records the authenticated member's vote.
func (h *Handler) CastVote(c *gin.Context) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	pollID, err := strconv.ParseUint(c.Param("pollId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid poll id"})
		return
	}
	var req castReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = h.svc.CastVote(uint(pollID), req.OptionID, mid)
	switch {
	case err == nil:
	case errors.Is(err, ErrPollNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "poll not found"})
		return
	case errors.Is(err, ErrPollClosed):
		c.JSON(http.StatusConflict, gin.H{"error": "poll is closed"})
		return
	case errors.Is(err, ErrAlreadyVoted):
		c.JSON(http.StatusConflict, gin.H{"error": "already voted in this poll"})
		return
	case errors.Is(err, ErrOptionNotInPoll):
		c.JSON(http.StatusBadRequest, gin.H{"error": "option does not belong to this poll"})
		return
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not cast vote"})
		return
	}

	res, err := h.svc.GetResults(uint(pollID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not load results"})
		return
	}
	c.JSON(http.StatusOK, res)
}

type createPollReq struct {
	Title       string    `json:"title" binding:"required"`
	Description string    `json:"description"`
	EndsAt      time.Time `json:"ends_at" binding:"required"`
	GameIDs     []uint    `json:"game_ids" binding:"required"`
}

// CreatePoll creates a new poll (admin only).
func (h *Handler) CreatePoll(c *gin.Context) {
	mid, ok := memberID(c)
	if !ok {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "authentication required"})
		return
	}
	var req createPollReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	p, err := h.svc.CreatePoll(CreatePollInput{
		Title:       req.Title,
		Description: req.Description,
		EndsAt:      req.EndsAt,
		GameIDs:     req.GameIDs,
	}, mid)
	if err != nil {
		if errors.Is(err, ErrInvalidInput) {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not create poll"})
		return
	}
	c.JSON(http.StatusCreated, toPollResponse(p))
}

// GetResults returns the tally for a poll.
func (h *Handler) GetResults(c *gin.Context) {
	pollID, err := strconv.ParseUint(c.Param("pollId"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid poll id"})
		return
	}
	res, err := h.svc.GetResults(uint(pollID))
	if err != nil {
		if errors.Is(err, ErrPollNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "poll not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not get results"})
		return
	}
	c.JSON(http.StatusOK, res)
}

// ListPolls returns all polls (admin only).
func (h *Handler) ListPolls(c *gin.Context) {
	polls, err := h.svc.ListPolls()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not list polls"})
		return
	}
	out := make([]pollResponse, 0, len(polls))
	for i := range polls {
		out = append(out, toPollResponse(&polls[i]))
	}
	c.JSON(http.StatusOK, out)
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
