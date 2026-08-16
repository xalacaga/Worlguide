# Feature Spec: On-device speech synthesis via AVSpeechSynthesizer

**Status**: approved
**Created**: 2026-08-14
**Domain module(s) touched**: iOS: WGPlayback (real `AudioPlaying`, no new
module); [ADR 0013](../../docs/adr/0013-audioasset-carries-text-not-url.md)
(structural, `AudioAsset` shape)

## Overview

[ROADMAP.md Phase 4/5](../../ROADMAP.md) — the first real implementation of
`WGPlayback.AudioPlaying` (existing Protocol port, only a test fake behind
it so far). [ADR 0011](../../docs/adr/0011-tts-on-device-not-backend-vendor.md)
is the decision that governs this spec: speech is synthesized **on-device**
via `AVSpeechSynthesizer`, fed `ContentPackage.text` (`specs/009`) and its
language — no backend TTS vendor. [ADR 0013](../../docs/adr/0013-audioasset-carries-text-not-url.md),
written alongside this spec, changed `AudioAsset` to carry `text` instead
of a pre-rendered `url` so this spec has something honest to consume.

## User scenarios

- As a user who has a `ContentPackage` for a POI, I want the app to read
  its text aloud in the content's language, using the closest available
  system voice, so that I can listen hands-free while walking.

## Requirements

- [ ] `AVSpeechSynthesizerAudioPlayer: AudioPlaying` (new, `WGPlayback`) —
  the real adapter. `play(_ asset: AudioAsset)` builds an
  `AVSpeechUtterance` from `asset.text`, resolves a voice for
  `asset.language`, and speaks it. `stop()` stops any in-progress
  utterance immediately (`AVSpeechBoundary.immediate`).
- [ ] `play`/`stop` do not leak `AVFoundation` types through
  `AVSpeechSynthesizerAudioPlayer`'s public interface (`Package.swift`'s
  existing rule: "modules must avoid UIKit/AVFoundation-only APIs in their
  public interface, enforced by review") — the public `init()` takes no
  `AVFoundation`-typed parameter; the AVFoundation seam used for testing is
  `internal`, reachable only via `@testable import`.
- [ ] Voice resolution (`specs/010`'s own concern, flagged but left open
  by [ADR 0011](../../docs/adr/0011-tts-on-device-not-backend-vendor.md)):
  a stored language code (the Wikipedia language subdomain, e.g. `"fr"`,
  `"en"`, `"zh-hans"`) is matched against the device's installed voices by
  BCP-47 prefix (`"fr"` → any voice starting `"fr-"`), with two named
  special cases for the ADR's own example — `"zh-hans"` prefers
  `zh-CN`/`zh-SG` voices, `"zh-hant"` prefers `zh-TW`/`zh-HK` — before
  falling back to bare `"zh-"`. Returns `nil` (not a thrown error) when
  nothing on the device matches — falls back to `AVSpeechUtterance`'s
  default voice, not a hard failure.
- [ ] The matching logic itself (`SpeechVoiceResolver.bestMatch`) is pure
  and tested against a plain list of language identifiers — not the
  device's actual installed voices, which vary by machine/CI runner and
  would make tests non-deterministic.

## Out of scope

- Building the actual Xcode App target — this spec only makes
  `AVSpeechSynthesizerAudioPlayer` buildable/testable via `swift build`/
  `swift test`, confirmed to work without one (AVFoundation compiles and
  runs on macOS via the CLI toolchain, no simulator needed).
- Playback progress/completion reporting back to a caller — `AudioPlaying`
  has no such signal in its protocol; `play` returns once synthesis is
  initiated, it does not await the utterance finishing.
- Persisting/caching synthesized audio (ADR 0011: synthesis is always
  on-the-fly from `ContentPackage.text`, never rendered to a file).
- An exhaustive Wikipedia-language-code → BCP-47 mapping table — only the
  ADR 0011-flagged `zh-hans`/`zh-hant` case is special-cased; every other
  code relies on the general prefix match.

## Provenance / data impact

None — this spec plays already-provenanced text (`specs/009`'s
`ContentPackage`); it adds no new source and produces no new persisted
data.

## Review checklist

- [x] No implementation detail leaked into this spec
- [x] Requirements are testable
- [x] Constitution principles respected (see `.specify/memory/constitution.md`)
- [x] Follow-up ADR filed if this changes a structural boundary — yes:
  [ADR 0013](../../docs/adr/0013-audioasset-carries-text-not-url.md),
  written before this spec, covers the `AudioAsset` shape change this
  spec depends on.
