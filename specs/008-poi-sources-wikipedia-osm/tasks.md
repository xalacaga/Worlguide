# Tasks: POI sources — Wikipedia sitelinks + OSM tags (on-device)

**Plan**: `./plan.md`

## Phase 1 — Contracts

- [x] T001 Add `.openStreetMap` case to `Provenance.SourceKind` (WGCore)
- [x] T002 Add `.wikidataAPIEndpoint` / `.overpassEndpoint` to
  `ConfigurationKey` (WGConfiguration)

## Phase 2 — Adapters

- [x] T003 Implement `WikipediaSitelinkResolver` (WGAdapters):
  `wbgetentities` call, sitelink JSON parse, `nil` on missing sitelink
- [x] T004 Implement `OverpassTagFetcher` (WGAdapters): Overpass QL query
  build, HTTP call, tags JSON parse, empty dict on no result

## Phase 3 — Bundling / Interface

- [x] T005 Implement `POISources` (WGAdapters): fields + `assemble(...)`
  static builder producing `provenance` from non-empty inputs
- [x] T006 Unit tests for `WikipediaSitelinkResolver` against
  `FakeHTTPTransport` (found / missing / malformed response)
- [x] T007 Unit tests for `OverpassTagFetcher` against `FakeHTTPTransport`
  (found / empty / malformed response)
- [x] T008 Unit tests for `POISources.assemble` (both sources present,
  one missing, both missing → empty provenance)
- [x] T009 Update `Secrets.xcconfig.example` with
  `WG_WIKIDATA_API_ENDPOINT` and `WG_OVERPASS_ENDPOINT`

## Phase 4 — Close-out

- [x] T010 Run `swift build && swift test` — 23 tests, 0 failures, 1 opt-in
  live test skipped as expected
- [x] T011 No ADR needed (see plan.md's Constitution Check)
- [x] T012 Re-run `/graphify` so the knowledge graph reflects the change
- [ ] T013 Confirm CI is green before merge — pending human verification
  (push + watch `.github/workflows/ci.yml`'s `ios` job)
