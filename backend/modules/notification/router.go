package notification

import (
	"github.com/gin-gonic/gin"
	"github.com/masabasi/backend/pkg/middleware"
)

// RegisterRoutes mounts notification endpoints under /api/v1 (all JWT-gated).
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, jwtSecret string) {
	g := rg.Group("/notifications", middleware.RequireAuth(jwtSecret))
	g.GET("", h.List)
	g.POST("/read-all", h.MarkAllRead)
	g.POST("/:id/accept", h.Accept)
	g.POST("/:id/reject", h.Reject)
}
