---
name: model-field-mismatch
description: team-lead task mock-data specs in masabasi can use field names/types that differ from the real model classes; verify against actual model files
metadata:
  type: feedback
---

When a masabasi task spec hands you mock data, verify it against the real model classes before copying it — the spec's field names/types may not match.

**Why:** In the Faz 2 tables task, the team-lead's `GameTable` mock spec used `Member(id: 1, displayName: ...)` and `Game(id: 1, ...)`, but the real `lib/model/member.dart` uses `Member({required String id, required String name})` and `lib/model/game.dart` uses `String id`. Copying the spec verbatim would not compile.

**How to apply:** Always Read `lib/model/*.dart` for any model the spec references and adapt ids to String and field names (e.g. `name` not `displayName`) to the real constructors. The spec describes intent (which games/people/seats), not exact API.
