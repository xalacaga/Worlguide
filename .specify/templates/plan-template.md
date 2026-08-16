# Implementation Plan: [NAME]

**Spec**: `./spec.md`
**Status**: draft | approved

## Technical context

Which layer(s) does this touch: `domain` / `application` / `infrastructure` /
`interface` (backend), or which `WG*` module(s) (iOS)? Which existing
Protocols/ports does it use or extend?

## Constitution check

Go through `.specify/memory/constitution.md` principle by principle. For each
principle this plan could conflict with, state how it stays compliant, or
link the ADR that justifies the exception.

- [ ] 1. Domain independence
- [ ] 2. Strict module separation
- [ ] 3. Configuration via environment only
- [ ] 4. No secrets in the repository
- [ ] 5. Strict typing
- [ ] 6. Tests from day one
- [ ] 7. Provenance by design
- [ ] 8. Decisions are recorded (ADR filed if this plan is structural)

## Project structure impact

List new files/directories this plan introduces, grouped by layer. Reuse
existing Protocols/models before introducing new ones — check
`ios/WorldGuide/Sources/` first.

## Phases

1. Phase 1 — [ports/contracts added or changed]
2. Phase 2 — [adapters/implementation]
3. Phase 3 — [tests, docs, ADR if applicable]

## Verification

How this plan will be proven correct: which tests run, which CI job gates it
(`.github/workflows/ci.yml`), any manual check needed.
