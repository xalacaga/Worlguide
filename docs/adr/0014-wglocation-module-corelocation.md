# ADR 0014: New `WGLocation` module — `LocationProviding` over CoreLocation

**Status**: Accepted
**Date**: 2026-08-15

## Context

[ADR 0003](0003-provider-pattern-and-ios-module-scope.md) scaffolded five
iOS modules and was explicit that any further client-side capability is
"a new ADR, not a retrofit of this one." Wiring the real adapters into a
UI (`ROADMAP.md` Phase 5, remaining bullets, after `specs/011`'s App
target) needs the device's current location to call
`WikidataPOIProvider.nearbyPOI(around:radiusMeters:)` (`specs/007`) — no
existing module owns this. Location is exactly the kind of "dependency on
something outside the app's control" the Provider pattern
([ADR 0003](0003-provider-pattern-and-ios-module-scope.md)) was written
for: a hardware/OS service, permission-gated, that must be fakeable in
tests without a live provider (constitution principle 6).

## Decision

A new module, `WGLocation`, mirrors `WGPlayback`'s existing shape (a
`Protocol` port wrapping an Apple system framework, with the real adapter
in the same module — [ADR 0011](0011-tts-on-device-not-backend-vendor.md)/
[ADR 0013](0013-audioasset-carries-text-not-url.md) precedent, not
`WGAdapters`, since `CoreLocation` is a system framework, not a network
client or vendor SDK per `AGENTS.md` rule 1):

- `LocationProviding` (protocol): `func currentLocation() async throws ->
  Coordinate` — a single-shot fetch, reusing `WGCore.Coordinate` (already
  the shape every `POIProviding`/adapter call expects). Continuous
  location streaming (background updates, significant-change monitoring)
  is explicitly not built now — out of scope until a feature actually
  needs it, per the same "don't scaffold for a hypothetical future"
  reasoning [ADR 0003](0003-provider-pattern-and-ios-module-scope.md)
  already established.
- `CLLocationManagerLocationProvider` (real adapter, same module): wraps
  `CLLocationManager`, bridges its delegate-based single-fix callback into
  `async`/`await` via a continuation. `CoreLocation` types stay out of the
  module's public interface (`Package.swift`'s existing review-enforced
  rule, same treatment `specs/010` gave `AVFoundation`).
- `WGCore.WGError` gains a `.permissionDenied` case — location
  authorization denial is a generic-enough failure mode (any future
  permission-gated capability could reuse it) to belong in the shared
  error type rather than a location-specific one.
- `ios/WorldGuideApp`'s `Info.plist` (via `ios/project.yml`,
  `specs/011`) gains `NSLocationWhenInUseUsageDescription` — required by
  iOS before `CLLocationManager` can even prompt for authorization;
  `specs/011` deliberately deferred this until a spec actually calls
  CoreLocation, which is now.

## Consequences

- iOS module count grows from five to six library products (plus
  `WGAdapters`) — proportional growth, same reasoning
  [ADR 0003](0003-provider-pattern-and-ios-module-scope.md) used to justify
  the original five, not a departure from it.
- Location permission UX (what happens when the user denies it, whether to
  re-prompt) is a UI-layer concern for the spec that actually wires this
  into a screen — `LocationProviding` only reports `WGError.permissionDenied`
  and lets the caller decide.
- No live-device integration test tier: `CLLocationManagerLocationProvider`
  is tested via a fake conforming to the internal seam, same pattern as
  `specs/010`'s `SpeechSynthesizing` — there's no equivalent of `specs/007`'s
  opt-in live network test here, since a location fix isn't reproducible
  or scriptable the way an HTTP response is.
