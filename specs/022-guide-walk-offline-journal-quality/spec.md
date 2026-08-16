# Feature 022 - Guide, Walk, Offline, Journal and Quality

## Goal

Turn WorldGuide from a search-and-read app into a more active visit companion
while staying iOS-only and source-grounded.

## Requirements

- [x] Guide in walk mode detects a nearby POI from live GPS updates and exposes
  a prompt to start the short audio guide. An automatic playback mode can also
  start the first available chapter once per POI.
- [x] Smart walks remain configurable by duration and theme, and continue to
  use only measured MapKit routes for explicit custom-route distances.
- [x] Offline area packs save the current area POI catalog and prefetch bounded
  content for top POIs into the existing local cache.
- [x] Travel journal entries can carry a persistent personal note and include
  it in the export text.
- [x] POI quality and confidence are visible to users through labels based on
  available source signals: Wikipedia article, image, type/category and GPS
  distance.
- [x] Quick POI filters are available from the main screen for must-see places,
  monuments, museums, nature and cafes/food, in addition to source-completeness
  filters.
- [x] City/village searches explicitly state that the displayed list is the
  interesting-place set around the administrative place.
- [x] Audio playback supports user-selected speed while preserving on-device
  AVSpeechSynthesizer playback.

## Non-goals

- Offline Apple Maps tiles or offline turn-by-turn navigation. Those are not
  exposed as a reliable third-party app cache API.
- Realtime public-transport feeds. Transit routing remains delegated to Apple
  Maps unless a future transport-data provider is explicitly added.
- Photo capture in the travel journal. This tranche adds persistent notes; photo
  attachment requires media permissions, local file lifecycle and UI review.
