# Tasks: App target test coverage

**Plan**: `./plan.md`

## Phase 1 — Test target wiring

- [x] T001 Add `WorldGuideAppTests` unit test target to `ios/project.yml`
  (hosted, `TEST_HOST`/`BUNDLE_LOADER`)
- [x] T002 Add explicit `schemes:` block wiring the test target into the
  `WorldGuide` scheme's test action

## Phase 2 — Tests

- [x] T003 Write local fakes for `LocationProviding`/`POIProviding`/
  `ContentProviding`/`AudioPlaying`
- [x] T004 Test `loadNearbyPOIs`: success (sorted by distance),
  `.permissionDenied` message, generic-failure message
- [x] T005 Test `select`: loaded/empty/failed content states, and that
  selecting a new POI stops in-flight playback
- [x] T006 Test playback state machine: play → pause → resume → stop

## Phase 3 — Close-out

- [x] T007 `xcodegen generate` + `xcodebuild test` against the booted
  simulator — 8 tests, 0 failures. Note: `xcodebuild test` shuts down the
  simulator after the run (observed side effect); rebooting it before
  further manual verification was needed.
- [x] T008 No ADR needed (see plan.md's Constitution Check)
- [x] T009 Re-run `/graphify` so the knowledge graph reflects the change
