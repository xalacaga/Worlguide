# Feature Spec: MapKit place search + recenter exploration

**Status**: implemented
**Created**: 2026-08-15
**Domain module(s) touched**: `WGLocation`, `WGPOI`, `WGAdapters`, iOS App
target

## Overview

The destination search box only ever found Wikidata-notable landmarks
(`WikidataPOIProvider`'s `EntitySearch` query, `specs/013`) — a user
standing anywhere could not find a real, ordinary place (an address, a
business, a lesser-known site) the way they can in Apple's own Maps app.
Search first resolved any place worldwide via `MKLocalSearch` and, on
selection, recenters exploration there; WorldGuide's existing nearby-POI
pipeline then runs around the new center, unchanged. A later field-test
iteration ([specs/021](../021-field-test-realtime-search-walk-polish/))
kept this recentering model but added a composite Apple/Wikidata searcher,
query caching, ordinary-place synthetic POIs with coordinates, and special
handling for city/village searches. See
[ADR 0016](../../docs/adr/0016-mapkit-place-search-recenters-exploration.md)
for the full rationale, including why a search result recenters instead of
becoming a detail screen of its own.

## Requirements

- [x] Add a `PlaceSearching` port in `WGLocation` (`PlaceResult { id, name,
  subtitle, coordinate }`), later extended with administrative-place and
  Wikidata-ID metadata in `specs/021`.
- [x] Add `MKLocalSearchPlaceSearcher`, wrapping `MKLocalSearch` behind an
  internal `LocalSearchPerforming` seam for testability.
- [x] Remove `POIProviding.searchPOI` and `WikidataPOIProvider`'s
  `EntitySearch` query — fully superseded, not kept as a second path.
- [x] `NearbyPOIViewModel`: `browsingCoordinate`, `jumpToPlace(_:)`,
  `returnToMyLocation()`; `loadNearbyPOIs` uses `browsingCoordinate` when
  set instead of the device's real location.
- [x] Skip the real-location offline-POI cache write and nearby-alert
  notifications while browsing a searched location — both assume the user
  is physically where the coordinate points.
- [x] `ContentView`: search results are tappable rows that recenter
  (`jumpToPlace`), not `POI` rows opening a detail screen; a banner shows
  the browsed place's name with a "My location" button to return to the
  real GPS fix.
- [x] New localized strings (`exploringPlace`, `returnToMyLocation`); reuse
  existing `searchingPlaces`/`noSearchResult`/`placeSearchFailure`
  (renamed from `destinationSearchFailure`).
- [x] Post-020 behavior from `specs/021`: repeated queries are cached;
  Apple/Wikidata searchers run in parallel; named POIs like historic sites
  can surface via Wikidata; ordinary Apple-only places keep map/detail
  coordinates; administrative results show up to 10 nearby POIs.

## Non-goals

- Turning every `PlaceResult` into a full content-backed POI was out of
  scope for this feature. `specs/021` later added a narrower fallback:
  ordinary searched places can be represented as coordinate-bearing
  synthetic POIs for map/directions, without pretending Wikipedia content
  exists.
- Per-language search results — `MKLocalSearch` has no such parameter.
- Fixing the pre-existing offline nearby-POI cache key (`language|radius`,
  no coordinate) — a latent issue, but not one this feature should make
  worse by writing browsed-location results into it (this feature avoids
  that; it does not fix the underlying key).

## Review checklist

- [x] `WGLocation` stays the only module referencing `MapKit`/`CoreLocation`
  types outside their own adapters.
- [x] App UI depends on `PlaceSearching`, not `MKLocalSearch` directly.
- [x] New user-facing strings go through `AppStrings`.
- [x] Tests added for `MKLocalSearchPlaceSearcher` (short-query guard, query
  trimming, bias-coordinate forwarding, result/error pass-through).
- [x] `NearbyPOIViewModelTests` cover `jumpToPlace`/`returnToMyLocation`
  (browsing state, cache/notification skip, GPS restore).
