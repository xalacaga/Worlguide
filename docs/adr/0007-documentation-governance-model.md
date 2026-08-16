# ADR 0007: Documentation and governance model — one artifact, one question

**Status**: Accepted
**Date**: 2026-08-13

## Context

A project can accumulate several kinds of "why/what/how" documentation
(specs, ADRs, a knowledge graph, agent instructions, tests, CI, git history)
that quietly start overlapping and drifting out of sync. To keep them from
duplicating each other, each artifact in this repository answers exactly one
question and nothing else.

## Decision

| Artifact | Answers | Lives in |
|---|---|---|
| **Spec Kit** | WHAT to build | `specs/`, gated by `.specify/memory/constitution.md` |
| **ADR** | WHY this architecture/decision | `docs/adr/` (this file included) |
| **Graphify** | HOW the project works, WHERE to intervene | `graphify-out/` (generated, gitignored, rebuilt via `/graphify`) |
| **AGENTS.md** | Permanent RULES for any agent (Claude, Codex, …) | repo root |
| Claude / Codex | Reasoning and implementation | not a file — the agents themselves, operating under the rules above |
| **Tests** | IS IT CORRECT | `backend/tests/`, `ios/WorldGuide/Tests/` |
| **CI** | IS IT ACCEPTABLE (merge gate) | `.github/workflows/ci.yml` |
| **Git** | HISTORY / source of truth | the repository itself |

Specifically, to avoid the two most likely overlaps:

- `.specify/memory/constitution.md` is Spec Kit's own gate for its `/plan`
  step (checked principle-by-principle against a feature plan). It is
  intentionally short and only covers what a plan must respect.
  `AGENTS.md` is the operational file agents actually read first when
  starting work — repo map, commands, definition of done. `AGENTS.md`
  references the constitution for rationale instead of restating it.
- Graphify output is never hand-written or committed as source; it is
  always regenerated from the current tree via `/graphify`, so it cannot
  drift into being a second, stale copy of the ADRs or the repo map.

## Consequences

- Anyone (human or agent) asking "what should I build" reads `specs/`;
  "why is it structured this way" reads `docs/adr/`; "how does the running
  system work / where do I make this change" runs `/graphify`; "what are
  the standing rules" reads `AGENTS.md`. No artifact needs to answer a
  question that isn't its own.
- `AGENTS.md`'s definition-of-done checklist is what actually enforces this
  in practice: it asks, per change, whether an ADR, a spec update, or a
  Graphify refresh is needed — the model only holds if that checklist is
  followed.
