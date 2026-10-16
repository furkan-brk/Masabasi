package gamemaster

import (
	"github.com/gin-gonic/gin"
	"github.com/masabasi/backend/pkg/middleware"
)

// RegisterRoutes mounts gamemaster endpoints under /api/v1 (JWT-gated).
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, jwtSecret string) {
	auth := rg.Group("", middleware.RequireAuth(jwtSecret))
	auth.POST("/gamemaster/chat", h.Chat)
}
