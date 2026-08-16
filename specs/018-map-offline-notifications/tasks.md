# Tasks: Map, offline cache and smart notifications

**Plan**: `./plan.md`

## Phase 1 - Interactive map

- [x] T001 Add map region and visible-annotation helpers.
- [x] T002 Add a List/Map switch to the main exploration controls.
- [x] T003 Render POIs on an interactive map.
- [x] T004 Limit map annotations further, remove permanent marker labels and
  hide overflow count unless some results are hidden.
- [x] T005 Add a selected-POI card with navigation to detail, shown only
  after the user taps a marker.
- [x] T006 Hide the search field in map mode to avoid overlay clutter.

## Phase 2 - Offline cache

- [x] T007 Persist latest nearby POI results by language/radius.
- [x] T008 Fall back to persisted POI results after network failures.
- [x] T009 Persist loaded content packages by POI/language.
- [x] T010 Reuse persisted content across ViewModel instances.
- [x] T011 Show a localized offline notice when cached POIs are used.

## Phase 3 - Smart notifications

- [x] T012 Add app-local notification scheduling protocol and no-op fake.
- [x] T013 Request notification permission only when the user opts in.
- [x] T014 Notify only for POIs within the close-proximity threshold.
- [x] T015 Add cooldown logic to avoid repeated alerts for the same POI.
- [x] T016 Add localized notification copy.

## Phase 4 - Tests / Verify

- [x] T017 Add map support tests for region fallback and annotation limits.
- [x] T018 Add ViewModel tests for offline POI cache and persisted content.
- [x] T019 Add ViewModel tests for notification opt-in/denied behavior.
- [x] T020 Add notification policy tests.
- [x] T021 Run SPM regression tests.
- [x] T022 Run app tests through `xcodebuild test`.
- [x] T023 Run app build through `xcodebuild build`.

## Phase 5 - Close-out

- [x] T024 Update README, CHANGELOG and ROADMAP.
- [x] T025 No ADR needed: no structural boundary or public module contract
  changed.
- [x] T026 Re-run `/graphify` so the knowledge graph reflects the change.
