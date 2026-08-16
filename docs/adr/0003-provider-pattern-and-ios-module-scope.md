# ADR 0003: Shared Provider pattern; iOS scaffolds only client-relevant modules

**Status**: Accepted
**Date**: 2026-08-13

## Context

The architecture brief asks for a "Provider architecture" and for the same
seven-way separation (POI/Sources/Knowledge/Validation/Content/LLM/TTS) to
be respected. On the backend, all seven are real pipeline stages. On iOS,
Sources ingestion, Knowledge assembly, Validation, and TTS/LLM *generation*
have no client-side meaning: the app never talks to Wikipedia/Wikidata, never
runs an LLM, and never generates speech — it consumes already-validated,
already-rendered output from the backend API.

## Decision

**Provider pattern** (applies on both sides): any dependency on something
outside the app's control — a data source, an LLM, a TTS engine, a network
API — is expressed as a `Protocol` (Swift) / `Protocol` (Python `typing`)
named `<Thing>Providing`, injected into whatever needs it. Concrete
implementations live in `infrastructure/` (backend) or a future dedicated
adapter module (iOS) — never inline in a view or a use case.

**iOS module scope**, `ios/WorldGuide/Sources/`:

- `WGCore` — shared value types used by more than one module (`Coordinate`,
  `Provenance`, error/result types).
- `WGConfiguration` — reads xcconfig-backed configuration, no hardcoded
  values.
- `WGPOI` — POI read model + `POIProviding` protocol (backend-facing).
- `WGContent` — Content Package read model (with provenance) +
  `ContentProviding` protocol.
- `WGPlayback` — audio playback abstraction (`AudioPlaying` protocol
  wrapping AVFoundation later) for backend-rendered TTS audio. Named
  `Playback`, not `TTS`, because the app plays audio, it does not
  synthesize it — conflating the two names would misrepresent what the
  client does.

Sources, Knowledge, Validation, LLM, and full TTS generation are **not**
scaffolded as iOS modules. If a future feature needs client-side knowledge
of provenance detail beyond what `WGContent` exposes, that is a new ADR, not
a retrofit of this one.

## Consequences

- iOS module count stays proportional to what the app actually does,
  avoiding empty modules built for a hypothetical future.
- If offline/on-device generation is ever required, it is deliberately a new
  decision (new ADR) rather than something silently already half-scaffolded.
- The backend's seven-module split (ADR 0002) and iOS's five-module split
  are intentionally asymmetric; `AGENTS.md`'s repo map documents both so this
  isn't mistaken for a missed module.
