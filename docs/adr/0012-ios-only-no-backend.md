# ADR 0012: WorldGuide is an iOS-only app — no backend at all

**Status**: Accepted
**Date**: 2026-08-14

## Context

Phases 0-3 built a full backend (`backend/`, Python/FastAPI, hexagonal
architecture) — POI ingestion, Sources, Knowledge, Validation, Content —
persisted to a managed Postgres/PostGIS instance (ADR 0009), reached by the
iOS app over HTTP. Phase 4 ("TTS multilingue") was about to add a TTS
vendor to that same backend when the user reconsidered the premise
entirely: **the app must be autonomous — it must not need any third-party
infrastructure to function.** It should fetch remote information
(Wikidata, Wikipedia, OpenStreetMap), sort it, present it coherently, and
produce a summary — all from the app itself.

Confirmed explicitly, and retroactively: this isn't a Phase-4-only
constraint. It applies to the whole project. ADR 0011 (TTS on-device,
`AVSpeechSynthesizer` instead of a backend vendor) turned out to be the
first instance of this same principle, applied to one module before the
principle itself had been stated. This ADR generalizes it: not just TTS —
nothing runs server-side.

## Decision

WorldGuide has **no backend**. The iOS app talks directly to Wikidata
(SPARQL), Wikipedia (REST API), and OpenStreetMap (Overpass API) — the
same public services the backend used to call from `infrastructure/` — and
performs sorting, assembly, and summarization itself, in Swift, on-device.

- `backend/` (the entire Python/FastAPI hexagonal backend: `domain/`,
  `application/`, `infrastructure/`, `interface/api/`, `migrations/`,
  ~50 tests) is **deleted**, not archived — the user's explicit choice.
- `infra/` (`docker-compose.yml` for local Postgres/PostGIS + Redis) is
  deleted — there is no backend left to run locally.
- `specs/001-poi-nearby-search` through `specs/006-content-assembly-by-extraction`
  are deleted — they specified backend features that no longer exist.
  `specs/README.md`'s numbering convention ("sequential, never reused")
  is honored going forward: the next feature spec is `specs/007-...`, not
  a renumbered `001`.
- `.env.example` is deleted — every variable it listed
  (`DATABASE_URL`, `REDIS_URL`, `LLM_PROVIDER_*`, `TTS_PROVIDER_*`,
  `WIKIPEDIA_API_BASE_URL`, `POSTGRES_*`) was backend-only config. iOS
  configuration continues to live in `Secrets.xcconfig.example` alone.
- Because there is no version control in this repository (no `.git`), a
  local backup was taken before deletion:
  `/Users/xavier.begue/projets/wordguide-backups/backend-backup-20260814-073855.tar.gz`
  (contains `backend/` and `specs/` as they stood before this ADR).
- This **supersedes [ADR 0002](0002-hexagonal-architecture-backend.md)**
  (hexagonal architecture backend — there is no backend left to be
  hexagonal) and **[ADR 0009](0009-managed-services-no-self-operated-infrastructure.md)**
  (managed services / PaaS — there is nothing left to deploy anywhere).
- ADR 0003 (provider pattern, iOS module scope), ADR 0010 (content by
  extraction, not LLM generation), and ADR 0011 (TTS on-device) all remain
  valid and are in fact the blueprint for what replaces the backend: the
  iOS `WG*` modules already expose `Protocol`-based ports
  (`POIProviding`, `ContentProviding`, `AudioPlaying`) precisely so a real
  adapter can be dropped in without touching the domain-shaped interface —
  that adapter now talks to Wikidata/Wikipedia/OSM directly instead of to
  a WorldGuide-operated API.

## Consequences

- All backend business logic (Wikidata SPARQL nearby-search, Wikipedia
  sitelink resolution, OSM tag extraction, knowledge-package validation,
  content extraction) has to be **rewritten in Swift** — none of the
  Python implementation carries over directly, though the underlying
  approach (which endpoints to call, which tags matter, what counts as a
  valid draft) does; the deleted `specs/001-006` and the backup archive
  remain a reference for that rewrite.
- No shared server-side cache or database: every device repeats its own
  requests to Wikidata/Wikipedia/OSM. Acceptable for an app whose whole
  point is "no infrastructure to operate" — a local on-device cache (not a
  shared one) is a possible future optimization, not a requirement.
- "POI near me" can no longer be a PostGIS geospatial query — it becomes a
  Wikidata SPARQL query with a geo-radius filter (Wikidata supports this
  natively via `wikibase:around`), issued directly from the app, or a
  client-side distance filter over a broader Wikidata result set. Exact
  approach is for the Phase 1 spec to decide.
- No CI backend job, no `mypy --strict`/`ruff`/`pytest` gate, no CI
  Postgres service container — `.github/workflows/ci.yml` keeps only the
  `ios` job (`swift build && swift test`).
- The Spec Kit constitution's Principles 1, 3, and 5 referenced
  backend-specific paths (`backend/src/worldguide/domain/`,
  `worldguide.config.Settings`, backend `mypy --strict`) that no longer
  exist; amended accordingly, recorded as a dated entry in
  `.specify/memory/constitution.md`'s amendment history.
