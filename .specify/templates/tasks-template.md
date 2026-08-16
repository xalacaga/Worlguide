# Tasks: [NAME]

**Plan**: `./plan.md`

Numbered, ordered, one task = one committable unit. Mark `[x]` when done.

## Phase 1 — Contracts

- [ ] T001 Define/extend `Protocol`(s) in `domain/<module>/`
- [ ] T002 Add domain model(s) (stdlib-only, strictly typed)
- [ ] T003 Add unit tests for the model(s) and Protocol conformance (fakes)

## Phase 2 — Application

- [ ] T004 Add use case in `application/<module>/` (pure orchestration)
- [ ] T005 Add unit test for the use case against a fake adapter

## Phase 3 — Infrastructure / Interface

- [ ] T006 Implement adapter in `infrastructure/<module>/<provider>/`
- [ ] T007 Wire into `interface/api/` if user-facing
- [ ] T008 Update `.env.example` if new configuration is introduced

## Phase 4 — Close-out

- [ ] T009 Run `mypy --strict` / `swift build && swift test`
- [ ] T010 File ADR in `docs/adr/` if a structural boundary changed
- [ ] T011 Re-run `/graphify` so the knowledge graph reflects the change
- [ ] T012 Confirm CI is green before merge
