# Masabaşı Service

Masabaşı'nın Go backend'i — masa (table) merkezli bir kulüp platformu; Agent Tale
ile **aynı repoda yaşayan ama ayrı bir üründür**: kendi modül yolu
(`github.com/masabasi/backend`), kendi `docker-compose.yml`/`Dockerfile`'ı ve
kendi `vendor/` dizini vardır, böylece istenildiği anda ayrı bir repoya
çıkarılabilir.

## Sahiplik
- Agent: `masabasi-service-dev` (`.claude/agents/masabasi-service-dev.md`)
- Vault notu: `docs/Masabasi-Servisi.md`
- Frontend eşi: `app/` (`masabasi-app-dev`)

## Hızlı Bilgiler
- Dil: Go 1.25
- Modül yolu: `github.com/masabasi/backend` (**`github.com/agenttale/...` DEĞİL**)
- go.work: **yok** — modül bağımsız repoda (eskiden Agent Tale `services/go.work`'teydi); `-mod=vendor` ile build edilir
- Dosya sayısı: 44 `.go` (vendor hariç) · 3577 `.go` (vendor dahil) ·
  51 dosya toplam (vendor hariç)
- Test dosyası: 6 (`modules/{favorite,library,member,notification,table,vote}/service_test.go`)
- Bağımlılıklar: gin, gin-contrib/cors, gorm (postgres + glebarez/sqlite),
  golang-jwt/v5, minio-go/v7, golang.org/x/crypto.
  **`github.com/agenttale/*` bağımlılığı yok** (doğrulandı, aşağıya bkz.)

## Sorumluluklar
- `modules/table/` — ürünün merkezi domain nesnesi: masa oluşturma, listeleme,
  katılma/ayrılma. 7 rota; listeleme rotası `optionalAuth` ile anonim erişime de
  açık.
- `modules/member/` — hesap, profil ve üyelik yüzeyi (`/me` grubu dahil).
- `modules/vote/` — oylama; yetkili ve admin rotaları ayrı gruplarda.
- `modules/library/` — oyun kütüphanesi; yazma rotaları `RequireAdmin()` arkasında.
- `modules/favorite/`, `modules/notification/` — favoriler ve bildirimler.
- `modules/gamemaster/` — GM rolü yüzeyi; Claude ve Gemini'ye doğrudan HTTP
  çağrısı yapan tek modül (`direct_claude.go`, `direct_gemini.go`).
- `pkg/` — `auth` (JWT kimlik), `config`, `database`, `middleware`
  (`RequireAuth`/`RequireAdmin`), `storage` (MinIO üzerinden medya/upload).
- `cmd/server` (HTTP sunucu) ve `cmd/bgg-seed` (kütüphane seed job'ı).

## Komutlar
```bash
cd backend
go vet ./...
go test ./...
go build -mod=vendor ./cmd/server     # Dockerfile'ın kullandığı biçim
docker compose -f backend/docker-compose.yml up -d --build
```

## Denetim Durumu (Audit Status)
**Son denetim**: 2026-08-13 (v3.63 servis denetim turu)

| Kontrol | Sonuç | Not |
|---|---|---|
| `go vet ./...` | ✅ | Çıkış kodu 0, uyarı yok |
| `go test ./...` | ✅ | 6 paket `ok` (~24 sn/paket), 9 paket "no test files". `-race` **koşulmadı** |
| agenttale/shared'a bağımlı DEĞİL | ✅ | `go.mod` + tüm `.go` dosyalarında (vendor hariç) `agenttale` geçmiyor |

`go test` çıktısı (özet): `modules/{favorite,library,member,notification,table,vote}`
yeşil; `cmd/*`, `internal/testutil`, `pkg/*` ve `modules/gamemaster` test içermiyor.

## Bilinen Boşluklar / Bulgular

1. ~~go.work üyeliği~~ — repo ayrıldığı için çözüldü; artık lokal `go build`/`go test` vendor'ı doğrular.

2. **Hiçbir liste endpoint'i sayfalanmıyor.** `modules/*/service.go` ve
   `handler.go` dosyalarında `Limit(`/`Offset(`/`page` kullanımı yok — masa
   listesi, kütüphane, bildirimler ve favoriler büyüdükçe tüm satırları döndürür.
   Bu, modülün kendi Definition-of-Done maddesini ("her liste endpoint'i
   sayfalanır") ihlal ediyor. Sayfalama eklemek **yanıt gövdesini değiştireceği
   için** `masabasi-app-dev` ile sözleşme değişikliği olarak koordine edilmeli.

3. **Test kapsamı modül servislerine sınırlı.** `pkg/auth`, `pkg/middleware` ve
   `pkg/storage` — yani yetkilendirme ve upload yolları — hiç test edilmiyor.
   `modules/gamemaster` de testsiz; dış AI sağlayıcılarına çağrı yapan tek modül
   olduğu için burada en azından hata/timeout davranışı için test değerli olurdu.

4. **Dış çağrılarda `context.WithTimeout()` yerine istemci düzeyi timeout var.**
   `direct_claude.go:36` (60 sn) ve `direct_gemini.go:64` (120 sn) `http.Client`
   üzerinde timeout tanımlıyor; bu istek başına iptal (caller context'i düşünce
   çağrının kesilmesi) sağlamaz. 120 sn'lik Gemini timeout'u istek başına oldukça
   uzun.

5. **Test süresi paket başına ~24 saniye** — 6 paket için toplam ~2,5 dakika.
   Sabit bir gecikme gibi görünüyor (muhtemelen kurulum/bekleme); araştırılmadı.

6. `Dockerfile` `COPY vendor ./vendor` sonrası `COPY . .` yapıyor; ikinci kopya
   birinciyi kapsıyor, yani ilk satır gereksiz. Zararsız, yalnızca not.

**Bu denetimde hiçbir mevcut dosya değiştirilmedi; yalnızca bu `SERVICE.md`
oluşturuldu. Hiçbir git işlemi yapılmadı, `vendor/` dizinine dokunulmadı.**
