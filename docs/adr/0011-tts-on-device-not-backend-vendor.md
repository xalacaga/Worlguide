# ADR 0011: Speech synthesized on-device, not by a backend TTS vendor

**Status**: Accepted
**Date**: 2026-08-14

## Context

The original architecture brief called Phase 4 "TTS multilingue": choose a
cloud TTS vendor, implement `infrastructure/tts/` against it, and expose a
`Content → Speech` pipeline via the API so the iOS app streams
backend-rendered audio (`WGPlayback`/`AudioPlaying`, ADR 0003, deliberately
named "Playback" because the app was assumed to only ever consume, not
produce, speech).

When Phase 4 was about to start, the user asked whether the free, built-in
iOS text-to-speech engine (`AVSpeechSynthesizer`, the same voice family
Siri uses) could be used instead. Weighed against the same axes as ADR 0010
(no per-call cost, no vendor lock-in, no API key to manage, no
unpredictable third-party output): yes, and for the same reasons that ADR
0010 rejected an LLM vendor for text, a backend TTS vendor is not needed
for audio either. `AVFoundation` already ships this capability on every
iOS target this project runs on, at no marginal cost, entirely offline.

## Decision

Speech is synthesized **on-device, in the iOS app**, from the
`ContentPackage.text` that Phase 3's extraction pipeline already produces —
not rendered by a backend vendor and streamed as an audio file:

- No `infrastructure/tts/<vendor>` adapter is implemented, no TTS vendor is
  chosen, no `POST /poi/{poi_id}/speech` route is added, no audio asset is
  persisted or served by the backend.
- The actual synthesis work — `WGPlayback`'s `AudioPlaying` implemented
  with `AVSpeechSynthesizer`, fed `ContentPackage.text` and `.language` —
  belongs to Phase 5 ("App iOS"), where the rest of the AVFoundation work
  already lives. Phase 4 contributes no new backend feature.
- `domain/tts/` (`SpeechRequest`, `SpeechResult`, `TTSProvider`),
  `application/tts/synthesize_speech.py` (`SynthesizeSpeech`), and
  `infrastructure/tts/tts_provider.py` (`ConfiguredTTSProvider` stub) are
  **not deleted** — they stay as dormant Phase 0 scaffolding, the same
  treatment ADR 0010 gave `domain/llm/`. If a future need for
  backend-rendered audio appears (e.g. pre-generating an offline audio pack
  for a non-Apple client, or caching audio server-side), that is a new,
  explicit decision revisiting this one, not something silently
  reintroduced through the back door.
- `Settings.tts_provider_name` / `Settings.tts_provider_api_key`
  (`config.py`) are likewise left in place, unused — matching how
  `llm_provider_name` / `llm_provider_api_key` were kept after ADR 0010.

## Consequences

- Voice identity and quality are whatever Apple ships per language on the
  end user's device and OS version — no control over a specific "brand
  voice," no guarantee of parity across languages or across iOS releases.
  Accepted as the direct cost of "no vendor, no cost."
- No server-side audio storage, caching, or CDN concern — there is no
  audio infrastructure at all, which also means ADR 0009 ("managed
  services, no self-operated infra") has nothing to apply to for this
  phase.
- Reading a POI aloud needs no network once its `ContentPackage.text` is
  available on-device — desirable for a walking-tour app that cannot
  assume connectivity everywhere.
- `content_packages.language` is populated from the Wikipedia language
  subdomain the content was extracted from (e.g. `"fr"`, `"en"`,
  `"zh-hans"` — see `infrastructure/sources/wikipedia/`), not necessarily
  the BCP-47 tag `AVSpeechSynthesisVoice(language:)` expects (e.g.
  `"fr-FR"`). Phase 5 will need to resolve/prefix-match a voice from this
  code rather than assume an exact match is already stored — left as an
  open point for that phase's spec, not resolved here.
- No opt-in live-vendor integration test tier is needed for Phase 4 (there
  is no vendor to test against). Any `AVSpeechSynthesizer` testing is an
  iOS-side (`XCTest`) concern that belongs to Phase 5.
