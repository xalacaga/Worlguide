# Implementation Plan: On-device speech synthesis via AVSpeechSynthesizer

**Spec**: `./spec.md`
**Status**: approved

## Technical context

iOS/macOS. Extends `WGPlayback` (existing module, owns `AudioPlaying`/
`AudioAsset`) with the module's first real adapter — unlike `specs/007`–
`009`, this does not live in `WGAdapters`: `AVFoundation` is an Apple
system framework, not a network client or vendor SDK
(`AGENTS.md` rule 1 restricts only those to `WGAdapters`), same precedent
as `WGConfiguration`'s `BundleConfiguration`. Depends only on `WGCore`
(unchanged) and `AVFoundation` (system framework, no new package
dependency).

## Constitution check

- [x] 1. Domain independence — `AudioPlaying`'s Protocol is unchanged by
  this spec (only `AudioAsset`'s shape changed, in `ADR 0013`, filed
  alongside); the vendor/system-framework code lives entirely in the new
  `AVSpeechSynthesizerAudioPlayer`.
- [x] 2. Strict module separation — new types live in `WGPlayback`,
  depending only on `WGCore` and `AVFoundation`; no dependency on
  `WGAdapters` or vice versa.
- [x] 3. Configuration via environment only — nothing to configure:
  `AVSpeechSynthesizer` needs no endpoint, key, or flag. The special-case
  BCP-47 prefixes (`zh-CN`/`zh-SG`, `zh-TW`/`zh-HK`) are fixed language
  data, not environment-varying configuration, same category as
  `specs/009`'s OSM tag keys.
- [x] 4. No secrets in the repository — nothing secret involved.
- [x] 5. Strict typing — no `Any` in `WGPlayback`'s public interface;
  `AVFoundation` types stay out of the public interface entirely (see
  spec's second requirement).
- [x] 6. Tests from day one — `WGPlaybackTests` gains cases against an
  internal `SpeechSynthesizing` fake (mirrors `HTTPTransport`/
  `FakeHTTPTransport`'s role in `WGAdapters`) and against
  `SpeechVoiceResolver.bestMatch` directly, no real device voices needed.
- [x] 7. Provenance by design — not applicable; this spec plays already-
  provenanced text, adds none.
- [x] 8. Decisions are recorded — [ADR 0013](../../docs/adr/0013-audioasset-carries-text-not-url.md)
  covers the structural `AudioAsset` change this spec builds on; this plan
  needs no additional ADR of its own (the *choice of module*, `WGPlayback`
  over `WGAdapters`, is a direct, non-structural application of the
  already-recorded `AGENTS.md` rule 1 boundary, not a new one).

## Project structure impact

New:
- `ios/WorldGuide/Sources/WGPlayback/AVSpeechSynthesizerAudioPlayer.swift`
  — `public final class AVSpeechSynthesizerAudioPlayer: AudioPlaying,
  @unchecked Sendable`. `public init()` (AVFoundation-free signature,
  defaults to a real `AVSpeechSynthesizer`); `internal init(synthesizer:
  SpeechSynthesizing, voiceResolver: @escaping (String) ->
  AVSpeechSynthesisVoice?)` for tests. `play` builds an
  `AVSpeechUtterance`, resolves a voice, calls `synthesizer.speak(_:)`.
  `stop` calls `synthesizer.stopSpeaking(at: .immediate)`. Also defines
  the internal `SpeechSynthesizing` protocol (narrow seam around
  `AVSpeechSynthesizer`, same role as `WGAdapters.HTTPTransport`) and its
  `AVSpeechSynthesizer` conformance.
- `ios/WorldGuide/Sources/WGPlayback/SpeechVoiceResolver.swift` — internal
  `enum SpeechVoiceResolver`. `static func voice(forLanguageCode: String)
  -> AVSpeechSynthesisVoice?` (device-facing, calls
  `AVSpeechSynthesisVoice.speechVoices()`); `static func bestMatch
  (forLanguageCode: String, availableLanguages: [String]) -> String?`
  (pure, AVFoundation-free, this is what gets unit tested) with the
  `zh-hans`/`zh-hant` special cases plus general BCP-47 prefix matching.
- `ios/WorldGuide/Tests/WGPlaybackTests/AVSpeechSynthesizerAudioPlayerTests.swift`,
  `SpeechVoiceResolverTests.swift` — unit tests.

Changed: none beyond what `ADR 0013` already changed (`AudioAsset.swift`,
`AudioPlaying.swift`'s comment, `AudioPlayingTests.swift`).

Reused, not reimplemented: `WGCore` types (none new needed — no `WGError`
case fits "voice not found," which is why it's a soft `nil`/fallback, not
a thrown error).

## Phases

1. Phase 1 — `SpeechVoiceResolver` (independent, pure, no `AVSpeechSynthesizer`
   instance needed to write/test `bestMatch`).
2. Phase 2 — `SpeechSynthesizing` seam + `AVSpeechSynthesizerAudioPlayer`.
3. Phase 3 — Tests for both, wired together.

## Verification

`cd ios/WorldGuide && swift build && swift test` (CI:
`.github/workflows/ci.yml`, job `ios`) — confirmed empirically before this
plan was written that `AVFoundation`/`AVSpeechSynthesizer` compiles, links,
and runs via the plain `swift` CLI toolchain on macOS, no Xcode App target
or simulator required.
