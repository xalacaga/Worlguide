# Implementation Plan: App target test coverage

**Spec**: `./spec.md`
**Status**: approved

## Technical context

`ios/project.yml` only defines the `WorldGuide` app target so far
(`specs/011`). Adds a sibling `bundle.unit-test` target, hosted in it —
the standard XcodeGen/Xcode shape for testing App-target-only code that
isn't part of the SPM package.

## Constitution check

- [x] 1–5, 7 — not applicable / unaffected (no `WG*` module or Protocol
  changes).
- [x] 6. Tests from day one — this spec is exactly closing that gap for
  `NearbyPOIViewModel`; `CompositionRoot` stays untested for the reason
  given in the spec (nothing to protect — it's wiring, not logic).
- [x] 8. Decisions are recorded — no ADR needed (see spec's review
  checklist).

## Project structure impact

New:
- `ios/WorldGuideApp/WorldGuideAppTests/NearbyPOIViewModelTests.swift` —
  local fakes (`FakeLocationProviding`, `FakePOIProviding`,
  `FakeContentProviding`, `FakeAudioPlaying`) conforming to the four
  public ports; tests against `NearbyPOIViewModel` directly (no
  `CompositionRoot` involved).

Changed:
- `ios/project.yml` — new `WorldGuideAppTests` target (`type:
  bundle.unit-test`, `TEST_HOST`/`BUNDLE_LOADER` pointing at
  `WorldGuide.app`), explicit `schemes:` block giving the `WorldGuide`
  scheme a test action that includes it (no `schemes:` block existed
  before — XcodeGen's default per-target scheme doesn't wire test
  targets into the app's own scheme automatically).

## Verification

`xcodebuild test -project WorldGuide.xcodeproj -scheme WorldGuide
-destination 'id=<booted simulator>'` — this needs a real destination
(unlike `build`, `test` cannot target a generic/unbooted destination), so
verification depends on the booted simulator already used throughout
`specs/013`/`014`.
