# Tasks: Background audio playback

**Plan**: `./plan.md`

## Phase 1 — Capability declaration

- [x] T001 Add `UIBackgroundModes: [audio]` to `ios/project.yml`'s App
  target `info.properties` — verified present in the *built* app's
  `Info.plist`, not just the source template (same `$(...)` substitution
  caveat `specs/013` already documented)

## Phase 2 — Session management

- [x] T002 Define internal `AudioSessionConfiguring` protocol (`#if
  os(iOS)`) + `AVAudioSession` conformance
- [x] T003 Wire session activation (`.playback`/`.spokenAudio`) into
  `play()`, deactivation (`.notifyOthersOnDeactivation`) into `stop()`

## Phase 3 — Verify

- [x] T004 `xcodegen generate` + `xcodebuild build` (iOS Simulator
  destination) — succeeded; the `#if os(iOS)` branch compiles cleanly
- [x] T005 `swift build && swift test` — 65 tests, 0 failures, 1 opt-in
  live test skipped as expected (regression check; the new session code
  itself is untestable here, see plan.md's Constitution Check)
- [ ] T006 Reinstall on the booted simulator, play a POI's content,
  background the app (home button / app switch), confirm speech
  continues — not independently verified: no interactive tap capability
  in this environment (no Accessibility automation permission) to press
  Play, so background continuation could not be exercised end-to-end.
  The capability declaration and session-activation code are both
  confirmed present and building correctly; a human should confirm the
  actual audible behavior on-device.

## Phase 4 — Close-out

- [x] T007 No ADR needed (see plan.md's Constitution Check)
- [x] T008 Re-run `/graphify` so the knowledge graph reflects the change
- [ ] T009 Confirm CI is green before merge — pending human verification;
  note CI's `ios` job does not build the App target (`specs/011`'s known
  gap) so it cannot catch a regression in this spec's `#if os(iOS)` code
  either — a real, inherited limitation, not new to this spec
