# Tasks: Sectioned content + per-content image fallback

**Plan**: `./plan.md`

## Phase 0 — Structural prerequisite

- [x] T000 [ADR 0015](../../docs/adr/0015-content-package-carries-sections.md):
  `ContentPackage` carries sections, not a flat blob

## Phase 1 — Content model

- [x] T001 Add `WGContent.ContentSection` (`{ id, title, text }`)
- [x] T002 `ContentPackage.sections`/`.imageURL` replace `.text`

## Phase 2 — Extraction

- [x] T003 Rename `WikipediaSummaryExtractor` → `WikipediaArticleExtractor`;
  fetch full article + `pageimages` thumbnail in one call
- [x] T004 Parse `== Heading ==` markers into sections, drop empty-bodied
  ones
- [x] T005 `WikipediaContentProvider`: OSM trailing section, `imageURL`
  wiring — also gained an English-Wikipedia fallback when the requested
  language has no article (post-hoc addition, same session)

## Phase 3 — App UI

- [x] T006 `NearbyPOIViewModel`: `selectedSectionID`, `selectSection`/
  `deselectSection`, `playSelectedContent` reads the selected section
- [x] T007 `POIDetailView`: theme list → selected section + playback;
  image fallback (`poi.imageURL ?? contentPackage.imageURL`); also shows
  a "content shown in a different language" notice when the fallback
  above kicks in
- [x] T008 `CompositionRoot`: updated type name

## Phase 4 — Tests / Verify

- [x] T009 Update `WikipediaArticleExtractorTests`,
  `WikipediaContentProviderTests`, `ContentProvidingTests`,
  `NearbyPOIViewModelTests` for the new shape
- [x] T010 `swift build && swift test`
- [x] T011 `xcodegen generate` + `xcodebuild build`/`test` against the
  booted simulator; reinstall and visually confirmed on a real POI
  ("Exposition Universelle of 1889") — full theme list (11+ sections)
  and a real extracted article image both render correctly

## Phase 5 — Close-out

- [x] T012 No additional ADR needed beyond `ADR 0015` (the English
  fallback is a behavioral change, not a type-shape change)
- [x] T013 Re-run `/graphify` so the knowledge graph reflects the change
