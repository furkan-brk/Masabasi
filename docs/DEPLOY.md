# Masabaşı — Production Deploy Rehberi

**Hedef URL:** `https://masabasi.agenttale.com.tr`  
**VDS:** `212.68.34.48`  
**CI/CD:** `.github/workflows/deploy-masabasi.yml` (main'e push → otomatik)

---

## Mimari

```
Browser
  └─► Cloudflare DNS  masabasi.agenttale.com.tr → 212.68.34.48
        └─► VDS nginx  :443 (SSL, Let's Encrypt)
              └─► Docker masabasi_frontend  :8091  (nginx:alpine)
                    ├─► /api/*  → masabasi_backend  :8080  (Go)
                    └─► /media/* → masabasi_minio   :9000
```

Tüm servisler `backend/docker-compose.yml` ile tek stack'te çalışır.

---

## İlk Kurulum (bir kez)

### 1. DNS

Domain / Cloudflare panelinde:

```
A   masabasi   →   212.68.34.48
```

### 2. VDS'e SSH

```bash
ssh root@212.68.34.48
```

### 3. Repo klonla (yoksa)

```bash
git clone https://github.com/<ORG>/masabasi /opt/masabasi
cd /opt/masabasi
```

### 4. Secrets klasörü

```bash
mkdir -p /opt/masabasi/secrets
```

Yerel makineden GCP service account key'ini kopyala:

```bash
# Yerel terminalde çalıştır:
scp secrets/gcp-key.json root@212.68.34.48:/opt/masabasi/secrets/gcp-key.json
```

### 5. `.env.masabasi` oluştur

```bash
cat > /opt/masabasi/backend/.env.masabasi << 'EOF'
MASABASI_JWT_SECRET=<güçlü-rastgele-değer>
MASABASI_CORS_ORIGIN=https://masabasi.agenttale.com.tr
MASABASI_PUBLIC_URL=https://masabasi.agenttale.com.tr/media

CLAUDE_API_KEY=<anthropic-api-key>
GAMEMASTER_MODE=gemini
GCP_SERVICE_ACCOUNT_FILE=/run/secrets/gcp_sa.json
GCP_PROJECT_ID=<gcp-project-id>
GCP_REGION=us-central1
GEMINI_MODEL=gemini-2.5-flash
EOF
```

> Bu dosya `.gitignore`'da — asla commit edilmez. Değerleri geliştirici sözlü iletir.

### 6. VDS sistem nginx virtual host

```bash
cat > /etc/nginx/sites-available/masabasi << 'NGINX'
server {
    listen 80;
    server_name masabasi.agenttale.com.tr;

    location / {
        proxy_pass         http://127.0.0.1:8091;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        client_max_body_size 20m;
    }
}
NGINX

ln -s /etc/nginx/sites-available/masabasi /etc/nginx/sites-enabled/masabasi
nginx -t && systemctl reload nginx
```

### 7. SSL (Let's Encrypt)

```bash
certbot --nginx -d masabasi.agenttale.com.tr \
  --non-interactive --agree-tos -m admin@masabasi.club
```

Certbot 443 bloğunu ve HTTP→HTTPS yönlendirmesini otomatik ekler.

### 8. Docker stack'i başlat

```bash
cd /opt/masabasi
docker compose --env-file backend/.env.masabasi -f backend/docker-compose.yml up -d --build
sleep 5
curl -sf http://localhost:8090/health && echo "Backend OK"
```

### 9. GitHub Actions secrets (CI/CD için)

GitHub → repo → Settings → Secrets → Actions:

| Secret | Değer |
|--------|-------|
| `VDS_HOST` | `212.68.34.48` |
| `VDS_USER` | `root` |
| `VDS_SSH_KEY` | Private key içeriği (`~/.ssh/id_rsa` veya deploy key) |

`deploy.yml`'de aynı secretlar varsa ek gerekmez.

---

## Rutin Deploy (otomatik)

`app/**` veya `backend/**` değiştiğinde main'e push yeterli:

```
deploy-masabasi.yml
  ├─ deploy-backend  → SSH: git pull + docker compose --env-file backend/.env.masabasi -f backend/docker-compose.yml build + up
  └─ deploy-frontend → Flutter build web + SCP build/web → VDS
```

### Manuel tetikleme

```bash
# GitHub Actions → Deploy Masabaşı → Run workflow
# veya:
git commit --allow-empty -m "chore: trigger masabasi deploy" && git push
```

---

## Kontrol & Debug

```bash
# Servis durumları
docker compose -f backend/docker-compose.yml ps

# Backend log
docker logs masabasi_backend --tail 50

# Frontend log
docker logs masabasi_frontend --tail 20

# MinIO log
docker logs masabasi_minio --tail 20

# Backend sağlık
curl -sf http://localhost:8090/health

# SSL kontrol
curl -sI https://masabasi.agenttale.com.tr | head -5
```

---

## Güncelleme Notları

| Tarih | İşlem |
|-------|-------|
| 2026-06-21 | İlk deploy rehberi oluşturuldu; `Complexity float64` migrasyonu, kütüphane gelişmiş filtresi ve 3-sekmeli admin paneli (oyun CRUD + masa yönetimi) eklendi |
