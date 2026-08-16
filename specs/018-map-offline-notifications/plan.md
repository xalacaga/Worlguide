# Implementation Plan: Map, offline cache and smart notifications

**Spec**: `./spec.md`
**Status**: implemented

## Technical context

This is an app-target iteration. It reuses existing POI/content/location
ports and adds UI/state behavior around them:

- `POIMapSupport` owns map region and visible-annotation policy.
- `ContentView` owns the List/Map switch and keeps the search UI limited to
  list mode.
- `NearbyPOIViewModel` persists POI and content snapshots in `UserDefaults`
  using Codable app read models already available in the target.
- `NearbyNotificationScheduler` wraps `UserNotifications` behind a small
  app-local protocol so tests can use fakes.

## Constitution check

- No network code, HTTP client or source-specific SDK was added outside
  `WGAdapters`.
- Provider protocol contracts in SPM modules remain unchanged and async.
- No hardcoded external URL/key/flag was added.
- No public Swift module interface gained `Any`.
- Tests stay in `ios/WorldGuideAppTests` because this feature lives in the
  app target.

## Verification

- `swift test` from `ios/WorldGuide`
- `xcodebuild test -project WorldGuide.xcodeproj -scheme WorldGuide
  -destination 'platform=iOS Simulator,name=iPhone 17'`
- `xcodebuild build -project WorldGuide.xcodeproj -scheme WorldGuide
  -destination 'generic/platform=iOS Simulator'`

## Follow-up design note

The next content-quality improvement should add a separate fallback path for
official sources when Wikipedia has no usable article. Candidate priority:
POI official website from Wikidata/OSM, tourism office page, city/metropole
page, then regional/national institution. If source language differs from
the selected app or iPhone language, translated text must be clearly marked
as translated and keep the original source provenance visible.
