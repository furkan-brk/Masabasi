// Command server runs the Masabaşı Oyun Kulübü backend (gin + GORM + JWT).
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"strings"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/masabasi/backend/modules/favorite"
	"github.com/masabasi/backend/modules/gamemaster"
	"github.com/masabasi/backend/modules/library"
	"github.com/masabasi/backend/modules/member"
	"github.com/masabasi/backend/modules/notification"
	"github.com/masabasi/backend/modules/table"
	"github.com/masabasi/backend/modules/vote"
	"github.com/masabasi/backend/pkg/config"
	"github.com/masabasi/backend/pkg/database"
	"github.com/masabasi/backend/pkg/middleware"
	"github.com/masabasi/backend/pkg/storage"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func main() {
	cfg := config.Load()

	db, err := database.Connect(cfg.DBURL)
	if err != nil {
		log.Fatalf("database connect: %v", err)
	}
	if err := db.AutoMigrate(
		&member.Member{},
		&library.Game{},
		&table.GameTable{},
		&table.TableSeat{},
		&vote.VotePoll{},
		&vote.VoteOption{},
		&vote.Vote{},
		&notification.Notification{},
		&favorite.Favorite{},
	); err != nil {
		log.Fatalf("auto migrate: %v", err)
	}

	if os.Getenv("SEED") == "true" {
		if err := seed(db); err != nil {
			log.Printf("seed: %v", err)
		}
	}

	memberSvc := member.NewService(db)
	storageClt, err := storage.NewMinioClient(
		cfg.MinioEndpoint,
		cfg.MinioAccessKey,
		cfg.MinioSecretKey,
		cfg.MinioBucket,
		cfg.MinioPublicURL,
	)
	if err != nil {
		log.Printf("WARNING: MinIO unavailable (%v) — avatar upload disabled", err)
	}
	librarySvc := library.NewService(db)
	tableSvc := table.NewService(db)
	voteSvc := vote.NewService(db)
	notifSvc := notification.NewService(db)
	favoriteSvc := favorite.NewService(db)
	memberHandler := member.NewHandler(memberSvc, cfg.JWTSecret, storageClt)
	libraryHandler := library.NewHandler(librarySvc)
	tableHandler := table.NewHandler(tableSvc)
	voteHandler := vote.NewHandler(voteSvc)
	notifHandler := notification.NewHandler(notifSvc)
	favoriteHandler := favorite.NewHandler(favoriteSvc)
	libAdapter := &libraryAdapter{svc: librarySvc}
	var gamemasterClient gamemaster.Client
	if cfg.GameMasterMode == "gemini" {
		c, err := gamemaster.NewDirectGeminiAdapter(
			cfg.GeminiServiceAccountJSON,
			cfg.GeminiProjectID,
			cfg.GeminiRegion,
			cfg.GeminiModel,
			libAdapter,
		)
		if err != nil {
			log.Printf("WARNING: Gemini adapter init failed (%v) — falling back to Claude", err)
			gamemasterClient = gamemaster.NewDirectClaudeAdapter(cfg.ClaudeAPIKey)
		} else {
			gamemasterClient = c
		}
	} else {
		gamemasterClient = gamemaster.NewDirectClaudeAdapter(cfg.ClaudeAPIKey)
	}
	gamemasterHandler := gamemaster.NewHandler(gamemasterClient)

	r := gin.Default()
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{cfg.CORSOrigin},
		AllowMethods:     []string{"GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		AllowCredentials: cfg.CORSOrigin != "*",
	}))

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	v1 := r.Group("/api/v1")

	// Auth (public).
	v1.POST("/auth/register", memberHandler.Register)
	v1.POST("/auth/login", memberHandler.Login)

	// Member (JWT required).
	me := v1.Group("")
	me.Use(middleware.RequireAuth(cfg.JWTSecret))
	me.GET("/me", memberHandler.GetMe)
	me.PATCH("/me", memberHandler.UpdateMe)
	me.POST("/me/avatar", memberHandler.UploadAvatar)

	// Library (public reads, admin-gated create).
	library.RegisterRoutes(v1, libraryHandler, cfg.JWTSecret)

	// Tables (public reads, JWT-gated create/join/leave/update).
	table.RegisterRoutes(v1, tableHandler, cfg.JWTSecret)

	// Votes (public read current, JWT-gated cast, admin create/list).
	vote.RegisterRoutes(v1, voteHandler, cfg.JWTSecret)

	// Notifications (all JWT-gated).
	notification.RegisterRoutes(v1, notifHandler, cfg.JWTSecret)

	// Game master (AI Oyun Ustası, JWT-gated).
	gamemaster.RegisterRoutes(v1, gamemasterHandler, cfg.JWTSecret)

	// Favorites (all JWT-gated).
	favorite.RegisterRoutes(v1, favoriteHandler, cfg.JWTSecret)

	log.Printf("Masabaşı backend listening on :%s", cfg.Port)
	server := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           r,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       2 * time.Minute,
		WriteTimeout:      10 * time.Minute,
		IdleTimeout:       2 * time.Minute,
		MaxHeaderBytes:    1 << 20,
	}
	if err := server.ListenAndServe(); err != nil {
		log.Fatalf("server run: %v", err)
	}
}

// libraryAdapter bridges library.Service → gamemaster.LibrarySource.
type libraryAdapter struct{ svc *library.Service }

func (a *libraryAdapter) SearchGames(f gamemaster.LibraryFilter) ([]gamemaster.LibraryGame, error) {
	lf := library.ListFilter{
		Query:      f.Query,
		MinPlayers: f.MinPlayers,
		MaxPlayers: f.MaxPlayers,
		Genres:     f.Genres,
	}
	if f.Complexity != nil {
		v := float64(*f.Complexity)
		lf.Complexity = &v
	}
	games, err := a.svc.ListGames(lf)
	if err != nil {
		return nil, err
	}
	out := make([]gamemaster.LibraryGame, 0, len(games))
	for _, g := range games {
		out = append(out, gamemaster.LibraryGame{
			Title:       g.Title,
			MinPlayers:  g.MinPlayers,
			MaxPlayers:  g.MaxPlayers,
			DurationMin: g.DurationMin,
			Complexity:  int(g.Complexity),
			Genres:      g.Genres,
		})
	}
	return out, nil
}

// seed inserts the full club game library and an admin member if the DB is empty.
func seed(db *gorm.DB) error {
	var gameCount int64
	db.Model(&library.Game{}).Count(&gameCount)
	if gameCount == 0 {
		games := make([]library.Game, 0, len(fullGameList))
		for _, e := range fullGameList {
			games = append(games, library.Game{
				Title:       e.Title,
				MinPlayers:  e.MinPlayers,
				MaxPlayers:  e.MaxPlayers,
				Complexity:  float64(e.Complexity),
				Genres:      e.Genres,
				OwnedStatus: "Mevcut",
			})
		}
		if err := db.CreateInBatches(&games, 50).Error; err != nil {
			return fmt.Errorf("seed games: %w", err)
		}
		log.Printf("seeded %d games", len(games))
	}

	var memberCount int64
	db.Model(&member.Member{}).Count(&memberCount)
	if memberCount == 0 {
		hash, err := bcrypt.GenerateFromPassword([]byte("admin1234"), 12)
		if err != nil {
			return fmt.Errorf("seed hash: %w", err)
		}
		admin := member.Member{
			Email:           "admin@masabasi.club",
			PasswordHash:    string(hash),
			DisplayName:     "Kulüp Yöneticisi",
			ExperienceLevel: "Usta",
			ClubStatus:      "Aktif Üye",
			Role:            "admin",
		}
		if err := db.Create(&admin).Error; err != nil {
			return fmt.Errorf("seed admin: %w", err)
		}
	}

	// Ensure furkanberk20@gmail.com is admin
	if err := db.Model(&member.Member{}).Where("email = ?", "furkanberk20@gmail.com").Update("role", "admin").Error; err != nil {
		log.Printf("WARNING: failed to ensure admin role for furkanberk20@gmail.com: %v", err)
	}

	// Ensure local game cover URLs are correctly mapped and self-heal from localhost leakages
	publicURL := os.Getenv("MINIO_PUBLIC_URL")
	if publicURL == "" {
		publicURL = "http://localhost:9000/masabasi"
	}
	localCovers := map[string]string{
		"Anlatamaz ki!":     "Anlatamaz Ki!.jpg",
		"Ben Daha Önce Hiç": "Ben daha önce hiç!.jpg",
		"Bomba":             "Bomba.jpg",
		"Fenomen Kim":       "Fenomen Kim.jpg",
		"Frog Balance Game": "Frog Balance Game.jpg",
		"Uno Pokemon":       "Uno Pokemon.jpg",
		"Çek Bir Kart":      "Çek bi kart.jpg",
		"Çatlak Yumurta":    "Çatlak Yumurta.jpg",
		"Çiziver":           "Çiziver.jpg",
		"Katerogi X":        "Kategori X.jpg",
		"Kelime Oyunu":      "Kelime Oyunu.jpg",
		"Truva":             "Truva.jpg",
		"Korku Kapanı":      "Korku Kapanı.jpg",
		"Dost Kazığı":       "Dost Kazığı.jpg",
		"Banned Words XL":   "Banner Words XL.jpg",
		"Darkective":        "Darkective.jpg",
		"Destek Köstek!":    "Destek-Köstek.jpg",
		"Bay Böcek Firarda": "Bay Böcek Firarda.jpg",
		"Ejder Avcıları":    "Ejder Avcıları.jpg",
		"Gelişine":          "Gelişine.jpg",
		"Otokrat":           "Otokrat.jpg",
		"Sinners":           "Sinners.jpg",
	}
	for title, filename := range localCovers {
		targetURL := fmt.Sprintf("%s/games/%s", publicURL, filename)
		// Update if empty, null, or if it points to localhost in a production setting
		var checkLike string
		if !strings.Contains(publicURL, "localhost") {
			checkLike = " OR cover_image_url LIKE 'http://localhost%'"
		}
		query := fmt.Sprintf("title = ? AND (cover_image_url = '' OR cover_image_url IS NULL%s)", checkLike)
		if err := db.Model(&library.Game{}).Where(query, title).Update("cover_image_url", targetURL).Error; err != nil {
			log.Printf("WARNING: failed to update cover URL for %s: %v", title, err)
		}
	}

	if err := seedTables(db); err != nil {
		return err
	}
	return nil
}

// seedTables inserts a couple of sample tables hosted by the admin if none exist.
func seedTables(db *gorm.DB) error {
	var tableCount int64
	db.Model(&table.GameTable{}).Count(&tableCount)
	if tableCount > 0 {
		return nil
	}

	var firstGame library.Game
	if err := db.Order("id ASC").First(&firstGame).Error; err != nil {
		return nil // no games to attach tables to
	}
	var admin member.Member
	if err := db.Where("role = ?", "admin").First(&admin).Error; err != nil {
		return nil // no host available
	}

	svc := table.NewService(db)
	samples := []table.CreateInput{
		{
			GameID:      firstGame.ID,
			HostID:      admin.ID,
			ScheduledAt: time.Now().Add(24 * time.Hour),
			Location:    "Kulüp Salonu",
			TableNo:     "Masa 1",
			Capacity:    4,
			Notes:       "Yeni başlayanlar bekleniyor.",
		},
		{
			GameID:      firstGame.ID,
			HostID:      admin.ID,
			ScheduledAt: time.Now().Add(48 * time.Hour),
			Location:    "Kulüp Salonu",
			TableNo:     "Masa 2",
			Capacity:    4,
			Notes:       "Deneyimli oyuncu masası.",
		},
	}
	for _, in := range samples {
		if _, err := svc.CreateTable(in); err != nil {
			return fmt.Errorf("seed table: %w", err)
		}
	}
	return nil
}
