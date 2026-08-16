# AGENTS.md

Permanent rules for any AI coding agent working in this repository (Claude
Code, Codex CLI, or others that read this file by convention). This is the
operational entry point — for *why* each rule exists, see
`.specify/memory/constitution.md` (Spec Kit's gate) and `docs/adr/`
(structural decisions). Do not duplicate their content here; link to it.

## Repo map

```
ios/WorldGuide/Sources/
  WGCore, WGConfiguration, WGPOI, WGContent, WGPlayback   # local SPM modules,
                     # each a Protocol port (POIProviding, ContentProviding,
                     # AudioPlaying, ConfigurationProviding)
  WGAdapters         # the ONLY place allowed to import a network client and
                     # talk to Wikidata/Wikipedia/OSM directly (specs/007)
ios/WorldGuide/Tests/     # mirrors Sources/, fakes implement the module's Protocol

docs/adr/        # why — structural decisions
specs/           # what — feature specs (numbering continues at 007, ADR 0012)
.specify/        # Spec Kit: constitution + templates
```

No backend ([ADR 0012](docs/adr/0012-ios-only-no-backend.md)) — this is an
iOS-only repository.

## Non-negotiable rules

1. **Never import a network client or vendor SDK (Wikipedia/Wikidata/OSM
   client, HTTP library) inside a `WG*` module's Protocol-facing interface.**
   Only a dedicated adapter module may do this.
2. **Never commit a real secret.** `Secrets.xcconfig` is gitignored; only
   `Secrets.xcconfig.example` (empty values) is versioned.
3. **All configuration comes from xcconfig.** No hardcoded URL, key, or flag.
4. **Provider ports are `async`** (Swift `async`/`await`) — every real
   adapter is I/O (network call to Wikidata/Wikipedia/OSM). A validator
   stays sync unless a specific validator needs I/O.
5. **Strict typing is enforced, not optional**: no `Any` in a Swift
   module's public interface.
6. **A module without a test location is not done.** Add the test dir/file
   when you add the module, even if the first test is trivial.

Full rationale: `.specify/memory/constitution.md`.

## Build & test commands

```bash
# iOS (no simulator needed — modules avoid iOS-only APIs on purpose)
cd ios/WorldGuide && swift build && swift test
```

## Definition of done for any change

- [ ] Protocol-facing module code has no new vendor import (rule 1 above).
- [ ] New config keys added to `Secrets.xcconfig.example`.
- [ ] Tests added/updated; `swift test` passes.
- [ ] Structural decision? → new file in `docs/adr/`, numbered sequentially.
- [ ] Business feature? → `specs/<NNN-slug>/` updated (spec/plan/tasks).
- [ ] `/graphify` re-run after the change so the knowledge graph stays current.
- [ ] CI (`.github/workflows/ci.yml`) green before considering the change complete.

## Governance model (why these files exist)

| Artifact | Answers |
|---|---|
| Spec Kit (`specs/`, `.specify/`) | WHAT to build |
| ADR (`docs/adr/`) | WHY this architecture/decision |
| Graphify (`graphify-out/`) | HOW the project works, WHERE to intervene |
| AGENTS.md (this file) | Permanent rules for agents |
| Tests | IS IT CORRECT |
| CI | IS IT ACCEPTABLE (merge gate) |
| Git | HISTORY / source of truth |

Full detail: `docs/adr/0007-documentation-governance-model.md`.
