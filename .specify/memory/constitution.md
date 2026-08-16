# WorldGuide Constitution

This file is the Spec Kit governance gate: every `specs/*/plan.md` must pass a
"Constitution Check" against these principles before implementation starts.
It answers **QUOI construire** (what is allowed to be built) — not *how* (see
`docs/adr/`) nor *where to look in the running system* (see Graphify). The
practical, day-to-day rulebook for agents is [AGENTS.md](../../AGENTS.md);
this document is the smaller set of non-negotiable principles it points back to.

## Principles

### 1. Domain independence
The domain-shaped layer (iOS `WG*` module interfaces — `POIProviding`,
`ContentProviding`, `AudioPlaying`, `LocationProviding`, `PlaceSearching`,
etc.) never imports a concrete external provider — no Wikipedia, Wikidata,
or OSM client, no HTTP library. Domain code depends only on the standard
library/Foundation and its own `Protocol`/port definitions. A dedicated
adapter module (iOS) may import an external client and talk to
Wikidata/Wikipedia/OSM directly. `WGLocation` may wrap Apple system
frameworks such as CoreLocation/MapKit behind typed ports because those are
on-device/platform services, not repository-owned backend clients.

### 2. Strict module separation
iOS feature domains (`WGPOI`, `WGContent`, `WGPlayback`, `WGLocation`,
`WGConfiguration`) are separate local Swift modules with one-directional
dependencies and explicit public ports. A module never imports another
module's internals. Cross-cutting types live in a shared kernel (`WGCore`)
referenced explicitly, never implicitly.

### 3. Configuration via environment only
All configuration — URLs, credentials, feature flags — is read from
xcconfig (iOS). Nothing is hardcoded. `Secrets.xcconfig.example` is the
source of truth for variable *names*; it never carries real values.

### 4. No secrets in the repository
No API key, token, password or credential is ever committed. `.gitignore`
excludes `.env` and `Secrets.xcconfig`. A reviewer finding a real secret in
a diff blocks the merge, no exception.

### 5. Strict typing
iOS: no `Any` in a module's public interface, models are `Sendable` and
`Codable` where they cross a boundary.

### 6. Tests from day one
Every module ships a test location the moment it's created, even before it
has real behavior. Tests exercise domain/application code against fakes
that implement the module's `Protocol` — proving the architecture is
testable without a live provider, database, or network call.

### 7. Provenance by design
Assembled content always carries explicit provenance: source reference,
retrieval timestamp, license, and validation status. No extracted content
is presented to the user without passing validation first.

### 8. Decisions are recorded
Any structural decision (new module boundary, new dependency direction, new
cross-cutting concern) gets an ADR in `docs/adr/` before or alongside the
code that implements it. A plan that changes architecture without a
corresponding ADR fails the Constitution Check.

## Governance

This constitution can only be amended by an explicit user decision, recorded
as a new dated entry below and reflected in
`docs/adr/0007-documentation-governance-model.md`. Spec Kit's `/plan`
command must reject a plan that violates a principle above without an
accompanying justification and ADR reference.

## Amendment history

- 2026-08-13 — Initial constitution, derived from the constraints given for
  the WorldGuide architecture scaffolding (domain independence, strict
  module separation, env-only config, no secrets, strict typing,
  tests-from-day-one, documented decisions).
- 2026-08-14 — Pivot to an iOS-only app, no backend
  ([ADR 0012](../../docs/adr/0012-ios-only-no-backend.md)). Principles 1, 3,
  5, and 7 amended to remove backend-specific paths and the now-obsolete
  LLM generation-lineage requirement.
- 2026-08-16 — Clarified the iOS-only module list after field-test work
  added live location/place-search behavior
  ([specs/021](../../specs/021-field-test-realtime-search-walk-polish/),
  [ADR 0014](../../docs/adr/0014-wglocation-module-corelocation.md),
  [ADR 0016](../../docs/adr/0016-mapkit-place-search-recenters-exploration.md)).
  The principles did not change: platform services stay behind typed ports,
  and external public-service/network integration remains adapter-scoped.
