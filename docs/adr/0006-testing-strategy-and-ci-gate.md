# ADR 0006: Fakes over mocks, macOS-testable iOS modules, CI as the merge gate

**Status**: Accepted
**Date**: 2026-08-13

## Context

"Tests prévus dès l'architecture" means the test story has to work before
any business logic exists, and has to actually prove the hexagonal
boundaries (ADR 0002) hold — not just exist for coverage's sake.

## Decision

- **Backend**: tests live in `backend/tests/`, mirroring
  `src/worldguide/{domain,application}/`. Application-layer tests inject a
  hand-written fake implementing the relevant `Protocol` (not a mocking
  framework double) — a fake is a real, if trivial, implementation, so a
  passing test proves the use case works against *some* conforming
  adapter, not just against a permissive mock. `mypy --strict` runs on the
  entire `src/worldguide` tree as part of the test gate, not as a separate
  optional step (see the addendum below for how untyped third-party
  dependencies are handled without weakening this).
- **iOS**: `Package.swift` declares platforms `iOS(.v17)` **and**
  `macOS(.v13)`. Modules avoid UIKit/AVFoundation-only APIs in their public
  interface so `swift test` runs on macOS without a simulator — this keeps
  local and CI test runs fast. The one iOS-exclusive layer (the thin SwiftUI
  App target wiring the local package) is created later in Xcode and is
  explicitly not part of `swift test`.
- **CI**: `.github/workflows/ci.yml` runs both suites on every push/PR as
  two independent jobs (`backend`, `ios`). CI passing is the "is this
  acceptable to merge" gate (see ADR 0007's governance table) — it does not
  replace ADR review or the Spec Kit constitution check, which happen
  earlier in the workflow.

## Consequences

- A new domain module is incomplete, by the `AGENTS.md` definition of done,
  until it has both a `Protocol` and a fake conforming to it under test.
- Keeping iOS modules simulator-free is a real constraint on what code can
  live in `WG*` modules; anything needing UIKit/AVFoundation directly moves
  to the future App target or a dedicated adapter module instead.
- CI has no secrets to manage yet since nothing under test calls a live
  provider — revisit this ADR once `infrastructure/` gets real adapters
  that CI needs to exercise against sandboxed/mocked endpoints.

## Addendum (2026-08-13, `specs/001-poi-nearby-search`)

The revisit above happened: `PostGISPOIRepository` is the first real
adapter. `.github/workflows/ci.yml`'s `backend` job now runs a
`postgis/postgis` service container with fixed, ephemeral,
throwaway-per-run credentials (`postgres`/`postgres`) — not a secret, since
nothing real is protected by it and the container is destroyed at the end
of the job. No separate migration step: per ADR 0009, the app provisions
its own schema, so a session-scoped `pytest` fixture
(`tests/integration/postgis/conftest.py`) calls the same
`apply_migrations()` the app calls on boot — CI never runs a `psql`/migration
command by hand, it exercises the real self-provisioning path. Infra-level tests
(`backend/tests/integration/`) still self-skip when `DATABASE_URL` isn't
set, so `pytest` stays green in a plain local checkout without Docker
running — CI is where they actually execute. Every future real adapter
(Redis, Wikipedia, Wikidata, LLM/TTS vendors) follows this same pattern:
add its service/sandbox to the CI job when its integration test is written,
not before.

## Addendum (2026-08-13, `specs/002-poi-import-from-wikidata`)

`WikidataPOIDiscoveryProvider` calls the public Wikidata Query Service —
a third-party dependency CI can't spin up itself the way it spins up
`postgis`. Its test (`tests/integration/wikidata/`) is opt-in, gated behind
`WORLDGUIDE_ENABLE_NETWORK_TESTS=1`, and self-skips otherwise — not part of
the default `pytest`/CI run. Same underlying principle as the addendum
above (infra-level tests self-skip without their precondition), applied to
a service this project doesn't own instead of one it does.

Verified directly (not just by inspection): a correctly-headers `httpx`
request to `query.wikidata.org` and to `en.wikipedia.org`'s API returned
`403` from this development sandbox's network egress — Wikimedia's edge
protection blocking the Python client's fingerprint specifically (an
identical `curl` request, same headers, same IP, succeeded immediately
before and after). This is a property of that sandbox's network egress,
not of the implementation — no attempt was made to disguise the client to
get around it (e.g. spoofing a browser User-Agent), since that would trade
an honest, policy-compliant client for evasion of the exact bot protection
the code is supposed to respect. Confirm this code path from a normal
development machine or the actual deployment environment before trusting
the opt-in test's result from a sandboxed CI-like environment.

This also surfaced that `mypy --strict src` (the command actually run in
`AGENTS.md`/CI) always checked the whole `src/worldguide` tree, not just
`domain/`+`application/` as originally stated — `asyncpg` has no type
stubs, and mypy only complained once real code used it. Corrected the
documentation (constitution, `AGENTS.md`, `ARCHITECTURE.md`) to say what
actually runs, and added a named `[[tool.mypy.overrides]]` for `asyncpg` in
`backend/pyproject.toml` rather than narrowing the checked scope.
