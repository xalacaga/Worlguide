# Implementation Plan: POI sources — Wikipedia sitelinks + OSM tags (on-device)

**Spec**: `./spec.md`
**Status**: approved

## Technical context

iOS only. Extends the existing `WGAdapters` module (`specs/007`) — no new
module boundary, `WGAdapters` already owns "talks to
Wikidata/Wikipedia/OSM directly" per `AGENTS.md`'s repo map. Touches
`WGCore.Provenance` (additive enum case) and `WGConfiguration` (two new
config keys). `WGPOI.POI` is unchanged — the QID (`POI.id`) and
`POI.coordinate` are already enough input for both new lookups.

## Constitution check

- [x] 1. Domain independence — no vendor import outside `WGAdapters`;
  `WGCore.Provenance` gains a case (a value, not a vendor type).
- [x] 2. Strict module separation — new types live in `WGAdapters`,
  depending only on `WGCore` (`Coordinate`, `Provenance`, `WGError`) and
  `WGConfiguration`, same direction as `specs/007`.
- [x] 3. Configuration via environment only — two new xcconfig keys
  (`WG_WIKIDATA_API_ENDPOINT`, `WG_OVERPASS_ENDPOINT`), no hardcoded URL.
  The Overpass QL query radius (a fixed constant, not environment-varying)
  is a code constant, same category as `specs/007`'s User-Agent string.
- [x] 4. No secrets in the repository — neither API takes a key.
- [x] 5. Strict typing — no `Any` in `WGAdapters`' public interface;
  `POISources.osmTags` is `[String: String]`, not a loosely-typed blob.
- [x] 6. Tests from day one — new `WGAdaptersTests` cases against
  `FakeHTTPTransport` (already exists from `specs/007`), no live network
  test needed yet (both APIs are unauthenticated GETs/POSTs — the existing
  opt-in pattern from `specs/007` can be reused later if flakiness shows
  up, not required now).
- [x] 7. Provenance by design — this spec *is* the provenance work: see
  spec's "Provenance / data impact".
- [x] 8. Decisions are recorded — no new ADR (see spec's review checklist);
  this plan is the record.

## Project structure impact

New:
- `ios/WorldGuide/Sources/WGAdapters/WikipediaSitelinkResolver.swift` —
  `struct WikipediaSitelinkResolver`, takes an `HTTPTransport` + the
  Wikidata API endpoint URL. `func articleTitle(forQID: String, language:
  String) async throws -> String?` — GET `?action=wbgetentities&ids=QID
  &props=sitelinks&format=json`, reads `sitelinks.{language}wiki.title`.
- `ios/WorldGuide/Sources/WGAdapters/OverpassTagFetcher.swift` — `struct
  OverpassTagFetcher`, takes an `HTTPTransport` + the Overpass endpoint
  URL. `func tags(near: Coordinate) async throws -> [String: String]` —
  POST an Overpass QL query (`is_in`/`around:30`), reads the first
  element's `tags` from the JSON response; empty dict if no element.
- `ios/WorldGuide/Sources/WGAdapters/POISources.swift` — `struct
  POISources: Sendable, Codable, Equatable`: `poiID: String`,
  `wikipediaTitle: String?`, `language: String`, `osmTags: [String:
  String]`, `provenance: [Provenance]`. A `static func assemble(poiID:
  language:wikipediaTitle:osmTags:retrievedAt:) -> POISources` builds
  `provenance` from which inputs are non-empty (the "light validation"
  from the spec) — kept a plain static builder, not a new Protocol port:
  nothing outside `WGAdapters` calls it yet (Phase 3 will).
- `ios/WorldGuide/Tests/WGAdaptersTests/WikipediaSitelinkResolverTests.swift`,
  `OverpassTagFetcherTests.swift`, `POISourcesTests.swift` — unit tests
  against `FakeHTTPTransport`.

Changed:
- `ios/WorldGuide/Sources/WGCore/Provenance.swift` — add
  `case openStreetMap` to `SourceKind`.
- `ios/WorldGuide/Sources/WGConfiguration/ConfigurationProviding.swift` —
  add `.wikidataAPIEndpoint` and `.overpassEndpoint` cases.
- `ios/WorldGuide/Secrets.xcconfig.example` — add
  `WG_WIKIDATA_API_ENDPOINT` and `WG_OVERPASS_ENDPOINT`.
- `AGENTS.md` — no repo-map change (still "the only place allowed to
  import a network client", same module).

Reused, not reimplemented: `WGAdapters.HTTPTransport`,
`WGAdaptersTests.FakeHTTPTransport`, `WGCore.Coordinate`, `WGCore.WGError`,
`WGCore.Provenance`, `WGPOI.POI.id`/`.coordinate`.

## Phases

1. Phase 1 — `Provenance.SourceKind.openStreetMap` +
   `.wikidataAPIEndpoint`/`.overpassEndpoint` config keys.
2. Phase 2 — `WikipediaSitelinkResolver` and `OverpassTagFetcher`
   (independent of each other, can be built in either order).
3. Phase 3 — `POISources` bundling type + validation logic, tests for all
   three new types, `Secrets.xcconfig.example` updated.

## Verification

`cd ios/WorldGuide && swift build && swift test` (CI:
`.github/workflows/ci.yml`, job `ios`).
