package table

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/masabasi/backend/pkg/auth"
	"github.com/masabasi/backend/pkg/middleware"
)

// RegisterRoutes mounts table endpoints under the given /api/v1 group.
func RegisterRoutes(rg *gin.RouterGroup, h *Handler, jwtSecret string) {
	// Reads are public, but ?tab=mine needs an identity, so attach optional auth.
	rg.GET("/tables", optionalAuth(jwtSecret), h.ListTables)
	rg.GET("/tables/:id", h.GetTable)

	authed := rg.Group("", middleware.RequireAuth(jwtSecret))
	authed.POST("/tables", h.CreateTable)
	authed.POST("/tables/:id/join", h.JoinTable)
	authed.DELETE("/tables/:id/leave", h.LeaveTable)
	authed.DELETE("/tables/:id", h.DeleteTable)
	authed.PATCH("/tables/:id", h.UpdateTable)
}

// optionalAuth sets member_id/role when a valid Bearer token is present but
// never rejects the request, so public reads still work without a token.
func optionalAuth(secret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		parts := strings.SplitN(header, " ", 2)
		if len(parts) == 2 && strings.EqualFold(parts[0], "Bearer") {
			if claims, err := auth.Parse(secret, parts[1]); err == nil {
				c.Set("member_id", claims.MemberID)
				c.Set("role", claims.Role)
			}
		}
		c.Next()
	}
}
