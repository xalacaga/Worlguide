# Feature Spec: POI sources — Wikipedia sitelinks + OSM tags (on-device)

**Status**: approved
**Created**: 2026-08-14
**Domain module(s) touched**: iOS: WGCore (`Provenance.SourceKind`), WGAdapters
(new adapters, no new module)

## Overview

[ROADMAP.md Phase 2](../../ROADMAP.md) — before any content can be assembled
(Phase 3) for a `POI` (found in Phase 1 via `WikidataPOIProvider`), the app
must resolve, directly from the device, *which* Wikipedia article covers it
in the requested language, and *which* OpenStreetMap tags apply near it. No
backend ([ADR 0012](../../docs/adr/0012-ios-only-no-backend.md)) — this
reprises the old, deleted `specs/003` and `specs/005`.

This spec stops at "sources found and lightly validated." Extracting a
summary from the Wikipedia article and composing text from OSM tags is
[ROADMAP.md Phase 3](../../ROADMAP.md) — not spec'd yet — not here.

## User scenarios

- As a user who has found a POI (Phase 1), I want the app to know which
  Wikipedia article (in my language, falling back to a default) describes
  it, and which OSM tags exist for it, so that Phase 3 has real source
  material to build content from instead of just a name and a QID.

## Requirements

- [ ] `WikipediaSitelinkResolver` (new, `WGAdapters`) resolves a Wikidata
  QID to a Wikipedia article title for a given language edition, via
  Wikidata's `wbgetentities` action API (`props=sitelinks`) — reuses
  `HTTPTransport` (existing, `specs/007`). Returns `nil` (not a thrown
  error) when no sitelink exists for the requested language: a missing
  article is an expected, common case, not a failure.
- [ ] `OverpassTagFetcher` (new, `WGAdapters`) fetches OpenStreetMap tags
  for the nearest node/way within a fixed small radius of a `Coordinate`,
  via the public Overpass API. Returns an empty `[String: String]` (not a
  thrown error) when nothing is found nearby — same reasoning as above.
- [ ] `POISources` (new value type, `WGAdapters`): bundles a `poiID`, the
  resolved Wikipedia article title (`String?`) with its language, the OSM
  tags (`[String: String]`), and a `[Provenance]` array reflecting which of
  the two sources actually returned something (empty sources contribute no
  `Provenance` entry).
- [ ] `Provenance.SourceKind` (existing, `WGCore`) gains an
  `.openStreetMap` case — the two prior cases (`wikipedia`, `wikidata`)
  aren't enough to describe an OSM-sourced tag.
- [ ] Light validation before assembly: a source contributes to
  `POISources.provenance` only if present (non-nil title / non-empty tags).
  No license field is populated yet for OSM (`license: nil` is valid,
  `Provenance.license` is already optional) — OSM's ODbL attribution
  handling is deferred to Phase 3/5 (UI attribution), not decided here.
- [ ] Network/decoding failures (transport error, malformed JSON) surface
  as `WGError.network` / `WGError.decoding` (existing type) — only "source
  absent" is a soft `nil`/empty result, not every failure.
- [ ] Nothing is persisted across app launches — the roadmap explicitly
  scopes this to in-memory/session-local results (Phase 2+ caching is out
  of scope, same as spec 007's "no caching" note).

## Out of scope

- Extracting the Wikipedia summary text or composing an OSM-tag line
  (Phase 3).
- Wiring `POISources` into `WGContent.ContentProviding` (Phase 3).
- OSM attribution/license display in UI (Phase 5+).
- Caching `POISources` across app launches or sessions.
- Choosing *which* language to request (caller-supplied, same pattern as
  `ContentProviding.content(forPOI:language:)`).

## Provenance / data impact

`POISources.provenance` is the first *client-side* place where more than
one `Provenance.SourceKind` can appear together for the same POI (Wikidata
already implicit via the POI's `id`/QID, now Wikipedia and OpenStreetMap
join it) — consistent with the multi-source model
[ADR 0004](../../docs/adr/0004-knowledge-package-provenance.md) describes,
reimplemented here without a backend.

## Review checklist

- [x] No implementation detail leaked into this spec
- [x] Requirements are testable
- [x] Constitution principles respected (see `.specify/memory/constitution.md`)
- [x] Follow-up ADR filed if this changes a structural boundary — not
  needed: no new module, `WGAdapters` already owns "talks to
  Wikidata/Wikipedia/OSM" per `AGENTS.md`'s repo map; adding an
  `openStreetMap` case to an existing enum is additive, not structural.
