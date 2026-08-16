# Feature Spec: Nearby-POI screen (location → POIs → content → TTS)

**Status**: implemented
**Created**: 2026-08-15
**Domain module(s) touched**: iOS: none (no `WG*` module changes);
`ios/WorldGuideApp/` (composition root, view model, views);
`ios/project.yml` (xcconfig wiring)

## Overview

[ROADMAP.md Phase 5](../../ROADMAP.md), remaining bullets: wire the real
adapters built in `specs/007`–`012` into an actual screen. This is the
first feature-shaped UI in the app — everything before this spec was a
port, an adapter, or a placeholder (`specs/011`'s `ContentView`).

The flow: on launch, ask for the device's location
(`WGLocation.LocationProviding`, `specs/012`) → query nearby POIs
(`WGAdapters.WikidataPOIProvider`, `specs/007`) → user picks one → fetch
its content (`WGAdapters.WikipediaContentProvider`, `specs/009`) → user
taps play, content is read aloud
(`WGPlayback.AVSpeechSynthesizerAudioPlayer`, `specs/010`).

## User scenarios

- As a user opening the app, I want to see a list of POIs near me, pick
  one, read a short extract about it, and have the app read it aloud, so
  that I get the walking-tour experience the app is for.
- As a user who denies location access, I want a clear message instead of
  a silent hang or crash.

## Requirements

- [x] `ios/WorldGuideApp/CompositionRoot.swift` builds the real adapter
  graph from `ConfigurationProviding` (`BundleConfiguration`): reads the
  four endpoint keys (`specs/007`–`010`) and fails loudly
  (`fatalError`, with a message pointing at `Secrets.xcconfig.example`) if
  any is missing — no hardcoded fallback URL, per
  [ADR 0005](../../docs/adr/0005-configuration-via-environment.md)'s
  "never hardcoded" rule; a missing required endpoint is a setup error,
  not something to paper over.
- [x] `NearbyPOIViewModel` (new, `ios/WorldGuideApp/`) orchestrates:
  fetch location → fetch nearby POIs → (on selection) fetch content →
  (on play) speak it. Exposes a small state enum (`idle` /
  `loadingLocation` / `loadingPOIs` / `loaded([POI])` / `failed(String)`)
  the view renders directly — no hidden UIKit/SwiftUI-only state.
- [x] `ContentView` becomes the POI list (loading/error/empty states);
  selecting a POI pushes a detail view showing the fetched content text
  and Play/Stop controls wired to `AudioPlaying`.
- [x] `WGError.permissionDenied` (`specs/012`) surfaces as a specific
  "location access needed" message, not a generic error string.
- [x] `ios/project.yml`'s App target gets a `configFiles` entry pointing
  at `ios/WorldGuide/Secrets.xcconfig` (gitignored, copied from
  `.example` locally) and the four endpoint keys are added to
  `info.properties` as `$(WG_...)` substitutions, so
  `BundleConfiguration` actually finds them in the built `Info.plist`.

## Out of scope

- Unit tests for `NearbyPOIViewModel`/`CompositionRoot`: at the time of this
  spec they lived in
  `ios/WorldGuideApp/`, which has no test target (no simulator runtime is
  installed on this machine to run `xcodebuild test`, `specs/011`'s known
  limitation). Their dependencies (`LocationProviding`, `POIProviding`,
  `ContentProviding`, `AudioPlaying`) are each fully tested in their own
  module — this spec's own orchestration logic is accepted as untested
  glue, same treatment `specs/011` already gave `ContentView`/
  `WorldGuideApp.swift`, not a new gap. This gap was later closed by
  `WorldGuideAppTests` in `specs/015` and follow-up specs.
- Result caching, retry logic, pull-to-refresh, POI search/filtering were
  out of scope here. Caching/search/filtering were later added by
  `specs/017`, `specs/018`, `specs/020` and `specs/021`.
- Continuous location updates while the list is open (`specs/012`
  explicitly scoped to a single fetch) were out of scope here and later
  delivered by [specs/021](../021-field-test-realtime-search-walk-polish/).
- Any design system / visual polish was out of scope here; later UI polish
  lives in `specs/017`, `specs/018` and `specs/021`.
- Real-device or live-network verification — this sandbox has no
  simulator runtime and no paired device with the App installed;
  verification is `xcodebuild build` only, same as `specs/011`/`012`.
  Later field-test verification on a paired iPhone is documented in
  [specs/021](../021-field-test-realtime-search-walk-polish/).

## Provenance / data impact

None new — this spec only displays `ContentPackage.provenance`
(`specs/008`/`009`) that already exists; it introduces no new source.

## Review checklist

- [x] No implementation detail leaked into this spec
- [x] Requirements are testable
- [x] Constitution principles respected (see `.specify/memory/constitution.md`)
- [x] Follow-up ADR filed if this changes a structural boundary — not
  needed: no new `WG*` module; `ios/WorldGuideApp/` is App-target glue
  code, the same category `specs/011` already established.
