# app/ — Masabaşı Oyun Kulübü Flutter Web istemcisi

Kutu oyunu topluluk platformu. Kendi backend'i `../backend`
(module path `github.com/masabasi/backend`, kendi `go.mod` + docker-compose + `.env`).
Agent Tale monorepo'sundan ayrıldı (`C:\Projeler\Agent-Tale`'e artık bağı yok).

Kendi `pubspec.yaml`'ı (GetX + go_router + dio + google_fonts), kendi tema/l10n'ü var.
Agent Tale `apps/web`'in `lib/ui/ui.dart` barrel kuralı ve `check_conventions.sh`
ratchet'i **buraya uygulanmaz**.

## Komutlar (`cd app/`)

```bash
flutter analyze
flutter test
flutter build web
```

## Tasarım: Stitch birebir

Ekranlar Stitch tasarımlarından üretiliyor ve **piksel sadakatiyle** uygulanır
("Stitch'deki sayfalar gibi"): boşluk, renk, tipografi, köşe yarıçapı, gölge ve
durumlar yaklaşık değil birebir. Tasarım referansı olmadan ekran uydurma.

Backend tarafı için: `../backend/SERVICE.md`.
