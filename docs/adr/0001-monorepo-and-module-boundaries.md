# ADR 0001: Monorepo with explicit top-level boundaries

**Status**: Accepted
**Date**: 2026-08-13

## Context

WorldGuide is a single product delivered as two runtime artifacts — an iOS
app and a Python backend — sharing one domain model (POI, Sources,
Knowledge, Validation, Content, LLM, TTS) and one governance layer (specs,
ADRs, constitution, CI). Splitting into multiple repos would duplicate that
governance layer and make cross-cutting changes (e.g. a Knowledge Package
field used by both backend and iOS) require coordinated multi-repo commits
before there is even a first feature.

## Decision

One repository, with top-level directories that are themselves the
boundaries other ADRs and `AGENTS.md` refer to:

```
backend/   # Python/FastAPI, hexagonal architecture (ADR 0002)
ios/       # Swift/SwiftUI, local SPM modules (ADR 0003)
infra/     # local dev environment (docker-compose), no secrets
docs/adr/  # this decision log
specs/     # Spec Kit feature specs
.specify/  # Spec Kit constitution + templates
.github/   # CI
```

`backend/` and `ios/` do not import from each other; they communicate only
over the HTTP API defined in `backend/src/worldguide/interface/api/`. Shared
concepts (e.g. what a POI or a Content Package looks like) are duplicated as
independently-typed models on each side rather than shared via a code
dependency — the wire format (JSON over HTTP) is the actual contract, not a
shared library.

## Consequences

- A single `git log` is the source of truth for the whole product (matches
  the "Git = history/source of truth" role in ADR 0007).
- CI can run backend and iOS jobs independently in the same workflow.
- Future risk: model drift between backend and iOS DTOs. Accepted for now;
  if it becomes painful, an OpenAPI-generated client is a smaller fix than
  undoing the monorepo, so no anti-corruption layer is built prematurely.
