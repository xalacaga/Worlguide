# Tasks: Modern exploration experience + cache/favorites

**Plan**: `./plan.md`

## Phase 1 — Product state

- [x] T001 Add radius options and selected radius to `NearbyPOIViewModel`
- [x] T002 Add in-memory content cache keyed by POI + language
- [x] T003 Add persistent favorites via `UserDefaults`
- [x] T004 Add recent POI history via `UserDefaults`
- [x] T005 Add Flash/Complete reading modes
- [x] T006 Add lightweight POI quality score
- [x] T006a Add app UI strings that follow the selected/iPhone language
- [x] T006b Add walking directions launcher for a selected POI

## Phase 2 — UI

- [x] T007 Modernize the nearby screen with a visual hero, segmented
  Autour/Favoris/Historique control, radius controls and image-led POI cards
- [x] T008 Modernize the detail screen with large image header, favorite
  action, reading mode picker, theme cards and clearer audio controls
- [x] T009 Add Sources/provenance disclosure to the detail screen
- [x] T009a Add a localized `S'y rendre` button to POI detail
- [x] T009b Wire the main `Chercher un lieu` field to global destination
  search instead of limiting it to the visible nearby radius or current
  country; sort returned results by distance from the user.
- [x] T009c Reduce main-screen visual load by keeping Autour/Favoris/Historique
  visible and moving secondary controls into compact actions.

## Phase 3 — Tests / Verify

- [x] T010 Update `NearbyPOIViewModelTests` for cache, radius, favorites,
  history, Flash mode and selected-language strings
- [x] T010a Add app tests for Apple Maps walking launch options
- [x] T011 Run app tests through `xcodebuild test`
- [x] T012 Run SPM regression tests
- [x] T013 Run `xcodegen generate` and `xcodebuild build`

## Phase 4 — Close-out

- [x] T014 No ADR needed: no structural boundary or public module contract
  changed
- [x] T015 Re-run `/graphify` so the knowledge graph reflects the change
