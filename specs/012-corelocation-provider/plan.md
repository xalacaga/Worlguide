# Implementation Plan: Device location via CoreLocation

**Spec**: `./spec.md`
**Status**: approved

## Technical context

iOS/macOS. New module `WGLocation`, sixth `WG*` library product
([ADR 0014](../../docs/adr/0014-wglocation-module-corelocation.md)).
Depends only on `WGCore` (`Coordinate`, `WGError`) and `CoreLocation`
(system framework). No dependency on `WGPOI`/`WGAdapters`; the App target
(`specs/011`) will depend on `WGLocation` directly, same as it does on the
other five products.

## Constitution check

- [x] 1. Domain independence — `LocationProviding`'s Protocol carries no
  `CoreLocation` type; the vendor/system-framework code lives entirely in
  `CLLocationManagerLocationProvider`.
- [x] 2. Strict module separation — `WGLocation` depends only on `WGCore`,
  one direction, same shape as `WGPlayback`.
- [x] 3. Configuration via environment only — nothing to configure;
  `NSLocationWhenInUseUsageDescription`'s *string value* lives in
  `ios/project.yml` (project structure, same category as
  `specs/011`'s bundle ID), not runtime configuration.
- [x] 4. No secrets in the repository — nothing secret involved.
- [x] 5. Strict typing — no `Any` in `WGLocation`'s public interface;
  `CoreLocation` types stay internal (spec's fourth requirement).
- [x] 6. Tests from day one — `WGLocationTests` ships with the module,
  `CLLocationManagerLocationProvider` tested against an internal fake
  seam, no live device needed.
- [x] 7. Provenance by design — not applicable (see spec).
- [x] 8. Decisions are recorded —
  [ADR 0014](../../docs/adr/0014-wglocation-module-corelocation.md)
  covers the new module boundary; this plan needs no ADR of its own.

## Project structure impact

New:
- `ios/WorldGuide/Sources/WGLocation/LocationProviding.swift` — the
  protocol.
- `ios/WorldGuide/Sources/WGLocation/CLLocationManagerLocationProvider.swift`
  — the real adapter: internal `LocationManaging` protocol (seam around
  `CLLocationManager`, mirrors `WGPlayback.SpeechSynthesizing`) +
  `CLLocationManager` conformance; the provider class holds a
  `CheckedContinuation` bridging `locationManager(_:didUpdateLocations:)`/
  `locationManager(_:didFailWithError:)`/
  `locationManagerDidChangeAuthorization(_:)` into `currentLocation()`.
- `ios/WorldGuide/Tests/WGLocationTests/CLLocationManagerLocationProviderTests.swift`
  — unit tests against a fake `LocationManaging`.

Changed:
- `ios/WorldGuide/Package.swift` — new `WGLocation` library product/target
  (deps: `WGCore`) and `WGLocationTests` test target.
- `ios/WorldGuide/Sources/WGCore/WGError.swift` — add
  `.permissionDenied` case.
- `ios/project.yml` — App target's `info.properties` gains
  `NSLocationWhenInUseUsageDescription`; `dependencies` gains
  `WGLocation`.

Reused, not reimplemented: `WGCore.Coordinate`, `WGCore.WGError`.

## Phases

1. Phase 1 — `WGError.permissionDenied`; `WGLocation` target wired into
   `Package.swift`.
2. Phase 2 — `LocationProviding` protocol + `LocationManaging` seam +
   `CLLocationManagerLocationProvider`.
3. Phase 3 — Tests; `ios/project.yml` updated (usage description +
   App target dependency); `xcodegen generate` + `xcodebuild` re-verified.

## Verification

`cd ios/WorldGuide && swift build && swift test` (CI:
`.github/workflows/ci.yml`, job `ios`), plus the same `xcodebuild build`
check `specs/011` used (generic iOS Simulator destination, code signing
disabled) to confirm the App target still links with the new product and
Info.plist key.
