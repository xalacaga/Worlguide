# Implementation Plan: Modern exploration experience + cache/favorites

**Spec**: `./spec.md`
**Status**: implemented

## Technical context

This is an app-target iteration. It composes features already exposed by
the SPM modules and does not alter provider contracts:

- `NearbyPOIViewModel` owns app UI state: radius, tabs, reading mode,
  favorites, history and a session content cache.
- Favorites/history persist POI read models as JSON in `UserDefaults`.
- Content cache stays in memory only.
- SwiftUI views consume the same ViewModel and avoid new dependencies.

## Constitution check

- No new network code, SDK import or vendor dependency was added to a
  protocol-facing module.
- No hardcoded external URL/key/flag was added.
- No public Swift module interface gained `Any`.
- Tests were updated in `WorldGuideAppTests`.

## Verification

- `xcodebuild test -project WorldGuide.xcodeproj -scheme WorldGuide
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO`
- `swift test` from `ios/WorldGuide`
- `xcodegen generate --spec project.yml`
- `xcodebuild build -project WorldGuide.xcodeproj -scheme WorldGuide
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO`
