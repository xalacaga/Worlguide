# Implementation Plan: Nearby-POI screen (location → POIs → content → TTS)

**Spec**: `./spec.md`
**Status**: approved

## Technical context

iOS. All new code lives in `ios/WorldGuideApp/` (the App target,
`specs/011`), not a `WG*` SPM module — this is composition/UI glue, not
domain logic (the domain logic it calls is already built and tested in
`WGLocation`/`WGPOI`/`WGContent`/`WGPlayback`/`WGAdapters`). Depends on all
six library products, already linked (`specs/011`/`012`).

## Constitution check

- [x] 1. Domain independence — no `WG*` Protocol touched; the view model
  depends only on the four existing `Protocol` ports, never on
  `WGAdapters`'/`WGLocation`'s concrete types directly (constructed once,
  in `CompositionRoot`, and injected as protocol values).
- [x] 2. Strict module separation — `ios/WorldGuideApp/` already depends
  on all six products (`specs/011`); no new cross-module dependency
  direction.
- [x] 3. Configuration via environment only — `CompositionRoot` reads all
  four endpoints from `ConfigurationProviding`; `fatalError` on missing
  config, no hardcoded fallback URL (spec's first requirement is this
  plan's constitution compliance).
- [x] 4. No secrets in the repository — the four endpoint values are
  public API URLs, not credentials, but still sourced from `Secrets.xcconfig`
  (gitignored) rather than committed, consistent with how `specs/007`–
  `010` already treat them.
- [x] 5. Strict typing — no `Any`; `NearbyPOIViewModel`'s state is a
  closed enum.
- [x] 6. Tests from day one — the four ports this view model composes are
  each already tested; the view model itself is untested per this spec's
  documented, explicit out-of-scope note (no App-target test target
  exists yet — a real gap, named honestly, not silently skipped).
- [x] 7. Provenance by design — `POIDetailView` can display
  `ContentPackage.provenance` (already carried end-to-end since
  `specs/009`); not required by this spec's minimum scope but the data is
  there if the view chooses to show it.
- [x] 8. Decisions are recorded — no new ADR (see spec's review
  checklist).

## Project structure impact

New:
- `ios/WorldGuideApp/CompositionRoot.swift` — `enum CompositionRoot`,
  `static func makeViewModel() -> NearbyPOIViewModel`, reads
  `BundleConfiguration`, builds `WikidataPOIProvider`,
  `WikipediaContentProvider` (composed from `WikipediaSitelinkResolver`/
  `WikipediaSummaryExtractor`/`WikidataCoordinateResolver`/
  `OverpassTagFetcher`), `CLLocationManagerLocationProvider`,
  `AVSpeechSynthesizerAudioPlayer`.
- `ios/WorldGuideApp/NearbyPOIViewModel.swift` — `@MainActor final class
  NearbyPOIViewModel: ObservableObject` (not the `@Observable` macro:
  that requires iOS 17+, this target's deployment floor is iOS 16,
  `specs/011`). `@Published private(set) var state: LoadState`,
  `@Published private(set) var selectedContent: ContentPackage?`,
  `@Published private(set) var isPlaying: Bool`. Methods:
  `loadNearbyPOIs(radiusMeters:)`, `select(_ poi: POI)`,
  `playSelectedContent()`, `stopPlaying()`.
- `ios/WorldGuideApp/POIDetailView.swift` — content text + Play/Stop.

Changed:
- `ios/WorldGuideApp/ContentView.swift` — becomes the POI list, driven by
  `NearbyPOIViewModel.state`; `NavigationStack` + `NavigationLink` to
  `POIDetailView`.
- `ios/WorldGuideApp/WorldGuideApp.swift` — constructs the view model via
  `CompositionRoot.makeViewModel()`, passes it to `ContentView`.
- `ios/project.yml` — App target gains `configFiles: { Debug:
  WorldGuide/Secrets.xcconfig, Release: WorldGuide/Secrets.xcconfig }`;
  `info.properties` gains the four `WG_*` endpoint keys as `$(WG_*)`
  substitutions.
- `ios/WorldGuide/Secrets.xcconfig` (gitignored, local-only) — copied from
  `.example` and filled with the four real public endpoint URLs (not
  secret values, but still environment-configured per `ADR 0005`) so this
  plan's own build verification actually resolves real endpoints.

Reused, not reimplemented: every `WG*` port/adapter from `specs/007`–
`012`; `WGCore.Coordinate`/`WGError`; `WGPOI.POI`;
`WGContent.ContentPackage`; `WGPlayback.AudioAsset`.

## Phases

1. Phase 1 — `ios/project.yml` xcconfig wiring + local `Secrets.xcconfig`.
2. Phase 2 — `CompositionRoot` + `NearbyPOIViewModel`.
3. Phase 3 — `ContentView` (list) + `POIDetailView` (detail/play);
   `WorldGuideApp.swift` wired to the view model.

## Verification

`xcodegen generate --spec ios/project.yml` then `xcodebuild build`
(generic iOS Simulator destination, code signing disabled) — same check
`specs/011`/`012` used. `swift build && swift test` for the unchanged
SPM package (this spec adds no SPM code, so this is a regression check,
not new coverage).
