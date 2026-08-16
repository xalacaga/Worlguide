# Tasks: Device location via CoreLocation

**Plan**: `./plan.md`

## Phase 0 — Structural prerequisite

- [x] T000 [ADR 0014](../../docs/adr/0014-wglocation-module-corelocation.md):
  new `WGLocation` module boundary recorded ahead of this spec's tasks

## Phase 1 — Contracts

- [x] T001 Add `.permissionDenied` case to `WGError` (WGCore)
- [x] T002 Wire `WGLocation`/`WGLocationTests` targets into `Package.swift`

## Phase 2 — Provider

- [x] T003 Define `LocationProviding` protocol (WGLocation)
- [x] T004 Define internal `LocationManaging` seam + `CLLocationManager`
  conformance
- [x] T005 Implement `CLLocationManagerLocationProvider`: authorization
  request, single-fix continuation bridging, error mapping to `WGError`
  — uses `startUpdatingLocation`/`stopUpdatingLocation`, not
  `requestLocation` (iOS-only, not available on the macOS target this
  package also builds for)
- [x] T005b Define `CountryCodeProviding` and implement
  `CLGeocoderCountryCodeProvider` so future country-aware features can
  resolve the user's current country.

## Phase 3 — Tests / App wiring

- [x] T006 Unit tests for `CLLocationManagerLocationProvider` against a
  fake `LocationManaging` (authorized+fix, denied, not-determined→granted,
  not-determined→denied, delegate failure). Tests use
  `.authorizedAlways`, not `.authorizedWhenInUse` — the latter is marked
  `@available(macOS, unavailable)`, caught by `swift test` on this
  platform.
- [x] T006b Unit tests for `CLGeocoderCountryCodeProvider` against a fake
  reverse-geocoder (uppercase ISO code, missing code, geocoder failure).
- [x] T007 Update `ios/project.yml`: add
  `NSLocationWhenInUseUsageDescription`, add `WGLocation` to the App
  target's dependencies
- [x] T008 Re-run `xcodegen generate` + `xcodebuild build` (generic iOS
  Simulator destination, code signing disabled) to confirm the App target
  still links

## Phase 4 — Close-out

- [x] T009 Run `swift build && swift test` — latest package verification:
  95 tests, 0 failures, 1
  opt-in live test skipped as expected
- [x] T010 No additional ADR needed beyond `ADR 0014` (see plan.md's
  Constitution Check)
- [x] T011 Re-run `/graphify` so the knowledge graph reflects the change
- [ ] T012 Confirm CI is green before merge — pending human verification
  (push + watch `.github/workflows/ci.yml`'s `ios` job)
