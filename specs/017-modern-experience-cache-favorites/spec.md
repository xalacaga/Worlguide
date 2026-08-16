# Feature Spec: Modern exploration experience + cache/favorites

**Status**: implemented
**Created**: 2026-08-15
**Domain module(s) touched**: iOS App target only (`ios/WorldGuideApp/`,
`ios/WorldGuideAppTests/`)

## Overview

WorldGuide's first working flow existed, but still felt like a plain
technical list. This iteration turns it into a more attractive mobile
experience for younger users while staying inside the existing ports and
adapters.

## Requirements

- [x] Add an in-memory content cache keyed by POI + language so reopening
  the same place does not refetch content during the session.
- [x] Add persistent favorites for POIs.
- [x] Add a recent-history list populated when a POI is opened.
- [x] Add radius options for nearby search: 250 m, 500 m, 1 km, 3 km.
- [x] Add lightweight POI quality scoring from available metadata.
- [x] Add Flash/Complete reading modes, where Flash presents a concise
  version of a selected section without LLM generation.
- [x] Localize the app chrome from the selected language, falling back to
  the iPhone language at startup and English when unsupported.
- [x] Add a `S'y rendre` / Directions action from POI detail that opens
  Apple Maps with walking directions to the selected POI.
- [x] Surface provenance in the POI detail view through a Sources section.
- [x] Modernize the SwiftUI experience with image-led cards, stronger
  visual hierarchy, segmented controls, badges and clearer audio controls.

## Out of scope

- Persistent offline article cache across app launches.
- Map view.
- In-app turn-by-turn navigation.
- Server-side or LLM-based summarization.
- App Store distribution polish.

## Review checklist

- [x] No new network/vendor import outside `WGAdapters`.
- [x] No new configuration key.
- [x] Existing async provider ports unchanged.
- [x] Tests updated for ViewModel behavior.
