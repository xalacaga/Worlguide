# Tasks: Field-test realtime search, walks and detail polish

**Plan**: `./plan.md`

## Phase 1 - Live GPS and nearby refresh

- [x] T001 Keep observing live location updates while the app is open.
- [x] T002 Re-sort loaded POIs from the latest user coordinate.
- [x] T003 Refresh the nearby POI catalog after meaningful movement.
- [x] T004 Make `returnToMyLocation()` use the latest known live GPS fix.

## Phase 2 - Search quality and speed

- [x] T005 Extend `PlaceResult` with administrative-place and Wikidata ID
  metadata.
- [x] T006 Add `WikidataPlaceSearcher` for named POIs that MapKit may miss.
- [x] T007 Add `CompositePlaceSearcher` and run Apple/Wikidata search in
  parallel.
- [x] T008 Search Wikidata in multiple languages in parallel and deduplicate
  by QID.
- [x] T009 Cache repeated place-search queries in `NearbyPOIViewModel`.
- [x] T010 Preserve ordinary searched places as map/detail POIs with real
  coordinates even without Wikipedia content.
- [x] T011 Show up to 10 interesting POIs for administrative place searches.

## Phase 3 - Map, walks and directions

- [x] T012 Add heading/direction display on the map.
- [x] T013 Add "Ajouter a la balade" from POI detail.
- [x] T014 Add custom walk stop ordering and clearing.
- [x] T015 Build route geometry, distance and duration from MapKit route
  responses.
- [x] T016 Ensure smart/custom walks start from real GPS when available.
- [x] T017 Offer walking, cycling, driving and Apple Plans public-transport
  routing paths where supported.
- [x] T017a Ensure custom walk routes build one sequential leg per selected
  POI and open Apple Plans only for the next leg to avoid dropped waypoints.
- [x] T017b Add per-leg transit buttons so each balade segment can be opened
  explicitly in Apple Plans.

## Phase 4 - Detail layout and playback

- [x] T018 Move language selection to configuration and remove duplicate
  gear/weather/energy UI from the main surface.
- [x] T019 Replace bottom "listen" playback with per-chapter icon controls.
- [x] T020 Make the active chapter icon toggle pause/resume.
- [x] T021 Enforce a strict single-column detail layout with bounded image,
  title, buttons, sources and chapter rows.

## Phase 5 - Tests / verify

- [x] T022 Add/update tests for search preservation, administrative place
  POIs, live GPS return, and walk start-point rules.
- [x] T023 Add `WikidataPlaceSearcherTests` for named historic POI search.
- [x] T023a Add `WalkRouteTests` and `MapDirectionsTests` coverage for
  multi-stop custom walks and next-leg Apple Plans handoff.
- [x] T024 Run `swift test`.
- [x] T025 Run `xcodebuild build-for-testing`.
- [x] T026 Build and install on the paired iPhone.

## Phase 6 - Documentation / graph

- [x] T027 Update README, CHANGELOG, ROADMAP and related specs.
- [x] T028 No new ADR needed: this is product behavior and adapter
  composition, not a new architectural boundary.
- [x] T029 Re-run `/graphify` after documentation updates.
