# Feature Spec: Sectioned content + per-content image fallback

**Status**: implemented
**Created**: 2026-08-15
**Domain module(s) touched**: iOS: `WGContent` (`ContentPackage` shape,
[ADR 0015](../../docs/adr/0015-content-package-carries-sections.md)),
`WGAdapters` (`WikipediaArticleExtractor`, `WikipediaContentProvider`),
`ios/WorldGuideApp/` (theme picker UI)

## Overview

Two real gaps found from live use:
1. `specs/009`'s `exintro`-only extraction under-delivers for any article
   with real body sections (e.g. "Cort Theatre (San Francisco)": one
   lead paragraph fetched, two more full sections about the venue's
   later renamings never fetched at all) — and the fix isn't just "fetch
   more," it's "let the user choose what to hear" (ADR 0015).
2. Some POIs have no Wikidata `P18` image (`specs/016`'s own testing:
   "Cort Theatre (San Francisco)" has none) but do have a Wikipedia
   "page image" (a lead/infobox photo MediaWiki computes automatically) —
   worth trying as a fallback before showing nothing.

## User scenarios

- As a user who has selected a POI, I want to see a list of topics
  (sections) about it and pick one to read/hear, instead of one long
  block of text read start to finish.
- As a user viewing a POI with no Wikidata photo, I want the app to still
  try Wikipedia's own lead image before giving up on showing one.

## Requirements

- [x] `ContentPackage.sections: [ContentSection]` replaces `.text`
  ([ADR 0015](../../docs/adr/0015-content-package-carries-sections.md)).
  `ContentPackage` also gains `imageURL: URL?`.
- [x] `WikipediaArticleExtractor` (renamed from `WikipediaSummaryExtractor`)
  fetches the full article (`explaintext`, no `exintro`) plus a
  `pageimages` thumbnail in one combined API call, and splits the text on
  `== Heading ==` markers into `[ArticleSection]` (title + text), dropping
  sections with no body text after processing.
- [x] `WikipediaContentProvider` appends the OSM line (`specs/009`) as a
  trailing section titled `"OpenStreetMap"`; sets `ContentPackage.imageURL`
  from the article extractor's thumbnail.
- [x] `NearbyPOIViewModel` gains section selection: `select(_ poi:)` shows
  a theme list first; picking a section shows only that section's text +
  playback controls for it (never the whole article read start to
  finish). Switching sections (or POIs) while playing stops playback
  first, same rule `specs/013` already established for POI switches.
- [x] `POIDetailView` shows `poi.imageURL ?? contentPackage.imageURL` —
  the Wikidata list-level image if present, else the content-level
  Wikipedia fallback once loaded.
- [x] Follow-up from [specs/021](../021-field-test-realtime-search-walk-polish/):
  each chapter now has its own leading playback icon, and the detail view
  uses a strict bounded layout so long section titles or article text cannot
  widen the page.

## Out of scope

- Nested/hierarchical section display (Wikipedia's `===` subsections are
  flattened to the same list level, not shown as a tree) — a flat list of
  themes is enough for "pick a topic," a tree adds UI complexity for
  little gain at this stage.
- Filtering by section name pattern (e.g. hiding "References" by string
  match) — sections are dropped by "has no body text after processing"
  instead, which generalizes across languages (ADR 0015).
- Caching fetched sections/images across app launches.

## Provenance / data impact

`POISources.assemble`'s existing "source present → provenance entry" rule
is reused unchanged — Wikipedia's provenance entry now reflects "the
article had at least one usable section," not "the intro was non-empty,"
a strictly looser condition that only rules out is genuinely empty
articles.

## Review checklist

- [x] No implementation detail leaked into this spec
- [x] Requirements are testable
- [x] Constitution principles respected (see `.specify/memory/constitution.md`)
- [x] Follow-up ADR filed if this changes a structural boundary — yes:
  [ADR 0015](../../docs/adr/0015-content-package-carries-sections.md),
  written before this spec, covers the `ContentPackage` shape change.
