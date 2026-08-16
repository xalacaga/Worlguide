# Implementation Plan: Background audio playback

**Spec**: `./spec.md`
**Status**: approved

## Technical context

iOS only for the new code path (macOS has no `AVAudioSession`). Extends
`WGPlayback.AVSpeechSynthesizerAudioPlayer` (`specs/010`) — no new module.
`ios/project.yml` (`specs/011`) gains a background-mode capability
declaration, same category of change as `specs/012`'s
`NSLocationWhenInUseUsageDescription`.

## Constitution check

- [x] 1. Domain independence — `AudioPlaying`'s Protocol is unchanged;
  session configuration is an implementation detail of the one concrete
  adapter, invisible to callers.
- [x] 2. Strict module separation — no new dependency; `AVAudioSession`
  is a system framework already implicitly available wherever
  `AVFoundation` is imported.
- [x] 3. Configuration via environment only — nothing to configure here;
  `UIBackgroundModes` is project/build structure (`ios/project.yml`), same
  category as `specs/012`'s location usage string.
- [x] 4. No secrets in the repository — n/a.
- [x] 5. Strict typing — no `Any`; the new `AudioSessionConfiguring` seam
  is internal, mirrors `SpeechSynthesizing`'s existing shape.
- [x] 6. Tests from day one — the seam is unit-testable in principle, but
  since it's entirely `#if os(iOS)`-gated and this module's `swift test`
  runs on macOS by design (docs/adr/0006), no test in this repo's `swift
  test` pipeline exercises it; `xcodebuild build` against a real iOS
  destination is the verification, same honestly-documented gap pattern
  `specs/011`/`013` already use for App-target-adjacent code.
- [x] 7. Provenance by design — n/a.
- [x] 8. Decisions are recorded — no new ADR (see spec's review checklist).

## Project structure impact

Changed:
- `ios/WorldGuide/Sources/WGPlayback/AVSpeechSynthesizerAudioPlayer.swift`
  — new internal `AudioSessionConfiguring` protocol (`#if os(iOS)`),
  `AVAudioSession` conformance, injected into
  `AVSpeechSynthesizerAudioPlayer`. `play()` activates
  (`.playback`/`.spokenAudio`) before speaking; `stop()` deactivates
  (`.notifyOthersOnDeactivation`). `pause()`/`resume()` unchanged.
- `ios/project.yml` — App target's `info.properties` gains
  `UIBackgroundModes: [audio]`.

Reused, not reimplemented: `SpeechSynthesizing` seam and its test pattern
(`specs/010`) — the new seam follows the same shape.

## Phases

1. Phase 1 — `ios/project.yml` background mode capability.
2. Phase 2 — `AudioSessionConfiguring` seam + wiring into `play()`/`stop()`.
3. Phase 3 — `xcodegen generate` + `xcodebuild build` against the iOS
  simulator to confirm the `#if os(iOS)` path actually compiles (this
  repo's `swift test` cannot, per the Constitution Check above); reinstall
  on the booted simulator for a live check.

## Verification

`xcodebuild build` (iOS Simulator destination — this is the only build
that actually compiles the `#if os(iOS)` branch) plus `swift build &&
swift test` as a regression check on the macOS-buildable remainder of the
package. Live verification: play on the simulator, lock the simulator
device (`xcrun simctl` has no direct "lock" command — verified instead by
backgrounding the app via `xcrun simctl` app-switch equivalent /
manually), confirm speech continues.
