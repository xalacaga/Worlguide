# Feature Spec: Device location via CoreLocation

**Status**: approved
**Created**: 2026-08-15
**Domain module(s) touched**: iOS: new `WGLocation` module
([ADR 0014](../../docs/adr/0014-wglocation-module-corelocation.md)),
`WGCore` (`WGError.permissionDenied`), `ios/project.yml` (location usage
description)

## Overview

[ROADMAP.md Phase 5](../../ROADMAP.md) — wiring the real adapters into a
UI needs the device's current location:
`WikidataPOIProvider.nearbyPOI(around:radiusMeters:)` (`specs/007`) takes
a `Coordinate`, and the app uses the same coordinate to sort destination
search results by distance.
[ADR 0014](../../docs/adr/0014-wglocation-module-corelocation.md) is the
structural decision (new module) this spec implements.

## User scenarios

- As a user opening the app, I want it to ask for my location once and
  give the UI a `Coordinate`, so that a nearby-POI query has real input
  instead of a hardcoded one.
- As a user searching for a destination, I want results ordered by distance
  from where I am, so closer matches appear first even when the search itself
  is global.

## Requirements

- [ ] `LocationProviding` (new protocol, `WGLocation`): `func
  currentLocation() async throws -> Coordinate` — single-shot, reuses
  `WGCore.Coordinate`.
- [ ] `CountryCodeProviding` (protocol, `WGLocation`): `func
  countryCode(for coordinate: Coordinate) async throws -> String` — returns
  an ISO-3166 alpha-2 code such as `FR` or `DE` for future country-aware
  features.
- [ ] `CLLocationManagerLocationProvider: LocationProviding` (new, same
  module) — requests when-in-use authorization if not yet determined,
  then a single location fix, bridging `CLLocationManagerDelegate`'s
  callbacks into `async`/`await`.
- [ ] `CLGeocoderCountryCodeProvider: CountryCodeProviding` (same module)
  reverse-geocodes the coordinate via `CLGeocoder` and uppercases the
  returned ISO country code.
- [ ] Authorization denied/restricted surfaces as `WGError.permissionDenied`
  (new case, `WGCore`) — not a generic network/decoding error, so a caller
  can show a specific "location access needed" message.
- [ ] Location/positioning failures (e.g. `CLError` from the framework)
  surface as `WGError.network` — same treatment `specs/007`'s
  `WikidataPOIProvider` gives transport failures, no new error case
  needed for this.
- [ ] `CoreLocation` types do not leak through
  `CLLocationManagerLocationProvider`'s public interface — same rule
  `specs/010` applied to `AVFoundation` (`Package.swift`'s review-enforced
  boundary).
- [ ] `ios/project.yml`'s App target gains
  `NSLocationWhenInUseUsageDescription` — required before iOS will even
  show the authorization prompt.

## Out of scope

- Continuous location updates, background location, significant-change
  monitoring — only a single current-location fetch, per
  [ADR 0014](../../docs/adr/0014-wglocation-module-corelocation.md).
- Any UI screen, permission-denied messaging, or retry flow — this spec
  is the port + adapter only; wiring it into an actual nearby-POI screen
  is a later spec.
- A live/manual test tier — a location fix isn't scriptable the way an
  HTTP response is; testing is entirely against a fake `CLLocationManager`
  seam.

## Provenance / data impact

None — location is an input to a query, not content shown to the user;
`Provenance` is unaffected.

## Review checklist

- [x] No implementation detail leaked into this spec
- [x] Requirements are testable
- [x] Constitution principles respected (see `.specify/memory/constitution.md`)
- [x] Follow-up ADR filed if this changes a structural boundary — yes:
  [ADR 0014](../../docs/adr/0014-wglocation-module-corelocation.md),
  written before this spec, covers the new module boundary.
