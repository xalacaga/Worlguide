# Feature Spec: POI discovery via Wikidata (on-device)

**Status**: approved
**Created**: 2026-08-14
**Domain module(s) touched**: iOS: WGPOI (existing Protocol), WGAdapters (new)

## Overview

The app finds points of interest (POI) by querying Wikidata directly from
the device — no backend. It supports two discovery modes: nearby POIs around
the current coordinate, and explicit global destination search for known POIs.
This is the first real implementation of
`WGPOI.POIProviding`, the Protocol port that has existed since Phase 0 with
only a test fake behind it. See
[ADR 0012](../../docs/adr/0012-ios-only-no-backend.md) for why there is no
backend to do this instead.

## User scenarios

- As a user standing somewhere in the world, I want the app to list notable
  POIs within a radius of my location, so that I can pick one to learn
  about.
- As a user looking for a known place, I want the app's place search to cover
  the world instead of only the current 3 km radius or current country, so
  that I can find the right destination and still see nearby matches first.

## Requirements

- [ ] `WikidataPOIProvider` (new, `WGAdapters`) implements `POIProviding`
  by querying the public Wikidata Query Service (SPARQL,
  `SERVICE wikibase:around` on `wdt:P625`) for items with a coordinate
  within `radiusMeters` of the given `Coordinate`.
- [ ] `POIProviding.searchPOI(matching:language:)` searches explicit
  destinations globally via Wikidata `EntitySearch`. The app language still
  controls labels and Wikipedia sitelinks; the app layer sorts returned POIs
  by distance from the user's current coordinate.
- [ ] Each result maps to a `POI` (existing model, `WGPOI`): `id` = the
  Wikidata QID, `name` = the label, `coordinate` parsed from the returned
  point, `category` = best-effort from an instance-of (`wdt:P31`) label
  when present, `hasWikipediaArticle` from the language-specific sitelink,
  and `imageURL` from `P18` when present.
- [ ] Network/decoding failures surface as `WGError.network` /
  `WGError.decoding` (existing type, `WGCore`) — no new error type.
- [ ] The HTTP call is injectable for testing (`HTTPTransport` protocol,
  new) — no real network access in the default `swift test` run.

## Out of scope

- Server-side nearest-result ordering for global search; Wikidata
  `EntitySearch` provides candidates, then the app sorts by distance.
- Caching results across app launches (Phase 2+ concern, if ever).
- Wikipedia/OSM sources, content assembly, summarization (Phase 2/3).
- Wiring into an actual app UI (no Xcode App target exists yet, Phase 5).

## Provenance / data impact

Every `POI` already carries its Wikidata QID as `id` — this is itself the
provenance link back to the source, consistent with how the (now deleted)
backend treated `wikidata_qid`. No separate provenance model is introduced
at this layer; source-level provenance (`Provenance`, `WGCore`) is a
Phase 2/3 concern once sources beyond "the POI exists" are fetched.

## Review checklist

- [x] No implementation detail leaked into this spec
- [x] Requirements are testable
- [x] Constitution principles respected (see `.specify/memory/constitution.md`)
- [x] Follow-up ADR filed if this changes a structural boundary — not
  needed: this is the first *use* of the adapter-module boundary already
  established by ADR 0003/0012, not a new boundary.
