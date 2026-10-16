// Command bgg-seed enriches the games table with data fetched from the
// BoardGameGeek XML API2 (cover image, description, play time).
//
// Usage:
//
//	DB_URL=<postgres-url> BGG_API_TOKEN=<token> go run ./cmd/bgg-seed
//
// BGG_API_TOKEN is REQUIRED since BoardGameGeek closed the XML API to
// anonymous clients (2026): every request — search included — now answers 401
// without a bearer token. Register (free) at boardgamegeek.com/using_the_xml_api.
//
// The command is idempotent: it skips games that already have a CoverImageURL.
package main

import (
	"encoding/xml"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/masabasi/backend/modules/library"
	"github.com/masabasi/backend/pkg/database"

	"github.com/glebarez/sqlite"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// bggOverrides maps Turkish/local game titles to either:
//   - a numeric BGG thing ID string (e.g. "68448") → fetched directly, no search
//   - an English search term (non-numeric) → used instead of the Turkish title for BGG search
var bggOverrides = map[string]string{
	// Türkçe lokalizasyonlar — İngilizce orijinal adı ile ara
	"Vampir Köylü":            "One Night Ultimate Werewolf",
	"Uykucu Kraliçeler":       "Sleeping Queens",
	"Suç Günlükleri":          "Chronicles of Crime",
	"Tabu":                    "Taboo",
	"Tabu XL":                 "Taboo",
	"Direniş":                 "The Resistance",
	"Gulyabani":               "Ultimate Werewolf",
	"Lanetli Ada":             "Forbidden Island",
	"Sahtekar":                "Coup",
	"Entrika":                 "Coup",
	"Harekat: Normandiya":     "D-Day Dice",
	"Kuzey Kaşifleri":         "Cartographers",
	"Kayıp Diyarlar":          "Lost Ruins of Arnak",
	"Keşif: Gezegen 9 Görevi": "Planet Unknown",
	"Kadim Yolculuk":          "Legendary: A Marvel Deck Building Game",
	"İhtilâl":                 "Twilight Struggle",
	"İnkılap":                 "Brass Lancashire",
	"İstanbul Big Box":        "Istanbul",
	"İz Peşinde":              "Detective: A Modern Crime Board Game",
	"Arnak Harabeleri":        "Lost Ruins of Arnak",
	"Ejder Avcıları":          "Dragon Slayer",
	"Korku Kapanı":            "Escape: The Curse of the Temple",
	"Komplo":                  "Intrigue",
	"Satranç":                 "Chess",
	"Metropol":                "Metropolis",
	"Sinners":                 "Sinners",
	"Otokrat":                 "Autocrat",
	"Lichterfest":             "Lanterns: The Harvest Festival",
	"Casus Belli":             "Memoir 44",
	"Astro Drive":             "Space Base",
	"Truva":                   "Troya",
	"İye":                     "Iota",
	"Epik Büyü Savaşları: Kurukafa Dağında Duello": "Epic Spell Wars of the Battle Wizards: Duel at Mt. Skullzfyre",
	"Epik Büyü Savaşları: Ölüm Şatosunda Kapışma":  "Epic Spell Wars of the Battle Wizards: Rumble at Castle Tentakill",

	// Doğrudan BGG thing ID (genel İngilizce kelime olduğu için arama yanıltıcı)
	"Forbidden":  "224517", // Forbidden Sky (en popüler Forbidden serisi)
	"Darkective": "254640", // Darkective
	"Coatl":      "254682", // Coatl
	"Cryptid":    "246784", // Cryptid
	"Biblios":    "63596",  // Biblios
	"Barrage":    "251247", // Barrage
}

// bggToken is read once at startup; empty means the run would 401 on every
// request, so we fail fast instead of burning ~2 minutes to report 91 SKIPs.
var bggToken = strings.TrimSpace(os.Getenv("BGG_API_TOKEN"))

func main() {
	if bggToken == "" {
		log.Fatal("BGG_API_TOKEN is required — the XML API returns 401 for anonymous requests. " +
			"Register for free at https://boardgamegeek.com/using_the_xml_api")
	}

	db, err := connectDB()
	if err != nil {
		log.Fatalf("db connect: %v", err)
	}
	if err := db.AutoMigrate(&library.Game{}); err != nil {
		log.Fatalf("migrate: %v", err)
	}

	var games []library.Game
	db.Where("cover_image_url = '' OR cover_image_url IS NULL").Find(&games)
	log.Printf("enriching %d games without cover images", len(games))

	client := &http.Client{Timeout: 15 * time.Second}
	var unmatched []string

	for i, g := range games {
		log.Printf("[%d/%d] %s", i+1, len(games), g.Title)
		if err := enrich(client, db, &g); err != nil {
			log.Printf("  SKIP: %v", err)
			unmatched = append(unmatched, g.Title)
		}
		time.Sleep(1200 * time.Millisecond) // BGG asks for ≥1s between requests
	}

	log.Printf("done — enriched %d, unmatched %d", len(games)-len(unmatched), len(unmatched))
	if len(unmatched) > 0 {
		log.Printf("UNMATCHED titles (add to bggOverrides):")
		for _, t := range unmatched {
			log.Printf("  - %q", t)
		}
	}
}

func connectDB() (*gorm.DB, error) {
	dbURL := os.Getenv("DB_URL")
	var dialector gorm.Dialector
	if dbURL == "" {
		dialector = sqlite.Open(":memory:")
	} else {
		dialector = postgres.Open(dbURL)
	}
	db, err := gorm.Open(dialector, &gorm.Config{Logger: logger.Default.LogMode(logger.Warn)})
	if err != nil {
		return nil, err
	}
	database.SetForTest(db)
	return db, nil
}

// ── BGG XML types ────────────────────────────────────────────────────────────

type bggSearch struct {
	Items []bggSearchItem `xml:"item"`
}

type bggSearchItem struct {
	ID   string      `xml:"id,attr"`
	Name bggNameAttr `xml:"name"`
}

type bggNameAttr struct {
	Value string `xml:"value,attr"`
}

type bggThing struct {
	Items []bggThingItem `xml:"item"`
}

type bggThingItem struct {
	Thumbnail   string         `xml:"thumbnail"`
	Image       string         `xml:"image"`
	Description string         `xml:"description"`
	PlayingTime bggIntVal      `xml:"playingtime"`
	MinPlayers  bggIntVal      `xml:"minplayers"`
	MaxPlayers  bggIntVal      `xml:"maxplayers"`
	Names       []bggThingName `xml:"name"`
}

type bggIntVal struct {
	Value int `xml:"value,attr"`
}

type bggThingName struct {
	Type  string `xml:"type,attr"`
	Value string `xml:"value,attr"`
}

// ── enrichment ───────────────────────────────────────────────────────────────

func enrich(client *http.Client, db *gorm.DB, g *library.Game) error {
	var thing *bggThingItem
	var err error

	if override, ok := bggOverrides[g.Title]; ok {
		// Check if override is a numeric BGG ID or a search term.
		if isNumeric(override) {
			log.Printf("  override: direct BGG ID %s", override)
			thing, err = fetchThing(client, override)
			if err != nil {
				return fmt.Errorf("fetch by id: %w", err)
			}
		} else {
			log.Printf("  override: search as %q", override)
			id, err := searchBGG(client, override)
			if err != nil {
				return fmt.Errorf("search override: %w", err)
			}
			thing, err = fetchThing(client, id)
			if err != nil {
				return fmt.Errorf("fetch override: %w", err)
			}
		}
	} else {
		id, err := searchBGG(client, g.Title)
		if err != nil {
			return fmt.Errorf("search: %w", err)
		}
		thing, err = fetchThing(client, id)
		if err != nil {
			return fmt.Errorf("fetch: %w", err)
		}
	}

	updates := map[string]any{}

	img := strings.TrimSpace(thing.Image)
	if img == "" {
		img = strings.TrimSpace(thing.Thumbnail)
	}
	if img != "" {
		if !strings.HasPrefix(img, "http") {
			img = "https:" + img
		}
		updates["cover_image_url"] = img
	}

	desc := strings.TrimSpace(thing.Description)
	if desc != "" && g.Description == "" {
		desc = strings.ReplaceAll(desc, "&#10;", "\n")
		desc = strings.ReplaceAll(desc, "&mdash;", "—")
		desc = strings.ReplaceAll(desc, "&ndash;", "–")
		if len(desc) > 500 {
			desc = desc[:500] + "…"
		}
		updates["description"] = desc
	}

	if pt := thing.PlayingTime.Value; pt > 0 && g.DurationMin == 0 {
		updates["duration_min"] = pt
	}
	if mp := thing.MinPlayers.Value; mp > 0 && g.MinPlayers == 0 {
		updates["min_players"] = mp
	}
	if mx := thing.MaxPlayers.Value; mx > 0 && g.MaxPlayers == 0 {
		updates["max_players"] = mx
	}

	if len(updates) == 0 {
		log.Printf("  nothing to update (no image/desc found on BGG)")
		return fmt.Errorf("no cover found on BGG")
	}
	if _, hasImg := updates["cover_image_url"]; !hasImg {
		log.Printf("  WARNING: no image found, but other fields updated")
	}
	if err := db.Model(g).Updates(updates).Error; err != nil {
		return fmt.Errorf("db update: %w", err)
	}
	log.Printf("  updated: %v", mapKeys(updates))
	return nil
}

func searchBGG(client *http.Client, title string) (string, error) {
	u := "https://boardgamegeek.com/xmlapi2/search?type=boardgame&exact=1&query=" +
		url.QueryEscape(title)
	data, err := bggGet(client, u)
	if err != nil {
		return "", err
	}
	var result bggSearch
	if err := xml.Unmarshal(data, &result); err != nil {
		return "", fmt.Errorf("xml parse: %w", err)
	}
	if len(result.Items) == 0 {
		// Retry without exact match
		u2 := "https://boardgamegeek.com/xmlapi2/search?type=boardgame&query=" +
			url.QueryEscape(title)
		data2, err := bggGet(client, u2)
		if err != nil {
			return "", err
		}
		if err := xml.Unmarshal(data2, &result); err != nil {
			return "", fmt.Errorf("xml parse fallback: %w", err)
		}
	}
	if len(result.Items) == 0 {
		return "", fmt.Errorf("not found on BGG")
	}
	return result.Items[0].ID, nil
}

func fetchThing(client *http.Client, id string) (*bggThingItem, error) {
	u := "https://boardgamegeek.com/xmlapi2/thing?id=" + id + "&stats=1"
	data, err := bggGet(client, u)
	if err != nil {
		return nil, err
	}
	var result bggThing
	if err := xml.Unmarshal(data, &result); err != nil {
		return nil, fmt.Errorf("xml parse: %w", err)
	}
	if len(result.Items) == 0 {
		return nil, fmt.Errorf("empty response for id %s", id)
	}
	return &result.Items[0], nil
}

func bggGet(client *http.Client, u string) ([]byte, error) {
	req, err := http.NewRequest(http.MethodGet, u, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "MasabasiGameClub/1.0 (contact@masabasi.club)")
	// BGG closed the XML API to anonymous clients in 2026 — without this the
	// server answers 401 to every call, search included.
	req.Header.Set("Authorization", "Bearer "+bggToken)
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("http get: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode == 202 {
		// BGG returns 202 when data is being prepared; retry once.
		time.Sleep(3 * time.Second)
		resp.Body.Close()
		resp2, err := client.Do(req)
		if err != nil {
			return nil, err
		}
		defer resp2.Body.Close()
		return io.ReadAll(resp2.Body)
	}
	// 401 is not a per-title problem: the token is missing/invalid/expired, so
	// every remaining request will fail the same way. Stop instead of logging
	// 91 identical SKIPs and finishing with "enriched 0".
	if resp.StatusCode == 401 {
		log.Fatalf("BGG returned 401 — BGG_API_TOKEN is invalid or expired (%s)", u)
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("http %d for %s", resp.StatusCode, u)
	}
	return io.ReadAll(resp.Body)
}

func isNumeric(s string) bool {
	for _, c := range s {
		if c < '0' || c > '9' {
			return false
		}
	}
	return len(s) > 0
}

func mapKeys(m map[string]any) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	return keys
}
