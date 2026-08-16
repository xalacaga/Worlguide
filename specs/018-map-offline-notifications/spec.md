# Feature Spec: Map, offline cache and smart notifications

**Status**: implemented
**Created**: 2026-08-15
**Domain module(s) touched**: iOS App target only (`ios/WorldGuideApp/`,
`ios/WorldGuideAppTests/`)

## Overview

WorldGuide should feel useful in motion, not only as a list. This iteration
adds a readable interactive map, keeps recent exploration usable when public
services are slow or unavailable, and lets the user opt in to local nearby
alerts without creating notification noise.

## Requirements

- [x] Add a List/Map exploration switch on the main screen.
- [x] Show nearby, favorite or history POIs on an interactive map.
- [x] Keep the map readable by limiting visible annotations, hiding
  permanent POI labels and showing overflow count only when relevant.
- [x] Let the user tap a marker to select a POI and open its detail; do not
  preselect a POI card on map load.
- [x] Show the user's heading/direction on the map while tracking (added by
  [specs/021](../021-field-test-realtime-search-walk-polish/)).
- [x] Persist the latest nearby POI results per language/radius for offline
  fallback.
- [x] Persist content packages after opening a POI, keyed by POI and
  language, so previously read content survives app relaunches.
- [x] Show an explicit offline notice when cached POIs are displayed after a
  network failure.
- [x] Add opt-in local notifications for very close POIs.
- [x] Avoid notification spam with a proximity threshold and per-POI cooldown.
- [x] Keep all app chrome aligned with the selected app language or the
  iPhone language fallback.

## Out of scope

- Turn-by-turn navigation inside WorldGuide.
- Background location tracking.
- In-app turn-by-turn/public-transit guidance. WorldGuide delegates those
  routes to Apple Plans; see
  [specs/021](../021-field-test-realtime-search-walk-polish/).
- Downloading every POI/article in an area before the user opens it.
- Institutional-source fallback when Wikipedia has no useful content.
- Automatic translation of official-source pages.

## Next product questions

- When Wikipedia is empty, should the app first use the POI official website,
  the local tourism office, or a city/metropole page?
- Should automatic translation use an Apple on-device framework where
  available, or a configurable external provider behind an adapter?
- How should translated content display provenance so users know what is
  original source text and what was translated?

## Review checklist

- [x] No new network/vendor import outside `WGAdapters`.
- [x] No new configuration key or secret.
- [x] Existing async provider ports unchanged.
- [x] Tests added for map annotation filtering, offline cache and
  notification policy.
