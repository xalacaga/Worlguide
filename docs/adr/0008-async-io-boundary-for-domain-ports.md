# ADR 0008: Repository/provider domain ports are async

**Status**: Accepted
**Date**: 2026-08-13

## Context

The Phase 0 scaffolding (ADR 0002) declared every `domain/*/repository.py`
and `domain/*/provider.py` `Protocol` with synchronous methods, since no
real adapter existed yet. Implementing the first real feature
(`specs/001-poi-nearby-search`) against PostgreSQL/PostGIS via `asyncpg`
surfaced the mismatch: `asyncpg` is async-only, `interface/api/` is FastAPI
(async route handlers), and every other real adapter this project will ever
write — Redis, Wikipedia, Wikidata, an LLM vendor, a TTS vendor — is
network I/O too. Leaving POI's port synchronous while every other port
stays synchronous "for now" would mean re-litigating this exact question on
every future feature instead of once, here, while it is still cheap (the
ports are one-line stubs with no real logic behind them yet).

## Decision

Every domain port that represents I/O — `POIRepository`, `SourceProvider`,
`KnowledgePackageRepository`, `ContentRepository`, `LLMProvider`,
`TTSProvider` — declares its methods `async def`. Application use cases
that call them (`GetNearbyPOI`, `IngestSource`, `BuildKnowledgePackage`,
`GenerateContent`, `SynthesizeSpeech`) become `async def __call__`,
`await`-ing the port. `interface/api/` route handlers are `async def` and
`await` the use case directly — no sync-to-async bridging layer.

`Validator` (`domain/validation/validator.py`) stays synchronous: as
scaffolded, validation is pure computation with no I/O. If a future
validator needs to call an external service, that specific validator's use
gets revisited then — this ADR does not preemptively change it.

Fakes used in tests (`FakePOIRepository`, etc.) become `async def` to match.
`backend/pyproject.toml` sets `[tool.pytest.ini_options] asyncio_mode =
"auto"` (via `pytest-asyncio`, already a dev dependency) so async test
functions run without per-test decorators.

## Consequences

- Every future infrastructure adapter (Redis cache, Wikipedia/Wikidata
  clients, LLM/TTS vendor SDKs) implements an async port from day one — no
  adapter will need this same migration later.
- `domain/` and `application/` remain free of any I/O library import (ADR
  0002 still holds) — `async def` on a `Protocol` method is a language
  feature, not a dependency.
- Cost: every port and use case signature changed in this pass, even the
  six that have no real implementation yet (still `NotImplementedError`,
  now behind `async def`). This is a one-time mechanical change; the
  alternative (leaving them inconsistent) would cost more later.
