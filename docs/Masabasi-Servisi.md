---
tip: servis
katman: full-stack
durum: aktif
etiketler: [servis, backend, frontend, ayri-urun]
---
# Masabaşı Servisi (`backend` + `app`)

> [!info] Eskiden Agent Tale monorepo'sunda yaşayan, artık kendi reposunda duran ve Agent Tale ile **kod paylaşmayan** bağımsız ürün: masaüstü oyun kulübü platformu. Kendi Go modülü (`module github.com/masabasi/backend` — `agenttale/shared`'a bağlı DEĞİL), kendi Postgres+MinIO stack'i, kendi ağı, ana CI dışında.

## Backend yerleşimi

`modules/<ad>/{router,handler,service,model}.go` dörtlüsü — Agent Tale'in `{router,handler,service}` üçlüsüne benzer ama modeller **modülün kendi içinde** (paylaşılan `models` paketi yok).

| Modül | Sorumluluk |
|---|---|
| `member` | Kayıt/giriş (kendi JWT'si), profil, avatar yükleme |
| `library` | Oyun kataloğu CRUD (`/games`) |
| `favorite` | Üye başına favori oyun ekle/çıkar |
| `table` | Masa (oturum) oluşturma, listeleme, katılma/ayrılma, güncelleme |
| `vote` | Oyun seçimi anketleri — anket açma, oy verme, sonuç |
| `notification` | Bildirim listesi + toplu okundu + davet kabul/ret |
| `gamemaster` | AI oyun ustası sohbeti (`POST /gamemaster/chat`) — Claude ve Gemini'ye **doğrudan** istemci (`direct_claude.go` / `direct_gemini.go`), Agent Tale'in AIPipeline servisini kullanmaz |

Destek paketleri modülün kendi `pkg/`'sinde: `auth/jwt.go`, `config`, `database`, `middleware/auth.go`, `storage/minio.go`. Test yardımcısı `internal/testutil/db.go` (Agent Tale'in `shared/testutil`'ından ayrı bir kopya). `cmd/server` ana binary, `cmd/bgg-seed` BoardGameGeek katalog seed'i.

> [!warning] Bu modül **vendor'lı** (`backend/vendor/`). Agent Tale modüllerinde v3.29'da vendor kaldırılmıştı — buradaki kural farklı.

## Frontend (`app`)

Ayrı bir Flutter Web uygulaması (kendi `pubspec.yaml`'ı; `apps/web` ile widget/tema paylaşımı yok). Yerleşimi `apps/web`'in layer-first deseninin aynısı: `lib/controller/<feature>_controllers/`, `lib/model/`, `lib/service/{api_service.dart, api/}`, `lib/view/{screen,widget}/`, `lib/utils/`. Backend'e nginx üzerinden relative yol ile bağlanır (`nginx.conf`).

> [!tip] Tasarım sadakati bu üründe açık bir gereksinim: ekranlar Stitch çıktısına **birebir** uyacak şekilde uygulanır (yaklaşık değil).

## Compose (`backend/docker-compose.yml`)

`name: masabasi` pinli, `masabasi-net` bridge ağı. Host portları Agent Tale ile çakışmayacak şekilde ayrı: db `5434:5432` · backend `8090:8080` · MinIO `9000/9001` · frontend `8091:80`. Env dosyası `.env.masabasi.example` şablonundan.

## Kaynak Dosyalar (repo)

- `backend/modules/` · `backend/pkg/` · `app/lib/`
- `.github/workflows/deploy-masabasi.yml` (path-filtered deploy)
