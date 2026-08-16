# Tasks: POI discovery via Wikidata (on-device)

**Plan**: `./plan.md`

## Phase 1 — Contracts

- [x] T001 Add `HTTPTransport` protocol in `WGAdapters` (new module)
- [x] T002 Wire `WGAdapters`/`WGAdaptersTests` targets into `Package.swift`
- [x] T003 Add `.wikidataSparqlEndpoint` to `ConfigurationKey`, drop
  `.apiBaseURL`

## Phase 2 — Adapter

- [x] T004 Implement `WikidataPOIProvider: POIProviding` (SPARQL query
  build, HTTP call via `HTTPTransport`, JSON response parsing, error
  mapping to `WGError`)
- [x] T004b Add global destination search to `POIProviding` and
  `WikidataPOIProvider` using Wikidata `EntitySearch`, with distance sorting
  handled in the app layer.

## Phase 3 — Tests / Interface

- [x] T005 Unit tests against `FakeHTTPTransport` (happy path, empty
  result, malformed response)
- [x] T005b Unit tests for global destination search, language selection,
  short-query network avoidance and app-side distance sorting.
- [x] T006 Opt-in integration test against the real endpoint, gated by
  `WORLDGUIDE_ENABLE_NETWORK_TESTS`
- [x] T007 Update `Secrets.xcconfig.example` with
  `WG_WIKIDATA_SPARQL_ENDPOINT`

## Phase 4 — Close-out

- [x] T008 Run `swift build && swift test` — unblocked after accepting the
  Xcode license and installing a full toolchain via `swiftly` (Swift
  6.3.3). Latest package verification: `swift test` succeeds with 95 tests
  executed (1 opt-in live network test skipped as expected).
- [x] T009 No ADR needed (see plan.md's Constitution Check)
- [x] T010 Re-run `/graphify` so the knowledge graph reflects the change
- [ ] T011 Confirm CI is green before merge — pending human verification
  (push + watch `.github/workflows/ci.yml`'s `ios` job)
