# Implementation Plan: Official POI Info

**Spec**: `./spec.md`
**Status**: implemented

## Technical context

This feature adds an app-visible official information sheet while preserving
the existing Wikipedia flow. The network implementation stays inside
`WGAdapters`; the app target receives an `ExternalContentProviding` port.

The adapter graph:

- resolves the POI's official website from Wikidata P856;
- falls back to OSM `website`, `contact:website` or `url`;
- fetches one bounded page card from that official URL;
- combines that text with OSM practical fields such as address, hours,
  phone and fee/charge.

## UI

`POIDetailView` shows two adjacent actions: `S'y rendre` and
`Infos officielles`. The official-info sheet shows source, practical info,
provenance and the official text. On iOS 18+, SwiftUI's Translation task
translates the text into the selected app language when needed.

## Constitution check

- No backend.
- Network clients stay inside `WGAdapters`.
- No secrets or hardcoded endpoints.
- No LLM generation of missing facts.

## Verification

- `cd ios/WorldGuide && swift test`
- `cd ios && xcodegen generate --spec project.yml`
- `cd ios && xcodebuild test -project WorldGuide.xcodeproj -scheme WorldGuide -destination 'platform=iOS Simulator,name=iPhone 17'`
- `cd ios && xcodebuild build -project WorldGuide.xcodeproj -scheme WorldGuide -destination 'generic/platform=iOS Simulator'`
