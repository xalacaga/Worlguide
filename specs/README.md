# Specs

This directory holds one subfolder per feature, created when real business
work starts. `specs/001` through `specs/006` specified backend features
that no longer exist — deleted along with the backend itself
([ADR 0012](../docs/adr/0012-ios-only-no-backend.md)). Numbering is never
reused, so the next feature spec is `specs/007-...`, not a renumbered
`001`.

## Convention

```
specs/
└── 001-short-feature-slug/
    ├── spec.md    # from .specify/templates/spec-template.md — WHAT
    ├── plan.md    # from .specify/templates/plan-template.md — HOW, gated by the constitution
    └── tasks.md   # from .specify/templates/tasks-template.md — ordered checklist
```

Numbering is sequential and never reused. `spec.md` answers *what* to build
in product terms; `plan.md` runs the Constitution Check against
`.specify/memory/constitution.md` and answers *how*, referencing the
relevant ADR(s) in `docs/adr/`; `tasks.md` is the ordered execution
checklist, ending with re-running `/graphify` and confirming CI is green.

Current latest spec: `021-field-test-realtime-search-walk-polish`, created
after real-device field testing to document live GPS refresh, composite
Apple/Wikidata place search, custom walks, transport handoff, chapter-level
playback and strict POI-detail layout.
