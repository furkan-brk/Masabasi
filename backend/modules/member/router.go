package member

import (
	"github.com/gin-gonic/gin"
	"github.com/masabasi/backend/pkg/middleware"
)

// RegisterRoutes mounts auth and member endpoints under the given /api/v1 group.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, jwtSecret string) {
	auth := rg.Group("/auth")
	{
		auth.POST("/register", h.Register)
		auth.POST("/login", h.Login)
	}

	me := rg.Group("/me", middleware.RequireAuth(jwtSecret))
	{
		me.GET("", h.GetMe)
		me.PATCH("", h.UpdateMe)
		me.POST("/avatar", h.UploadAvatar)
	}
}
