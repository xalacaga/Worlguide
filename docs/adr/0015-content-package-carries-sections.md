# ADR 0015: `ContentPackage` carries named sections, not one text blob

**Status**: Accepted
**Date**: 2026-08-15

## Context

Real user feedback on `specs/009`'s design: `exintro` (the Wikipedia lead
section) is honest but thin — for an article like "Cort Theatre (San
Francisco)", the lead is one paragraph while the article's actual body
(the theatre's several renamings: Curran, Century, Morosco, Capitol) is
two more full sections the app never fetched at all. The user's ask
wasn't just "more text" — it was to *choose* a theme before hearing
anything ("je dois pouvoir choisir ma thématique... pas tout me lire d'un
coup"), i.e. a real UX requirement, not only a data-completeness one.

Verified directly against the MediaWiki API: `action=query&prop=extracts
&explaintext=1` (dropping `exintro`) returns the *entire* article as
plain text, with section headers preserved as literal `== Heading ==`
markers in the stream — Wikipedia's own structure is already exactly the
"themes" the user asked for, no invented taxonomy needed.

## Decision

- `WGContent.ContentPackage` drops `text: String`, gains `sections:
  [ContentSection]`. `ContentSection` is `{ id, title, text }` — `id`
  stable per package (slug of title or index), `title` either
  `"Introduction"` (the pre-heading lead) or the literal Wikipedia
  heading text in whatever language was requested (sections are already
  language-native, e.g. French Wikipedia's "Historique").
- `WGAdapters.WikipediaSummaryExtractor` is renamed
  `WikipediaArticleExtractor` (it no longer fetches only a summary) and
  its `summary(forTitle:language:)` becomes `sections(forTitle:language:)
  -> [ArticleSection]?`, parsing the `== Heading ==` markers itself —
  still on-device, plain string splitting, no new dependency.
- Sections whose body is empty after processing are dropped (e.g. a
  trailing "References"/"External links" section, whose prose content
  MediaWiki's plaintext extract already strips to nothing) — filtered by
  "is there actual text," not by matching section-name patterns, so it
  generalizes across languages without a translation table.
- `WikipediaContentProvider` appends the OSM line (`specs/009`) as its
  own trailing section titled `"OpenStreetMap"` (a proper noun, not
  translated, same treatment `"Wikipedia"` itself already gets) instead
  of concatenating it into the lead paragraph.
- The app (`ios/WorldGuideApp/`) changes from "load POI → show all text →
  play" to "load POI → show a list of section titles → user picks one →
  show that section's text + playback controls for it." Playing narrates
  one chosen section, never the whole article at once.

## Consequences

- Breaking change to `ContentPackage`'s public shape, same treatment
  `ADR 0013` gave `AudioAsset`: accepted without hesitation, no released
  version, only this repo's own tests/fakes consume it.
- `NearbyPOIViewModel` gains a `selectedSectionID` concept and
  `selectSection`/`deselectSection`, mirroring how it already handles
  `select(_ poi:)` stopping in-flight playback (`specs/013`) — the same
  rule now also applies to switching sections within one POI.
- Fetching the full article (vs. just the intro) is a larger response
  per request; accepted, still a single HTTP call, no pagination or
  incremental-loading complexity introduced.
- Section splitting is a plain-text heuristic (regex on `== ... ==`
  markers), not a real wikitext/HTML parser — accepted as
  "good enough for a themes list," consistent with `ADR 0010`'s
  extraction-not-generation, extraction-not-full-parsing stance.
