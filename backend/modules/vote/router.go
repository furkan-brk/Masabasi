package vote

import (
	"github.com/gin-gonic/gin"
	"github.com/masabasi/backend/pkg/middleware"
)

// RegisterRoutes mounts vote endpoints under /api/v1.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, jwtSecret string) {
	// Public
	rg.GET("/votes/current", h.GetCurrentPoll)
	rg.GET("/votes/:pollId/results", h.GetResults)

	// Authenticated
	auth := rg.Group("", middleware.RequireAuth(jwtSecret))
	auth.POST("/votes/:pollId/cast", h.CastVote)

	// Admin
	admin := rg.Group("", middleware.RequireAuth(jwtSecret), middleware.RequireAdmin())
	admin.POST("/votes", h.CreatePoll)
	admin.GET("/votes", h.ListPolls)
}
