# ADR 0005: Configuration exclusively via environment variables / xcconfig

**Status**: Accepted
**Date**: 2026-08-13

## Context

The backend needs database/cache URLs and provider credentials; iOS needs
API base URLs and, eventually, client-side keys. The constraint is explicit:
no API key in the repository, and configuration must be by environment
variable.

## Decision

- **Backend**: `backend/src/worldguide/config.py` defines a `Settings`
  object (pydantic-settings `BaseSettings`) that reads from the process
  environment only — no default values for anything secret. Root
  `.env.example` lists every variable name the app reads, with empty
  values; a real `backend/.env` is gitignored.
- **iOS**: an `Secrets.xcconfig.example` (empty values, committed) documents
  the same convention for the iOS side; the real `Secrets.xcconfig` is
  gitignored (see `.gitignore`). `WGConfiguration` reads configuration
  surfaced through the app's `Info.plist`/build settings, never a literal in
  Swift source.
- Both `.env.example` and `Secrets.xcconfig.example` are the single source
  of truth for variable *names* — when infrastructure code needs a new
  variable, the example file is updated in the same change (enforced via
  the `AGENTS.md` definition-of-done checklist).

## Consequences

- Onboarding a new environment (local, CI, staging) is "copy the example
  file, fill in real values," never "read the source to find what's
  needed."
- CI can run without any real secret since nothing under test requires a
  live external call yet (only `/health` exists at this stage).
- Constraint: adapters must fail fast with a clear error if a required
  variable is missing, once real adapters are implemented — not scaffolded
  yet since no adapter has real logic.
