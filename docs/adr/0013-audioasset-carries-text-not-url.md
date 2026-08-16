# ADR 0013: `AudioAsset` carries synthesized text, not a pre-rendered audio URL

**Status**: Accepted
**Date**: 2026-08-14

## Context

`AudioAsset`/`AudioPlaying` (`WGPlayback`, Phase 0) were designed under the
original brief's assumption: a backend renders speech server-side and the
app streams/plays the result. The module was deliberately named
"Playback," not "TTS" — [ADR 0003](0003-provider-pattern-and-ios-module-scope.md)
records that the app was assumed to only ever *consume* audio, never
*produce* it. `AudioAsset.url: URL` is the direct expression of that
assumption.

[ADR 0011](0011-tts-on-device-not-backend-vendor.md) later reversed the
underlying premise: speech is synthesized **on-device**, in the app, via
`AVSpeechSynthesizer`, fed `ContentPackage.text` directly. There is never a
pre-rendered audio file or URL in this flow. Starting the real
implementation (`specs/010`, Phase 5) surfaced that `AudioAsset` cannot
honestly express what it now needs to carry — unlike `specs/007`–`009`,
which were each the first real *use* of an already-correctly-shaped port,
this is a genuine shape mismatch in the port itself.

## Decision

- `AudioAsset` drops `url: URL`, gains `text: String` — it now carries what
  `AVSpeechSynthesizer` actually consumes (the text and language to speak),
  not a file reference. `id` and `language` are unchanged.
- `AudioPlaying`'s protocol shape itself (`play(_ asset:) async throws`,
  `stop() async`) is **unchanged** — fire-and-forget play plus cancel is
  still the right shape; only the payload type's fields change.
- The real implementation (`AVSpeechSynthesizerAudioPlayer`, `specs/010`)
  lives directly in `WGPlayback`, not `WGAdapters`: `AVFoundation` is an
  Apple system framework, not a network client or vendor SDK — `AGENTS.md`
  rule 1 restricts only those to `WGAdapters`. Same precedent as
  `WGConfiguration`'s real `BundleConfiguration` living alongside
  `ConfigurationProviding` in the same module, not in `WGAdapters`.
- `AudioPlaying.swift`'s original Phase-0 comment ("the concrete
  AVFoundation-backed implementation is added with the App target...
  AVFoundation is iOS/macOS-only and this module is kept simulator-free for
  `swift test`") is corrected: `AVSpeechSynthesizer` was confirmed to
  compile, link, and run via plain `swift build`/`swift test` on macOS
  before this ADR was written — no App target or simulator required. The
  module was never actually blocked; the assumption was untested.

## Consequences

- Breaking change to `AudioAsset`'s public shape. Accepted without
  hesitation: nothing outside this repo consumes it (no App target, no
  released version yet); the only existing consumer is the test fake
  (`AudioPlayingTests.swift`), updated alongside this ADR.
- Voice resolution — mapping a stored language code (`"fr"`, `"en"`,
  `"zh-hans"`, the Wikipedia language subdomain per ADR 0011) to a BCP-47
  tag `AVSpeechSynthesisVoice(language:)` expects (e.g. `"fr-FR"`) — is
  `specs/010`'s problem to solve, as ADR 0011 already flagged.
- If a future need for backend-rendered/pre-cached audio ever reappears
  (ADR 0011's own "not deleted, dormant" caveat on the backend `domain/tts/`
  scaffolding), `AudioAsset` would need a new field or a sum type at that
  point — an explicit future decision, not something this ADR pre-builds
  for.
