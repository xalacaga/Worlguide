# ADR 0009: Managed services in production — no self-operated infrastructure

**Status**: Accepted
**Superseded by**: [ADR 0012](0012-ios-only-no-backend.md) — nothing is deployed anywhere anymore
**Date**: 2026-08-13

## Context

The stated goal is a completely autonomous application: the person running
WorldGuide should not have to operate servers — no patching a Postgres
instance, no scaling a Redis node, no babysitting an EC2 box. This needed
to be settled before more infra-shaped decisions (backend hosting, how the
`postgis`/`redis` services in `infra/docker-compose.yml` map to production)
piled up on an unstated assumption.

## Decision

In production, every stateful piece of infrastructure is a managed service,
never something self-hosted and operated by hand:

- **Postgres/PostGIS**: a managed provider (e.g. Neon, Supabase, RDS —
  provider not pinned by this ADR, see Consequences). Reached exclusively
  via `DATABASE_URL` (already the only way `PostGISPOIRepository` connects
  — no code change needed to point it at a managed instance instead of
  local Docker).
- **Redis**: a managed provider (e.g. Upstash, ElastiCache), reached via
  `REDIS_URL` — same story, config-only.
- **The FastAPI app itself**: deployed on a platform that runs it without
  the maintainer managing the underlying machine (PaaS-style: e.g. Fly.io,
  Railway, Render, or a managed container service) — not a VM someone SSHes
  into.

`infra/docker-compose.yml` keeps its existing, narrower job: **local
development only** (already documented as such since ADR 0001/0005). It is
not a production deployment artifact and this decision doesn't change it.

**Self-provisioning schema**: "no infrastructure to manage" extends to
schema setup — nobody runs a migration command by hand, ever, in any
environment. `worldguide.infrastructure.persistence.postgis.migrate.apply_migrations()`
runs automatically on API boot (FastAPI lifespan in
`interface/api/main.py`) and is the same function CI's test fixture calls
before the PostGIS integration test — one code path, not a prod version and
a separate CI/ops version. The only precondition to run WorldGuide's
backend anywhere is a reachable `DATABASE_URL` (empty database is fine) and
internet access for the providers it talks to (managed Postgres, managed
Redis, Wikipedia/Wikidata, the LLM/TTS vendor).

## Consequences

- No specific managed provider is chosen by this ADR — that's a
  cost/region/feature decision for whenever deployment is actually
  scheduled, not something to pin speculatively now. Whichever is chosen,
  it must be reachable purely via `DATABASE_URL`/`REDIS_URL` (ADR 0005) —
  a provider that requires vendor-specific SDK code in `infrastructure/`
  instead of a standard connection string would need its own justification.
- No Dockerfile or deployment pipeline exists yet in this repository — this
  ADR records the constraint the eventual one must satisfy, it does not
  build it. Building it is future work once deployment is actually
  scheduled, not implied scope creep from this decision.
- CI's `postgis` service container (ADR 0006 addendum) is unaffected: it's
  ephemeral test infrastructure, not a production hosting choice.
