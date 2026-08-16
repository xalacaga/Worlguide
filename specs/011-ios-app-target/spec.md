# Feature Spec: iOS App target (generated via XcodeGen)

**Status**: approved
**Created**: 2026-08-14
**Domain module(s) touched**: iOS: none (no `WG*` module changes); new
`ios/WorldGuideApp/` App target + `ios/project.yml`

## Overview

[ROADMAP.md Phase 5](../../ROADMAP.md), first bullet: "Création du target
App Xcode dépendant du package SPM local." Until now, `ios/WorldGuide` was
SPM-only ([README.md](../../README.md): "Aucun `.xcodeproj` n'est
fourni... Créer dans Xcode un target App minimal... est l'étape manuelle
restante"). This spec automates that manual step with a generated project
instead of a hand-maintained `.xcodeproj`, consistent with the repo's
existing preference for text/reviewable artifacts over opaque binary ones
(`Secrets.xcconfig.example`, Spec Kit docs, ADRs).

This spec deliberately stops at "a real App target that builds and links
against the local package." Wiring the real adapters (`WGAdapters`'
`WikidataPOIProvider`/`WikipediaContentProvider`/etc.) into an actual UI
flow, requesting location permission, and branching TTS playback into the
UI are follow-up work (`ROADMAP.md` Phase 5's remaining two bullets),
scoped to a later spec once this foundation exists.

## User scenarios

- As a developer, I want `xcodegen generate` (from `ios/`) to produce a
  working `.xcodeproj` with an App target depending on all six local SPM
  library products, so that I can open it in Xcode and start building a
  real UI on a known-good foundation, without hand-editing project files.

## Requirements

- [ ] `ios/project.yml` (XcodeGen manifest) defines one App target,
  `WorldGuide`, depending on `ios/WorldGuide` as a local Swift package,
  linking all six existing library products (`WGCore`, `WGConfiguration`,
  `WGPOI`, `WGContent`, `WGPlayback`, `WGAdapters`) — the roadmap's own
  framing is "depends on the local package," not a hand-picked subset.
- [ ] Deployment target `iOS 16`, matching `ios/WorldGuide/Package.swift`'s
  existing `.iOS(.v16)`.
- [ ] `ios/WorldGuideApp/` holds the App target's own minimal source: a
  SwiftUI `App` entry point and a placeholder `ContentView` — no business
  logic, no adapter wiring (out of scope, see Overview).
- [ ] `xcodegen generate` run from `ios/` produces `WorldGuide.xcodeproj`;
  the resulting project builds successfully via `xcodebuild build` for a
  generic iOS Simulator destination with code signing disabled (no signing
  identity exists on this machine — the App target's actual signing
  configuration is left as Xcode's default, to be set by whoever opens the
  project with a real Apple ID/team).
- [ ] `WorldGuide.xcodeproj` and `ios/build/`/`.build/` artifacts are
  gitignored — `project.yml` (text, reviewable) is the versioned source of
  truth; the `.xcodeproj` is a regenerable build artifact, same category
  as `Secrets.xcconfig.example` vs. the gitignored real `Secrets.xcconfig`.
- [ ] `README.md`'s "Créer dans Xcode un target App minimal... est l'étape
  manuelle restante" note is corrected to describe the `xcodegen generate`
  workflow instead.

## Out of scope

- Wiring `WikidataPOIProvider`/`WikipediaContentProvider`/
  `AVSpeechSynthesizerAudioPlayer` into actual UI/state (`ROADMAP.md`
  Phase 5, remaining bullets — a later spec once this target exists).
- `CoreLocation` / location permission (`NSLocationWhenInUseUsageDescription`)
  — not requested by anything in this narrow spec; added when a future
  spec actually calls CoreLocation, not speculatively now.
- Code signing / provisioning profile setup, App Store Connect metadata,
  app icon design (`ROADMAP.md` Phase 6, distribution).
- Installing an iOS Simulator runtime (none is installed on this machine;
  build-only verification via a generic destination does not need one).

## Provenance / data impact

None — no data model, no source, no content.

## Review checklist

- [x] No implementation detail leaked into this spec
- [x] Requirements are testable
- [x] Constitution principles respected (see `.specify/memory/constitution.md`)
- [x] Follow-up ADR filed if this changes a structural boundary — not
  needed: no `WG*` module boundary changes; XcodeGen is a build-tooling
  choice (how the existing package is packaged into an app), not a new
  architectural dependency direction.
