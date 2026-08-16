# Implementation Plan: POI discovery via Wikidata (on-device)

**Spec**: `./spec.md`
**Status**: approved

## Technical context

iOS only. Touches the existing `WGPOI` module (`POIProviding` Protocol,
`POI` model) and a new
`WGAdapters` module, the first "dedicated adapter module" referenced by
ADR 0003/0012 — the only place in this repo allowed to import a network
client. `WGAdapters` depends on `WGCore` (for `Coordinate`, `WGError`) and
`WGPOI` (for `POIProviding`, `POI`).

## Constitution check

- [x] 1. Domain independence — `WGPOI`'s `POIProviding` Protocol exposes
  capability only (`nearbyPOI`, `searchPOI`); the vendor-facing code
  (URLSession, SPARQL query building, Wikidata `EntitySearch`) lives
  entirely in `WGAdapters`, not in `WGPOI`.
- [x] 2. Strict module separation — `WGAdapters` depends on `WGCore` and
  `WGPOI` only, one direction, no reverse dependency.
- [x] 3. Configuration via environment only — the SPARQL endpoint is a new
  `Secrets.xcconfig` key (`WG_WIKIDATA_SPARQL_ENDPOINT`), not hardcoded.
  The User-Agent header string is hardcoded as a code constant, not
  configuration — it's a fixed, non-secret, non-environment-varying value
  required by Wikidata's usage policy, same category as a `Content-Type`
  header.
- [x] 4. No secrets in the repository — nothing secret involved; the
  Wikidata Query Service takes no API key.
- [x] 5. Strict typing — no `Any` in `WGAdapters`' public interface.
- [x] 6. Tests from day one — `WGAdaptersTests` ships with the module;
  `HTTPTransport` Protocol makes the adapter testable against a fake, plus
  one opt-in integration test against the real endpoint.
- [x] 7. Provenance by design — not applicable at this layer, see spec's
  "Provenance / data impact".
- [x] 8. Decisions are recorded — no new ADR needed (see spec's review
  checklist); this plan itself is the record of how the module boundary
  already established gets used for the first time.

## Project structure impact

New:
- `ios/WorldGuide/Sources/WGAdapters/HTTPTransport.swift` — minimal
  `protocol HTTPTransport { func data(for: URLRequest) async throws -> (Data, URLResponse) }`,
  with `URLSession` conforming via an empty `extension`.
- `ios/WorldGuide/Sources/WGAdapters/WikidataPOIProvider.swift` —
  `struct WikidataPOIProvider: POIProviding`, takes an `HTTPTransport` and
  the SPARQL endpoint URL in its initializer; supports radius discovery and
  global text search.
- `ios/WorldGuide/Tests/WGAdaptersTests/WikidataPOIProviderTests.swift` —
  unit tests against a `FakeHTTPTransport`, plus one
  `WORLDGUIDE_ENABLE_NETWORK_TESTS`-gated live test.

Changed:
- `ios/WorldGuide/Package.swift` — add `WGAdapters` library target (deps:
  `WGCore`, `WGPOI`) and `WGAdaptersTests` test target.
- `ios/WorldGuide/Sources/WGConfiguration/ConfigurationProviding.swift` —
  add `.wikidataSparqlEndpoint` case, drop the unused `.apiBaseURL` case
  (was for the deleted backend, never implemented).
- `ios/WorldGuide/Secrets.xcconfig.example` — replace `WG_API_BASE_URL`
  with `WG_WIKIDATA_SPARQL_ENDPOINT`.
- `ios/WorldGuide/Sources/WGPOI/POIProviding.swift` — add
  `searchPOI(matching:language:)` for global destination search.

Reused, not reimplemented: `WGCore.Coordinate`, `WGCore.WGError`,
`WGPOI.POI`, `WGPOI.POIProviding`.

## Phases

1. Phase 1 — `HTTPTransport` protocol + `WGAdapters`/`WGAdaptersTests`
   targets wired into `Package.swift`.
2. Phase 2 — `WikidataPOIProvider`: SPARQL query construction for nearby
   search and global destination search, response parsing (QID, label, WKT
   point), error mapping.
3. Phase 3 — Tests (fake-based unit tests + opt-in live test), config
   changes, `AGENTS.md` repo map updated.

## Verification

`cd ios/WorldGuide && swift build && swift test` (CI:
`.github/workflows/ci.yml`, job `ios`). Opt-in live check:
`WORLDGUIDE_ENABLE_NETWORK_TESTS=1 swift test` against the real
`query.wikidata.org` endpoint.
