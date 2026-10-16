package favorite

import (
	"github.com/gin-gonic/gin"
	"github.com/masabasi/backend/pkg/middleware"
)

// RegisterRoutes mounts favorite endpoints under /api/v1.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, jwtSecret string) {
	g := rg.Group("/me/favorites")
	g.Use(middleware.RequireAuth(jwtSecret))
	g.GET("", h.List)
	g.POST("/:gameId", h.Add)
	g.DELETE("/:gameId", h.Remove)
}
