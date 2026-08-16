# Tasks: iOS App target (generated via XcodeGen)

**Plan**: `./plan.md`

## Phase 0 — Tooling prerequisite

- [x] T000 Build XcodeGen from source (`swift build -c release` against
  its own SPM package — no Homebrew on this machine) and install to
  `~/.local/bin/xcodegen` (local machine setup, not part of the repo)

## Phase 1 — Manifest and App sources

- [x] T001 Write `ios/project.yml`: `WorldGuide` App target, iOS 16
  deployment target, depends on all six `ios/WorldGuide` library products
- [x] T002 Write `ios/WorldGuideApp/WorldGuideApp.swift` (SwiftUI `@main`
  entry point)
- [x] T003 Write `ios/WorldGuideApp/ContentView.swift` (placeholder view,
  no adapter wiring)

## Phase 2 — Generate

- [x] T004 Run `xcodegen generate` from `ios/`, confirm
  `WorldGuide.xcodeproj` is created with the expected target

## Phase 3 — Verify

- [x] T005 `xcodebuild build` against a generic iOS Simulator destination
  with code signing disabled — confirms the App target links against the
  local package. Surfaced a real latent bug in the process: `WGAdapters`
  imports `WGContent` (`WikipediaContentProvider.swift`) but
  `Package.swift` never declared that target dependency — `swift build`
  tolerated it, Xcode's module dependency validation did not. Fixed in
  `Package.swift` alongside this task. No simulator runtime was installed
  either; `xcodebuild -downloadPlatform iOS` fetched the iOS 26.5
  Simulator component first (user-approved, ~multi-GB download).

## Phase 4 — Close-out

- [x] T006 Add `ios/WorldGuide.xcodeproj/`, `ios/build/`,
  `ios/Generated-Info.plist` to `.gitignore`
- [x] T007 Update `README.md`'s "manual step remaining" note to describe
  the `xcodegen generate` workflow
- [x] T008 No ADR needed (see plan.md's Constitution Check)
- [x] T009 Re-run `/graphify` so the knowledge graph reflects the change
- [ ] T010 Confirm CI is green before merge — pending human verification;
  note CI's `ios` job (`.github/workflows/ci.yml`) currently only runs
  `swift build`/`swift test` against the SPM package, not `xcodegen`/
  `xcodebuild` — extending CI to build the App target is a follow-up, not
  part of this spec's own verification
