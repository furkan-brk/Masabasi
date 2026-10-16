package gamemaster

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type chatReq struct {
	History []Message `json:"history" binding:"required"`
}

// Handler exposes the Oyun Ustası chat endpoint.
type Handler struct {
	client Client
}

// NewHandler creates a gamemaster Handler.
func NewHandler(client Client) *Handler {
	return &Handler{client: client}
}

// Chat forwards the conversation history to the AI client and returns the reply.
func (h *Handler) Chat(c *gin.Context) {
	var req chatReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request body"})
		return
	}
	if len(req.History) == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "history is required"})
		return
	}

	reply, err := h.client.Chat(c.Request.Context(), req.History)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "could not reach the game master"})
		return
	}
	c.JSON(http.StatusOK, reply)
}
