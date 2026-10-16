# CLAUDE.md

Masabaşı — kutu oyunu topluluk (masa/kulüp) platformu. Agent Tale monorepo'sundan
(`C:\Projeler\Agent-Tale`) ayrıldı; ondan **kod paylaşmaz**.

| Dizin | İçerik | Rehber |
| ----- | ------ | ------ |
| `backend/` | Go + Gin + GORM backend (`github.com/masabasi/backend`, vendor'lı) | `backend/SERVICE.md` |
| `app/` | Flutter Web istemcisi (Stitch tasarımlarına piksel sadakat) | `app/CLAUDE.md` |
| `docs/` | `DEPLOY.md` (VDS kurulum/nginx/SSL), `Masabasi-Servisi.md` (servis notu) | |

## Komutlar

```bash
cd backend && go vet -mod=vendor ./... && go test -mod=vendor ./...
cd app && flutter analyze && flutter test && flutter build web --dart-define=API_BASE_URL=/api/v1
docker compose --env-file backend/.env.masabasi -f backend/docker-compose.yml up -d --build
```

Yerel secret'lar (git'e girmez): `backend/.env.masabasi` (şablon `.env.masabasi.example`),
`secrets/gcp-key.json` (compose `../secrets/gcp-key.json` olarak mount eder).

## Kurallar
- Agent Tale paketlerini (`github.com/agenttale/*`) **import etme**; ihtiyaç varsa kopyala.
- Agent'lar: `masabasi-service-dev` (backend), `masabasi-app-dev` (app) — `.claude/agents/`.
- Deploy: `.github/workflows/deploy.yml` → VDS `/opt/masabasi` (Agent Tale ile aynı VDS,
  `/tmp/agenttale-deploy.lock` kilidi ortak). Detay `docs/DEPLOY.md`.
