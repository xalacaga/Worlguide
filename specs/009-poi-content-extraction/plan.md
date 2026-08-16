# Implementation Plan: POI content via extraction (on-device)

**Spec**: `./spec.md`
**Status**: approved

## Technical context

iOS only. Extends `WGAdapters` (`specs/007`/`specs/008`) with the first
real `WGContent.ContentProviding` implementation — `WGContent` itself is
unchanged, its Protocol was already designed to receive a real adapter
without modification (`ADR 0003`). Depends on `WGCore` (`Coordinate`,
`Provenance`, `WGError`), `WGContent` (`ContentProviding`,
`ContentPackage`), `WGConfiguration`, and reuses `specs/008`'s
`WikipediaSitelinkResolver`, `OverpassTagFetcher`, `POISources` directly
(same module, no new dependency direction).

## Constitution check

- [x] 1. Domain independence — `WGContent`'s `ContentProviding` Protocol
  is unchanged; all vendor calls (Wikipedia REST, Wikidata SPARQL,
  Overpass) live in `WGAdapters`.
- [x] 2. Strict module separation — new types live in `WGAdapters`,
  depending only on `WGCore`, `WGContent`, `WGConfiguration`, same
  direction as `specs/007`/`specs/008`.
- [x] 3. Configuration via environment only — one new xcconfig key
  (`WG_WIKIPEDIA_REST_ENDPOINT_TEMPLATE`, containing `{lang}`/`{title}`
  placeholders substituted at call time — the REST API's domain varies by
  language, so a literal single URL can't express it; the *template
  string itself* is the configured value, nothing is hardcoded in Swift).
  `WikidataCoordinateResolver` reuses the existing
  `.wikidataSparqlEndpoint` key — no new key needed for it.
- [x] 4. No secrets in the repository — none of the three APIs take a key.
- [x] 5. Strict typing — no `Any` in `WGAdapters`' public interface.
- [x] 6. Tests from day one — new `WGAdaptersTests` cases against
  `FakeHTTPTransport`; `OSMContentLineComposer` is pure and tested without
  any transport at all.
- [x] 7. Provenance by design — `WikipediaContentProvider` reuses
  `specs/008`'s `POISources.assemble` for `ContentPackage.provenance`
  rather than reimplementing the "source present → provenance entry"
  rule; see spec's "Provenance / data impact".
- [x] 8. Decisions are recorded — `ADR 0010` already covers the
  extraction-not-generation decision; no new ADR (see spec's review
  checklist).

## Project structure impact

New:
- `ios/WorldGuide/Sources/WGAdapters/WikidataCoordinateResolver.swift` —
  `struct WikidataCoordinateResolver`, `HTTPTransport` + SPARQL endpoint
  URL (reuses `.wikidataSparqlEndpoint`). `func coordinate(forQID: String)
  async throws -> Coordinate?` — small SPARQL query on `wdt:P625`, reuses
  the same WKT point parsing approach as `WikidataPOIProvider`
  (`specs/007`).
- `ios/WorldGuide/Sources/WGAdapters/WikipediaSummaryExtractor.swift` —
  `struct WikipediaSummaryExtractor`, `HTTPTransport` + REST endpoint
  template URL string. `func summary(forTitle: String, language: String)
  async throws -> String?` — substitutes `{lang}`/`{title}` into the
  template, GETs, reads `.extract` from the JSON body, `nil` on HTTP 404.
- `ios/WorldGuide/Sources/WGAdapters/OSMContentLineComposer.swift` —
  `enum OSMContentLineComposer` (no state, one static function): `static
  func line(fromTags: [String: String]) -> String?` — pure, checks
  `tourism`/`historic`/`start_date`/`architect` in that order, joins
  present values into one short line, `nil` if none present.
- `ios/WorldGuide/Sources/WGAdapters/WikipediaContentProvider.swift` —
  `struct WikipediaContentProvider: ContentProviding`, composed from a
  `WikipediaSitelinkResolver`, `WikipediaSummaryExtractor`,
  `WikidataCoordinateResolver`, `OverpassTagFetcher` (all `specs/007`/
  `specs/008`/this spec's own new types) plus a `Date`-producing clock for
  `retrievedAt` (defaults to `Date.init`, injectable for tests).
  `content(forPOI:language:)`: resolve title → extract summary → resolve
  coordinate → fetch OSM tags (only if a coordinate was found) → compose
  OSM line → concatenate non-nil fragments → if non-empty, build
  `ContentPackage` with `provenance` from `POISources.assemble(...)`
  (`specs/008`) → else `nil`.
- `ios/WorldGuide/Tests/WGAdaptersTests/WikidataCoordinateResolverTests.swift`,
  `WikipediaSummaryExtractorTests.swift`, `OSMContentLineComposerTests.swift`,
  `WikipediaContentProviderTests.swift` — unit tests against
  `FakeHTTPTransport` (the three I/O types) and plain XCTest (the pure
  composer).

Changed:
- `ios/WorldGuide/Sources/WGConfiguration/ConfigurationProviding.swift` —
  add `.wikipediaRestEndpointTemplate` case.
- `ios/WorldGuide/Secrets.xcconfig.example` — add
  `WG_WIKIPEDIA_REST_ENDPOINT_TEMPLATE`.

Reused, not reimplemented: `WGAdapters.HTTPTransport`,
`WGAdaptersTests.FakeHTTPTransport`, `WGAdapters.WikipediaSitelinkResolver`,
`WGAdapters.OverpassTagFetcher`, `WGAdapters.POISources`,
`WGCore.Coordinate`, `WGCore.WGError`, `WGCore.Provenance`,
`WGContent.ContentProviding`, `WGContent.ContentPackage`.

## Phases

1. Phase 1 — `.wikipediaRestEndpointTemplate` config key.
2. Phase 2 — `WikidataCoordinateResolver`, `WikipediaSummaryExtractor`,
   `OSMContentLineComposer` (independent of each other).
3. Phase 3 — `WikipediaContentProvider` orchestration + tests for all
   four new types, `Secrets.xcconfig.example` updated.

## Verification

`cd ios/WorldGuide && swift build && swift test` (CI:
`.github/workflows/ci.yml`, job `ios`).
