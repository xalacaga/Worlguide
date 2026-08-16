# Tasks: Nearby-POI screen (location → POIs → content → TTS)

**Plan**: `./plan.md`

## Phase 1 — Config wiring

- [x] T001 Add `configFiles` to `ios/project.yml`'s App target; add the
  four `WG_*` endpoint keys to `info.properties`
- [x] T002 Create local (gitignored) `ios/WorldGuide/Secrets.xcconfig`
  from `.example`, filled with the real public endpoint URLs — hit and
  fixed a real xcconfig pitfall: `//` starts a comment in `.xcconfig`
  files, silently truncating every URL to `https:`; escaped with an empty
  `$()` expansion between the slashes, verified against the *built*
  bundle's `Info.plist` (not the source `Generated-Info.plist`, which
  stays unresolved `$(...)` until the build step substitutes it)

## Phase 2 — Composition and orchestration

- [x] T003 Implement `CompositionRoot.makeViewModel()` — `@MainActor`
  (required: `NearbyPOIViewModel`'s initializer is main-actor-isolated)
- [x] T004 Implement `NearbyPOIViewModel` (state enum, `loadNearbyPOIs`,
  `select`, `playSelectedContent`, `stopPlaying`)

## Phase 3 — Views

- [x] T005 Rewrite `ContentView` as the POI list (loading/error/empty
  states, `NavigationStack`) — `ContentUnavailableView` needs iOS 17, this
  target's floor is iOS 16, so a minimal stand-in view was used instead
- [x] T006 Implement `POIDetailView` (content text, Play/Stop)
- [x] T007 Wire `WorldGuideApp.swift` to `CompositionRoot`/`ContentView`

## Phase 4 — Close-out

- [x] T008 `xcodegen generate` + `xcodebuild build` (generic iOS
  Simulator destination, code signing disabled) — regenerating after
  adding new source files was required (XcodeGen enumerates the
  `WorldGuideApp` directory at generation time, not dynamically)
- [x] T009 `swift build && swift test` — 53 tests, 0 failures, 1 opt-in
  live test skipped as expected (regression check, SPM package unchanged
  by this spec)
- [x] T010 No ADR needed (see plan.md's Constitution Check)
- [x] T011 Re-run `/graphify` so the knowledge graph reflects the change
- [ ] T012 Confirm CI is green before merge — pending human verification
  (push + watch `.github/workflows/ci.yml`'s `ios` job); note CI does not
  build the App target (`specs/011`'s known gap, unchanged by this spec)

## Phase 5 — Live simulator verification (post-close-out)

- [x] T013 Booted an iOS 26.5 simulator, installed and ran the app for
  real: live location (simulator default: San Francisco) →
  `WikidataPOIProvider` found a real nearby POI ("California Street") via
  a live SPARQL query → selecting it surfaced a real bug — the public
  Overpass instance returned HTTP 504 after ~11s, which
  `WikipediaContentProvider` treated as fatal (killing the Wikipedia
  summary that had already succeeded), and `NearbyPOIViewModel.select`
  silently swallowed the error, leaving `POIDetailView` stuck on
  "Chargement du contenu…" forever.
- [x] T014 Fixed both layers: `WikipediaContentProvider` now treats a
  coordinate-resolution or Overpass failure as "OSM contributed nothing"
  (`try?`, same soft-degradation already used for "not found"), consistent
  with ADR 0010's "extract from each source" partial-success design — the
  primary Wikipedia source no longer gets sunk by a flaky supplementary
  one. Two new regression tests
  (`testContentUsesOnlyWikipediaWhenOverpassFails`,
  `testContentUsesOnlyWikipediaWhenCoordinateResolutionFails`) in
  `WikipediaContentProviderTests.swift`. `NearbyPOIViewModel` gained a
  proper `ContentState` enum (`loading`/`loaded`/`empty`/`failed`) so
  `POIDetailView` can no longer get stuck in an unlabeled infinite spinner
  on a real failure — re-verified on the simulator: real Wikipedia extract
  for "California Street" rendered with a working "Écouter" control.
