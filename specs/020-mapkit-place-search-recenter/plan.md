# Implementation Plan: MapKit place search + recenter exploration

**Spec**: `./spec.md`
**Status**: implemented

## Technical context

This feature replaces the Wikidata-`EntitySearch`-based destination search
with a `MapKit`-backed one, and changes what selecting a result does: it
relocates the exploration center instead of opening a detail screen. The
existing `nearbyPOI(around:radiusMeters:language:)` pipeline is otherwise
untouched — `POI`, `ContentPackage`, favorites/history all keep meaning
exactly what they meant before.

The original adapter graph:

- `MKLocalSearchPlaceSearcher` (new, `WGLocation`) wraps `MKLocalSearch`
  behind `LocalSearchPerforming` for testability, biased (not restricted)
  toward the current exploration center.
- `WikidataPOIProvider.searchPOI` and its `EntitySearch` SPARQL query are
  deleted, along with `POIProviding.searchPOI`.

Later field-test work in
[`specs/021`](../021-field-test-realtime-search-walk-polish/) adds
`WGAdapters.CompositePlaceSearcher` and `WikidataPlaceSearcher` on top of
this port. That does not restore the old `POIProviding.searchPOI` path; it
keeps place search separate from nearby-POI discovery.

## UI

`ContentView`'s search field, on a query ≥ 2 characters, shows tappable
place rows (name + locality/country subtitle) instead of `POI` rows.
Tapping one calls `NearbyPOIViewModel.jumpToPlace(_:)`, which sets
`browsingCoordinate` and reloads nearby POIs around it; a banner then shows
the browsed place's name with a "My location" button
(`returnToMyLocation()`) that clears `browsingCoordinate` and re-fetches
the real GPS fix.

As of `specs/021`, `returnToMyLocation()` prefers the latest known live GPS
fix to avoid blocking after browsing a remote city, and non-administrative
ordinary search results can be preserved as coordinate-bearing synthetic
POIs when no equivalent WorldGuide POI exists.

`loadNearbyPOIs` branches on `browsingCoordinate`:
- present → skip `locationProvider.currentLocation()`, skip the
  real-location offline cache write, skip nearby-alert notifications.
- absent → unchanged existing behavior.

## Constitution check

- No backend — `MKLocalSearch` runs directly on-device via Apple's own
  service, same treatment as `MapDirections`' existing `MKMapItem` use.
- `WGLocation` stays the only module referencing `MapKit` types outside its
  own adapter, mirroring how `CoreLocation` is scoped there.
- No secrets or hardcoded endpoints (n/a — no HTTP endpoint here).
- No LLM generation.

## Verification

- `cd ios/WorldGuide && swift test`
- `cd ios && xcodegen generate --spec project.yml`
- `cd ios && xcodebuild test -project WorldGuide.xcodeproj -scheme WorldGuide -destination 'platform=iOS Simulator,name=iPhone 17'`
- `cd ios && xcodebuild build -project WorldGuide.xcodeproj -scheme WorldGuide -destination 'generic/platform=iOS Simulator'`
- Manual: search a non-landmark address far outside the current radius,
  confirm it appears, tap it, confirm the list/map recenters there and a
  "My location" banner appears; tap it, confirm return to the real GPS fix.
