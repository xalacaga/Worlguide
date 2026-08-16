# Implementation Plan: Sectioned content + per-content image fallback

**Spec**: `./spec.md`
**Status**: approved

## Technical context

Extends `WGContent`/`WGAdapters` (`specs/009`) and `ios/WorldGuideApp/`
(`specs/013`). No new module. Verified directly against the MediaWiki API
before implementing: `prop=extracts` (no `exintro`) preserves `== Heading
==` markers in plaintext, and `prop=extracts|pageimages` combines into one
HTTP call.

## Constitution check

- [x] 1–5 — same shape as `specs/009`'s existing adapters; no new vendor
  import outside `WGAdapters`; no `Any`.
- [x] 6. Tests from day one — `WikipediaArticleExtractorTests`,
  `WikipediaContentProviderTests`, `ContentProvidingTests`,
  `NearbyPOIViewModelTests` all updated for the new shape, not just left
  passing by coincidence.
- [x] 7. Provenance by design — see spec's "Provenance / data impact".
- [x] 8. Decisions are recorded —
  [ADR 0015](../../docs/adr/0015-content-package-carries-sections.md)
  covers the `ContentPackage` shape change; this plan needs no ADR of its
  own.

## Project structure impact

Changed:
- `ios/WorldGuide/Sources/WGContent/ContentPackage.swift` — `sections:
  [ContentSection]` replaces `.text`; new `imageURL: URL?`.
- `ios/WorldGuide/Sources/WGContent/ContentSection.swift` (new) — `{ id,
  title, text }`, `Identifiable`.
- `ios/WorldGuide/Sources/WGAdapters/WikipediaSummaryExtractor.swift` →
  renamed `WikipediaArticleExtractor.swift`: `sections(forTitle:language:)
  -> [ArticleSection]?` (internal-to-file `ArticleSection` decoded
  result), parses `== Heading ==`, drops empty-bodied sections; also
  returns the `pageimages` thumbnail URL.
- `ios/WorldGuide/Sources/WGAdapters/WikipediaContentProvider.swift` —
  orchestrates sections + OSM trailing section + `imageURL`.
- `ios/WorldGuideApp/NearbyPOIViewModel.swift` — `selectedSectionID`,
  `selectSection`/`deselectSection`; `playSelectedContent` reads the
  selected section's text.
- `ios/WorldGuideApp/POIDetailView.swift` — theme-list / selected-section
  views; image fallback.
- `ios/WorldGuideApp/CompositionRoot.swift` — constructs
  `WikipediaArticleExtractor` instead of the old type name.

## Verification

`swift build && swift test` (SPM package regression) +
`xcodegen generate` + `xcodebuild build`/`test` against the booted
simulator, same pattern every prior spec this session used.
