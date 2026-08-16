# ADR 0010: Content assembled by extraction, not LLM generation

**Status**: Accepted
**Date**: 2026-08-13

## Context

The original architecture brief called for "génération LLM contrôlée"
(controlled LLM generation) as Phase 3, and `domain/llm/` was scaffolded
accordingly (`GenerationRequest`, `LLMProvider`, `GenerateContent`). When
Phase 3 was about to start, the user reconsidered: no dependency on an LLM
vendor at all — no per-call cost, no vendor lock-in, no API key to manage,
no generation unpredictability. Instead: an algorithm that assembles
content directly from what the sources (Wikipedia, OpenStreetMap) already
say, chosen explicitly over template-based generation for staying closer
to the sources' actual words.

## Decision

Content for a POI is assembled by **extracting real text from its
sources**, not by generating new text:

- A new port, `domain/sources/extractor.py::SourceTextExtractor`
  (`extract_text(poi, language) -> str | None`), lives in the Sources
  module alongside `SourceProvider` — extracting text from a source is
  still "talking to a source," the same responsibility, a different
  question ("what does it say" vs. "where does it point").
- `WikipediaContentExtractor` (`infrastructure/sources/wikipedia/`) fetches
  the real Wikipedia summary text (REST API `page/summary`) for the
  requested language, reusing `WikipediaSourceProvider` internally to find
  the right article title rather than re-querying Wikidata separately.
- `OSMContentExtractor` (`infrastructure/sources/osm/`) composes a short
  line from a POI's OpenStreetMap tags (`tourism`, `historic`,
  `start_date`, `architect`) when present.
- `application/content/assemble_content.py::AssembleContent` orchestrates:
  extract from each source, concatenate, validate (`ContentDraftValidator`,
  same pure-rule-in-`domain/` pattern as `KnowledgePackageValidator`,
  ADR 0004/specs/004), persist as a `ContentPackage` if valid.

`domain/llm/` (`GenerationRequest`, `LLMProvider`, `GenerateContent`,
`infrastructure/llm/`) is **not deleted** — it stays as dormant Phase 0
scaffolding, unused by this feature. If a future need for LLM-assisted
polish appears (e.g. smoothing the concatenated extract into one coherent
paragraph), that is a new, explicit decision revisiting this one — not
something silently reintroduced through the back door.

`domain/content/models.py::ContentDraft.generation_result_id` becomes
optional (`str | None = None`, was required) — an extraction-produced
draft has no LLM `GenerationResult` to reference. Nothing in the codebase
constructed a `ContentDraft` before this feature, so this is a safe
widening, not a breaking change to real callers.

## Consequences

- Content quality is bounded by what the sources literally say — no
  cross-source synthesis, no paraphrasing, no smoothing over
  Wikipedia-summary-plus-OSM-tags reading as two concatenated fragments
  rather than one voice. Accepted as the direct cost of "no LLM
  dependency."
- `WikipediaSourceProvider`'s scope boundary from ADR/specs 003 ("no
  content fetch, just references") is explicitly reversed *for the new
  `WikipediaContentExtractor` class*, not for `WikipediaSourceProvider`
  itself, which keeps returning references only — the two classes have
  different jobs even though they call related Wikipedia endpoints.
- TTS (Phase 4) will read from whatever prose this extraction step
  produces — its naturalness is now this feature's responsibility, not an
  LLM's.
