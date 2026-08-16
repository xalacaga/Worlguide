# Tasks: On-device speech synthesis via AVSpeechSynthesizer

**Plan**: `./plan.md`

## Phase 0 — Structural prerequisite

- [x] T000 [ADR 0013](../../docs/adr/0013-audioasset-carries-text-not-url.md):
  `AudioAsset` carries `text` instead of `url`; `AudioPlaying.swift`
  comment corrected; `AudioPlayingTests.swift` fake updated — done ahead
  of this spec's own tasks, verified with `swift build && swift test`
  (`WGPlaybackTests` only)

## Phase 1 — Voice resolution

- [x] T001 Implement `SpeechVoiceResolver.bestMatch` (pure): general
  BCP-47 prefix match + `zh-hans`/`zh-hant` special cases
- [x] T002 Implement `SpeechVoiceResolver.voice(forLanguageCode:)`
  (device-facing wrapper around `bestMatch` +
  `AVSpeechSynthesisVoice.speechVoices()`)

## Phase 2 — Player

- [x] T003 Define internal `SpeechSynthesizing` protocol +
  `AVSpeechSynthesizer` conformance
- [x] T004 Implement `AVSpeechSynthesizerAudioPlayer: AudioPlaying`:
  public AVFoundation-free `init()`, internal test-only init, `play`/`stop`

## Phase 3 — Tests

- [x] T005 Unit tests for `SpeechVoiceResolver.bestMatch` (exact prefix,
  bare-code fallback, `zh-hans`/`zh-hant` special cases, no match → `nil`)
- [x] T006 Unit tests for `AVSpeechSynthesizerAudioPlayer` against a fake
  `SpeechSynthesizing` (play speaks the given text with a resolved voice,
  stop calls `stopSpeaking(at: .immediate)`)

## Phase 4 — Close-out

- [x] T007 Run `swift build && swift test` — 48 tests, 0 failures, 1
  opt-in live test skipped as expected
- [x] T008 No additional ADR needed beyond `ADR 0013` (see plan.md's
  Constitution Check)
- [x] T009 Re-run `/graphify` so the knowledge graph reflects the change
- [ ] T010 Confirm CI is green before merge — pending human verification
  (push + watch `.github/workflows/ci.yml`'s `ios` job)
