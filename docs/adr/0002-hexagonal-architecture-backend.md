# ADR 0002: Hexagonal architecture for the backend, domain has zero third-party dependencies

**Status**: Accepted
**Superseded by**: [ADR 0012](0012-ios-only-no-backend.md) — no backend exists anymore
**Date**: 2026-08-13

## Context

The backend's core job is a pipeline — POI, Sources, Knowledge, Validation,
Content, LLM, TTS — where several stages talk to external providers
(Wikipedia, Wikidata, an LLM vendor, a TTS vendor, PostGIS, Redis). The
constraint given for this project is explicit: the domain must not depend
directly on an external provider. That has to be enforced by where code is
*allowed to live*, not by convention alone.

## Decision

Four layers under `backend/src/worldguide/`, one-directional dependency
(later layers may depend on earlier ones, never the reverse):

- **`domain/<module>/`** — `models.py` (plain `@dataclass(frozen=True,
  slots=True)`, stdlib typing only) and a port file (`repository.py` /
  `provider.py` / `validator.py`) defining a `Protocol`. Zero third-party
  imports, not even `pydantic` — the domain layer must be readable and
  testable with nothing installed beyond Python itself.
- **`application/<module>/`** — use cases that orchestrate ports. At this
  scaffolding stage they are pure pass-through (e.g. call the injected
  repository and return its result) — no business rules yet, since none are
  in scope.
- **`infrastructure/`** — the only layer allowed to import a vendor SDK
  (`httpx`, `asyncpg`, `redis`, an LLM SDK, a TTS SDK). Each provider gets
  its own subpackage (`sources/wikipedia/`, `sources/wikidata/`, `llm/`,
  `tts/`, `persistence/postgis/`, `cache/redis/`) implementing the matching
  domain `Protocol`.
- **`interface/api/`** — FastAPI app factory and routers; depends on
  `application/`, wires concrete `infrastructure/` adapters via DI.

`poi`, `sources`, `knowledge`, `validation`, `content`, `llm`, `tts` are
each a self-contained subpackage inside every layer above. A domain module
never imports another domain module's *port* (`Protocol`) or anything from
`infrastructure/`. It may import another domain module's plain `models.py`
when the data genuinely aggregates it — e.g. `knowledge.models.
KnowledgePackage` holding a list of `sources.models.SourceReference`, per
ADR 0004 — since that is data composition, not a provider dependency.
Cross-cutting value types with no single owning module (e.g. `Coordinates`)
live in `domain/shared/models.py`, the backend's equivalent of iOS's
`WGCore` (ADR 0003).

## Consequences

- Testing the whole pipeline logic requires no live Postgres, Redis,
  Wikipedia, or LLM/TTS vendor — fakes implementing the `Protocol`s are
  enough (see ADR 0006).
- Adding or swapping a provider (e.g. a different LLM vendor) only touches
  `infrastructure/llm/`; `domain/` and `application/` are untouched by
  construction, not by discipline.
- Overhead: every real feature needs a port + at least one adapter, even for
  simple cases. Accepted as the cost of the "no direct provider dependency"
  constraint.
