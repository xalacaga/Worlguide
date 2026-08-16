# Tasks: Official POI Info

**Plan**: `./plan.md`

## Phase 1 - Structured non-Wikipedia info

- [x] T001 Extend OSM structured tags surfaced in the OpenStreetMap section.
- [x] T002 Keep OSM handling pure and free of extra I/O.
- [x] T003 Update adapter tests for the clearer OSM output.

## Phase 2 - External official content

- [x] T004 Add `ExternalContentPackage`, `ExternalPracticalInfo` and
  `ExternalContentProviding`.
- [x] T005 Add Wikidata official website resolver.
- [x] T006 Add bounded official site extractor.
- [x] T007 Add `OfficialSiteContentProvider` combining Wikidata, OSM and the
  official page.
- [x] T008 Add tests for site extraction and practical info helpers.

## Phase 3 - POI detail UX

- [x] T009 Add a localized `Infos officielles` button next to `S'y rendre`.
- [x] T010 Add official info sheet with source, practical info and text.
- [x] T011 Add automatic translation on iOS 18+ with original fallback.
- [x] T012 Add ViewModel test for external content state.
- [x] T013 Add nearby tourism-office/visitor-centre fallback from OSM when
  the POI has no official website.
- [x] T014 Update README, CHANGELOG and ROADMAP.
- [x] T015 Run SPM tests, app tests and app build.
- [x] T016 Re-run `/graphify`.
