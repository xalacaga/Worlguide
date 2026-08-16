# Implementation Plan: Field-test realtime search, walks and detail polish

**Spec**: `./spec.md`
**Status**: implemented

## Technical context

The work keeps the existing iOS-only architecture. Provider-facing modules
continue to expose typed async ports; real network/place-service calls stay
inside adapters or platform-specific app glue.

The main implementation areas are:

- `WGLocation.PlaceSearching` now carries richer place metadata
  (`isAdministrativePlace`, `wikidataID`) without exposing MapKit.
- `WGLocation.MKLocalSearchPlaceSearcher` remains the Apple place-search
  adapter.
- `WGAdapters.WikidataPlaceSearcher` adds named Wikidata POI search/details.
- `WGAdapters.CompositePlaceSearcher` runs configured searchers in parallel
  and deduplicates results.
- `NearbyPOIViewModel` separates real user location from browsed
  exploration location, observes live updates, caches searches, refreshes
  POIs on movement, and owns walk/start-point rules.
- `ContentView`, `POIMapView`, `WalkRoute` and `POIDetailView` implement
  the user-facing map, walk routing, directions and strict detail layout.

## Constitution check

- No backend introduced; all behavior remains iOS-only.
- No new secret or hardcoded private key.
- Public provider ports remain async and strictly typed.
- Network clients and public-service integration remain out of
  protocol-facing `WG*` interfaces.
- `WGAdapters` is allowed to talk to Wikidata; `WGLocation` is allowed to
  wrap CoreLocation/MapKit platform services.
- Tests were added/updated in the package and app test targets.

## UI rules captured by this feature

- The detail page is a single constrained column. No child view may impose
  a width larger than the visible screen.
- Chapter rows always use the same structure: fixed playback icon column,
  bounded title/preview text, fixed chevron column.
- Route cards and custom walk controls must use measured distances/durations
  returned by MapKit. They must not estimate or invent route values.
- Searched places and browsed cities must not replace the user's real GPS
  as the start point for walks.
- Custom walks must calculate one MapKit route segment per chosen stop in
  order. The internal map is the complete circuit view; Apple Plans handoff
  is limited to explicit per-leg openings to avoid silently dropping
  intermediate stops.

## Verification

- Package tests: `swift test` passed with 102 tests, 1 skipped.
- App test build: `xcodebuild build-for-testing` passed.
- Device build: `xcodebuild build` for the paired iPhone passed.
- Device install: `xcrun devicectl device install app` succeeded.
- Regression: `WalkRouteTests` verifies a five-stop custom walk produces
  five ordered legs with explicit start/end coordinates; `MapDirectionsTests`
  verifies Apple Plans handoff uses the next stop and explicit per-leg items.
