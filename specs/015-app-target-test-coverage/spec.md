# Feature Spec: App target test coverage

**Status**: approved
**Created**: 2026-08-15
**Domain module(s) touched**: iOS: `ios/WorldGuideApp/` (no `WG*` module
changes); `ios/project.yml` (new test target)

## Overview

`specs/011`/`013` both explicitly accepted "`ios/WorldGuideApp/` has no
test target" as a documented gap. `NearbyPOIViewModel` is the app's actual
orchestration logic (location → POIs → content → playback state machine)
and has grown substantially (specs/013/014, plus this session's distance
sort/search additions) with zero test coverage — the risk flagged when
this gap was first accepted has arrived.

## User scenarios

- As whoever maintains this app next, I want `NearbyPOIViewModel`'s state
  transitions covered by tests, so that a future change to the load/
  select/play flow fails a test instead of only being caught by manual
  simulator testing.

## Requirements

- [ ] `ios/project.yml` gains a `WorldGuideAppTests` unit test target,
  hosted in the `WorldGuide` app target (`TEST_HOST`/`BUNDLE_LOADER`),
  wired into the `WorldGuide` scheme's test action.
- [ ] `NearbyPOIViewModelTests.swift` covers, against local fakes of the
  four `Protocol` ports (no `WGAdapters`/`WGLocation` involved): POI load
  success (sorted by distance from the fetched coordinate), permission-
  denied vs. generic failure states, content select success/empty/
  failure, and the play → pause → resume → stop state machine, including
  that selecting a new POI stops any in-flight playback (specs/013's
  fix).
- [ ] `CompositionRoot` stays untested by design — its only logic is
  `Bundle`/`Info.plist` wiring guarded by `fatalError` on missing config;
  faking `Bundle.main` in a hosted XCTest is fragile relative to the
  actual value (there is no orchestration logic in it to protect).

## Out of scope

- UI tests (`XCUITest`) for `ContentView`/`POIDetailView` — this spec is
  unit-level ViewModel coverage only.
- Retroactively testing `CompositionRoot` (see last requirement).
- Wiring this test target into CI — `.github/workflows/ci.yml`'s `ios`
  job still only runs `swift build`/`swift test` against the SPM package
  (`specs/011`'s known gap); making CI also run `xcodebuild test` against
  the App target is a separate, larger change.

## Provenance / data impact

None.

## Review checklist

- [x] No implementation detail leaked into this spec
- [x] Requirements are testable
- [x] Constitution principles respected (see `.specify/memory/constitution.md`)
- [x] Follow-up ADR filed if this changes a structural boundary — not
  needed: adds a test target, no production module boundary changes.
