# Tasks: POI content via extraction (on-device)

**Plan**: `./plan.md`

## Phase 1 — Contracts

- [x] T001 Add `.wikipediaRestEndpointTemplate` to `ConfigurationKey`
  (WGConfiguration)

## Phase 2 — Extractors

- [x] T002 Implement `WikidataCoordinateResolver` (WGAdapters): SPARQL
  query on `wdt:P625`, WKT point parse, `nil` on no coordinate
- [x] T003 Implement `WikipediaSummaryExtractor` (WGAdapters): REST
  `page/summary/{title}` call, `.extract` JSON parse, `nil` on HTTP 404
- [x] T004 Implement `OSMContentLineComposer` (WGAdapters): pure function,
  `tourism`/`historic`/`start_date`/`architect` line composition

## Phase 3 — Orchestration / Interface

- [x] T005 Implement `WikipediaContentProvider: ContentProviding`
  (WGAdapters): orchestrates sitelink → summary → coordinate → OSM tags →
  line → concatenation → `POISources.assemble`-derived provenance →
  `ContentPackage` or `nil`
- [x] T006 Unit tests for `WikidataCoordinateResolver` against
  `FakeHTTPTransport` (found / missing / malformed response)
- [x] T007 Unit tests for `WikipediaSummaryExtractor` against
  `FakeHTTPTransport` (found / 404 / malformed response)
- [x] T008 Unit tests for `OSMContentLineComposer` (all four keys, some
  keys, no keys)
- [x] T009 Unit tests for `WikipediaContentProvider` against
  `FakeHTTPTransport` (Wikipedia+OSM both present, one missing, both
  missing → `nil`)
- [x] T010 Update `Secrets.xcconfig.example` with
  `WG_WIKIPEDIA_REST_ENDPOINT_TEMPLATE`

## Phase 4 — Close-out

- [x] T011 Run `swift build && swift test` — 39 tests, 0 failures, 1
  opt-in live test skipped as expected
- [x] T012 No ADR needed (see plan.md's Constitution Check)
- [x] T013 Re-run `/graphify` so the knowledge graph reflects the change
- [ ] T014 Confirm CI is green before merge — pending human verification
  (push + watch `.github/workflows/ci.yml`'s `ios` job)
