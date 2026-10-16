package library

import (
	"github.com/gin-gonic/gin"
	"github.com/masabasi/backend/pkg/middleware"
)

// RegisterRoutes mounts library endpoints under the given /api/v1 group.
// jwtSecret is used by the admin-only create route.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, jwtSecret string) {
	rg.GET("/games", h.ListGames)
	rg.GET("/games/:id", h.GetGame)
	rg.POST("/games", middleware.RequireAuth(jwtSecret), middleware.RequireAdmin(), h.CreateGame)
	rg.PATCH("/games/:id", middleware.RequireAuth(jwtSecret), middleware.RequireAdmin(), h.UpdateGame)
	rg.DELETE("/games/:id", middleware.RequireAuth(jwtSecret), middleware.RequireAdmin(), h.DeleteGame)
}
