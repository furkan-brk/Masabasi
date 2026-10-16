---
name: reference_module_map
description: backend ownership map as of the v3.63 agent-roster split (2026-08-13)
metadata:
  type: reference
---

`backend/` — SEPARATE product, own Go module path
(`masabasi/backend`, not `github.com/agenttale/...`). Owns: `modules/`
(favorite, gamemaster, library, member, notification, table, vote), `pkg/`
(auth, config, database, middleware, storage). Pairs with `app`
(Flutter, `masabasi-app-dev`).

**Core constraint**: keep this product separable — do NOT take a dependency
on `agenttale/shared` even when a helper looks reusable. This is a
deliberate architectural boundary, not an oversight.

No project history recorded yet — this file will accumulate real findings as
work happens. Verify against current source before relying on specific file
names.
