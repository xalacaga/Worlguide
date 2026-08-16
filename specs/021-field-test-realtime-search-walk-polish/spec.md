# Feature Spec: Field-test realtime search, walks and detail polish

**Status**: implemented
**Created**: 2026-08-16
**Domain module(s) touched**: `WGLocation`, `WGAdapters`, iOS App target

## Overview

Real-device testing showed gaps that only appear in actual travel use:
the GPS dot could stay where the app opened, searched places without a
Wikipedia/Wikidata article had no usable location in their detail, some
important named POIs were missed by MapKit-only search, custom walks had to
start from the user's real position, and a few long detail pages could force
the SwiftUI layout wider than the iPhone screen.

This iteration turns the app into a live exploration surface: location
updates continue while the app is open, POIs refresh after meaningful user
movement, destination search combines Apple place search with Wikidata named
POI search, walk routes can be built from chosen POIs, and the detail page
uses a strict single-column layout shared by every POI.

## Requirements

- [x] Keep listening to live location updates while the app is open; update
  `userCoordinate` even while browsing another city.
- [x] Re-sort nearby POIs as the user moves and refresh the POI catalog when
  the user enters a new zone.
- [x] Make `returnToMyLocation()` use the latest known live GPS fix instead
  of blocking on a fresh one-shot CoreLocation request.
- [x] Separate the browsing/exploration coordinate from the distance
  reference coordinate, so searched locations can be explored while result
  distances still reflect the user's real position when known.
- [x] Extend place search with a composite searcher: Apple `MKLocalSearch`
  for ordinary places plus Wikidata search/details for named historic POIs.
- [x] Run Apple and Wikidata place search in parallel, search Wikidata in
  multiple languages, deduplicate results, and cache repeated queries.
- [x] If a searched result is administrative (city/village), show up to 10
  interesting nearby POIs around that place instead of only a synthetic city
  card.
- [x] Preserve a synthetic searched-place POI with coordinates for ordinary
  places that have no WorldGuide/Wikipedia POI, so directions and map
  location still work.
- [x] Add custom walk building: every POI detail can add/remove that POI from
  the walk, ordered stops build a route on the map, and displayed distances
  and durations come only from MapKit route responses.
- [x] Route calculation is sequential per selected stop
  (`current GPS -> stop 1 -> stop 2 -> ...`), not only origin-to-final
  destination. Apple Plans handoff opens the next leg, and each displayed
  leg exposes its own transit handoff button, because the public API does
  not guarantee full multi-stop transit guidance from a third-party app.
- [x] Walk routes always start from the user's real GPS position when known,
  not from the currently browsed city.
- [x] Offer walking, cycling, driving and public-transport directions where
  supported. Public transport is delegated to Apple Plans because WorldGuide
  does not own a free realtime transit feed.
- [x] Make the map show the user's heading/direction while tracking.
- [x] Remove duplicate configuration chrome, keep language selection in the
  configuration menu, and hide weather/energy controls.
- [x] Make detail-page playback an icon at the beginning of each chapter,
  with pause/resume on the active chapter, and remove the old bottom
  "listen" button.
- [x] Enforce one strict detail layout for all POIs: the page width is bound
  to the visible screen, long titles/buttons/licenses cannot expand it, and
  chapter rows use a fixed icon/text/chevron grid.

## Non-goals

- In-app realtime public-transport departure data. Apple Maps can compute
  and present the transit route when opened, but Apple does not expose the
  full Maps transit planner as a free app API for WorldGuide.
- Invented distances or durations. Walk and route values must come from
  MapKit route calculations or be omitted.
- Background location tracking after the app is closed.

## Verification

- `cd ios/WorldGuide && swift test`
- `xcodebuild build-for-testing -project ios/WorldGuide.xcodeproj -scheme WorldGuide ...`
- `xcodebuild build -project ios/WorldGuide.xcodeproj -scheme WorldGuide -destination id=...`
- `xcrun devicectl device install app --device ... WorldGuide.app`
- Real-device checks: Berlin search/detail layout, return to "Ma position",
  Sachsenhausen search, ordinary-place search (e.g. cafe), custom walk route
  from current GPS, custom walk with at least five selected POIs.
