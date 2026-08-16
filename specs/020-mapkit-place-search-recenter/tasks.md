# Tasks: MapKit place search + recenter exploration

**Plan**: `./plan.md`

## Phase 0 — Structural prerequisite

- [x] T000 [ADR 0016](../../docs/adr/0016-mapkit-place-search-recenters-exploration.md):
  destination search resolves any place via MapKit and recenters
  exploration, replacing Wikidata `EntitySearch`

## Phase 1 — Place search port + adapter

- [x] T001 Add `WGLocation.PlaceSearching` port (`PlaceResult`)
- [x] T002 Add `MKLocalSearchPlaceSearcher` (+ `LocalSearchPerforming` seam)
  and its tests

## Phase 2 — Remove the Wikidata-EntitySearch path

- [x] T003 Remove `POIProviding.searchPOI`
- [x] T004 Remove `WikidataPOIProvider.searchPOI` + `EntitySearch` SPARQL
  query + related tests

## Phase 3 — App wiring

- [x] T005 `NearbyPOIViewModel`: `browsingCoordinate`, `jumpToPlace(_:)`,
  `returnToMyLocation()`, `placeSearch*` state (renamed from
  `destinationSearch*`); `loadNearbyPOIs` skips real-location cache write
  and nearby-alert notifications while browsing
- [x] T006 `ContentView`: place-result rows, browsing banner, renamed
  `schedulePlaceSearch`
- [x] T007 `CompositionRoot`: construct `MKLocalSearchPlaceSearcher`, pass
  to `NearbyPOIViewModel`
- [x] T008 New `AppStrings` (`exploringPlace`, `returnToMyLocation`);
  rename `destinationSearchFailure` → `placeSearchFailure`

## Phase 4 — Tests / Verify

- [x] T009 Update `POIProvidingTests`, `WikidataPOIProviderTests`,
  `NearbyPOIViewModelTests` for the new shape
- [x] T010 `swift build && swift test`
- [x] T011 `xcodegen generate` + `xcodebuild build`/`test` against the
  booted simulator; manually verify search-and-recenter for a non-landmark
  place outside the current radius

## Phase 5 — Close-out

- [x] T012 No additional ADR needed beyond `ADR 0016`
- [x] T013 Re-run `/graphify --update` so the knowledge graph reflects the
  change
- [x] T014 Post-020 field-test follow-up documented in
  [`specs/021`](../021-field-test-realtime-search-walk-polish/): composite
  Apple/Wikidata search, query cache, administrative-place POI expansion,
  searched-place coordinate preservation and non-blocking return to live GPS
