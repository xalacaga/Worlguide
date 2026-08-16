# ADR 0016: Destination search resolves any place via MapKit and recenters exploration

**Status**: Accepted
**Date**: 2026-08-15

## Context

`specs/013`'s destination search (`POIProviding.searchPOI`,
`WikidataPOIProvider`'s `wikibase:mwapi`/`EntitySearch` query) was
"intentionally not radius-bound" by design, but it could still only ever
return items that exist as Wikidata entities with a coordinate — a small
fraction of what a general maps app knows about. A user standing in Berlin
reported being unable to find a real, well-known place because it either
had no Wikidata item or wasn't a strong EntitySearch label match; the
underlying complaint, once clarified, was "I want this to work exactly like
searching in Apple's own Maps app" — any address, business, or landmark,
anywhere, not just Wikidata-notable ones.

Two ways to satisfy that were considered: (a) make the search result itself
a first-class destination with directions/official-info even when it has no
Wikidata QID, or (b) use the search purely to relocate the exploration
center, then let the existing nearby-POI pipeline (already unrestricted in
where it can point) run from there. (a) would let `POI.id` stop meaning "a
Wikidata QID" everywhere it's currently assumed to (favorites/history
persistence, `WikipediaContentProvider`'s sitelink lookup, provenance) — a
much larger, riskier change for a result set that, for most non-landmark
places, would have no Wikipedia content anyway. (b) reuses the existing
`nearbyPOI(around:radiusMeters:language:)` call unchanged and needs no
change to `POI` at all.

## Decision

- New `WGLocation.PlaceSearching` port: `searchPlaces(matching:near:) async
  throws -> [PlaceResult]`, where `PlaceResult { id, name, subtitle,
  coordinate }` is a lightweight place, not a `POI` — it carries no
  Wikidata identity and is never persisted to favorites/history.
- New `WGLocation.MKLocalSearchPlaceSearcher` (real adapter, same module —
  `MapKit` is a system framework like `CoreLocation`/`AVFoundation`, same
  treatment as [ADR 0011](0011-tts-on-device-not-backend-vendor.md)/
  [ADR 0014](0014-wglocation-module-corelocation.md), not `WGAdapters`).
  Wraps `MKLocalSearch` behind an internal `LocalSearchPerforming` seam
  (mirrors `CLGeocoderCountryCodeProvider`'s wrapping of `CLGeocoder`) so
  the pure trimming/short-query-guard logic stays testable without a live
  MapKit call. `near:` biases (not restricts) results toward the current
  exploration center, matching how typing into Apple Maps' own search field
  behaves.
- `POIProviding.searchPOI` and `WikidataPOIProvider`'s
  `wikibase:mwapi`/`EntitySearch` query are removed — superseded, not kept
  as a second search path. `nearbyPOI` is untouched.
- `NearbyPOIViewModel` gains a `browsingCoordinate` — when set (by picking
  a `PlaceResult`), `loadNearbyPOIs` uses it instead of
  `locationProvider.currentLocation()`, and skips writing to the
  real-location offline cache and skips nearby-alert notifications (both
  are meaningless, or actively wrong, for a place the user isn't physically
  at). An explicit "my location" action clears it and re-fetches the real
  GPS fix.

## Consequences

- Search results are no longer directly playable/detailed content — picking
  one recenters the list/map instead of opening a detail screen. A search
  for a specific landmark now takes one extra tap (recenter, then tap the
  landmark in the refreshed nearby list) but works for literally anywhere
  Apple Maps knows about, which is what was actually being asked for.
- No language parameter on `PlaceSearching` — `MKLocalSearch` has no
  per-request result-language override (results already follow system
  locale), unlike Wikidata's label service.
- No live-device integration test tier for `MKLocalSearchPlaceSearcher`,
  same reasoning [ADR 0014](0014-wglocation-module-corelocation.md) gave
  for `CLLocationManagerLocationProvider`: a live `MKLocalSearch` response
  isn't reproducible/scriptable the way an HTTP fixture is.

## Addendum — 2026-08-16 field-test refinement

Real-device testing refined, but did not reverse, the decision:

- Place search now composes Apple `MKLocalSearch` with a Wikidata named-POI
  searcher (`specs/021`) so important historic/named POIs that Apple search
  under-ranks can still appear.
- `PlaceResult` can optionally carry a Wikidata QID. When it does, the
  selected result may become a normal content-backed `POI` because the QID
  preserves the existing meaning of `POI.id`.
- Apple-only places with no QID can be preserved as synthetic searched-place
  POIs only to keep their coordinate usable for map display, distance and
  directions. They must not claim Wikipedia content or provenance.
- The architectural boundary remains the same: `POIProviding.searchPOI` is
  not restored, nearby discovery still goes through `nearbyPOI`, and
  ordinary place search stays a separate `PlaceSearching` port.

**Correction — 2026-08-16**: `CompositePlaceSearcher`'s dedup initially kept
whichever searcher's result was encountered first, regardless of which one
carried a Wikidata QID — since Apple's searcher ran first in
`CompositionRoot`, the QID from the Wikidata searcher was silently dropped
for any place both searchers found (the common case for real landmarks).
Fixed to always prefer the QID-bearing entry on a duplicate, independent of
searcher order.
