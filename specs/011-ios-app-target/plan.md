# Implementation Plan: iOS App target (generated via XcodeGen)

**Spec**: `./spec.md`
**Status**: approved

## Technical context

Pure tooling/scaffolding — no `WG*` module code changes. `XcodeGen`
(https://github.com/yonaskolb/XcodeGen) reads `ios/project.yml` and
generates `ios/WorldGuide.xcodeproj`. No Homebrew on this machine;
`xcodegen` was built from source via `swift build -c release` (it is
itself a Swift Package) and installed to `~/.local/bin/xcodegen` — a
one-time local machine setup, not part of the repo.

## Constitution check

- [x] 1. Domain independence — no `WG*` Protocol/port touched.
- [x] 2. Strict module separation — the new App target depends on the
  existing package's products (one direction, already-established); no
  `WG*` module gains a new dependency.
- [x] 3. Configuration via environment only — nothing new to configure;
  the App target's own build settings (bundle ID, deployment target) are
  project structure, not runtime configuration, same category as
  `Package.swift`'s `platforms:` array.
- [x] 4. No secrets in the repository — `project.yml` and the generated
  `.xcodeproj` carry no secret; `Secrets.xcconfig` (gitignored) is
  referenced by the App target the same way `Package.swift`'s tests
  already expect it to exist once real adapters are wired.
- [x] 5. Strict typing — not applicable (no new `WG*` public interface).
- [x] 6. Tests from day one — not applicable; this spec adds no testable
  logic (a placeholder `ContentView` has nothing to unit test). Build
  verification (`xcodebuild build`) is this spec's equivalent of a test.
- [x] 7. Provenance by design — not applicable.
- [x] 8. Decisions are recorded — no ADR needed (see spec's review
  checklist): choosing a project generator is a tooling decision within
  the boundary the constitution already governs, not a new one.

## Project structure impact

New:
- `ios/project.yml` — XcodeGen manifest. One `packages:` entry
  (`WorldGuide`, local `path: WorldGuide`); one `targets:` entry
  (`WorldGuide`, `type: application`, `platform: iOS`,
  `deploymentTarget: "16.0"`, `sources: [WorldGuideApp]`, `dependencies:`
  the six library products); `info:` block generated inline (no separate
  `Info.plist` file to maintain) with a placeholder bundle ID
  (`com.xavierbegue.worldguide` — a naming placeholder, trivially changed
  in `project.yml` before any real distribution, not a structural
  decision worth an ADR).
- `ios/WorldGuideApp/WorldGuideApp.swift` — `@main struct WorldGuideApp:
  App`, `WindowGroup { ContentView() }`.
- `ios/WorldGuideApp/ContentView.swift` — placeholder SwiftUI view (app
  name + one-line description), no adapter wiring.

Changed:
- `.gitignore` — add `ios/WorldGuide.xcodeproj/`, `ios/build/`,
  `ios/DerivedData/` (generated/build artifacts, same treatment as the
  SPM package's own `.build/`, already ignored).
- `README.md` — "Créer dans Xcode un target App minimal... est l'étape
  manuelle restante" replaced with the `xcodegen generate` workflow
  (install XcodeGen, run from `ios/`, open the generated project).

Reused, not reimplemented: `ios/WorldGuide`'s existing SPM package and all
six library products, unchanged.

## Phases

1. Phase 1 — `ios/project.yml` + minimal `ios/WorldGuideApp/` sources.
2. Phase 2 — `xcodegen generate`, verify the `.xcodeproj` exists with the
   expected target/dependencies.
3. Phase 3 — `xcodebuild build` (generic iOS Simulator destination, code
   signing disabled) to confirm the App target actually links against the
   package; `.gitignore`/`README.md` updated.

## Verification

From `ios/`: `~/.local/bin/xcodegen generate`, then:
```
xcodebuild build -project WorldGuide.xcodeproj -scheme WorldGuide \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```
No iOS Simulator runtime is installed on this machine, so this is a
build-only check (compiles and links, does not launch) — consistent with
`swift build`/`swift test`'s own simulator-free approach elsewhere in this
repo (docs/adr/0006).
