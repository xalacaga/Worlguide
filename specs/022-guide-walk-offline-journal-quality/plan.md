# Plan

## Scope

This is an app-target feature layer. It reuses existing protocol ports:
`LocationProviding`, `POIProviding`, `ContentProviding`, `AudioPlaying`, and
the existing UserDefaults-backed persistence patterns.

## Implementation

- Extend app-level state in `NearbyPOIViewModel` for guide mode, speech speed,
  offline area packs, personal notes, confidence badges and richer POI filters.
- Keep provider interfaces unchanged except for `AudioAsset`, which gains a
  typed speech-rate multiplier consumed by `AVSpeechSynthesizerAudioPlayer`.
- Add main-screen quick filters and an auto-guide banner.
- Add configuration controls for guide mode, audio speed and offline pack
  download.
- Add POI-detail confidence pills and persistent personal note input.
- Add tests for filters, notes, offline pack persistence, guide playback and
  audio-rate propagation.

## Verification

- App targeted tests: `NearbyPOIViewModelTests` passed with 47 tests.
- Package tests: `swift test` passed with 108 tests, 1 skipped live-network
  test.
- Full app build/test still required after final docs/Graphify update.
