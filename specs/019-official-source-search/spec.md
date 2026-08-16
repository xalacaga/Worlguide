# Feature Spec: Official POI Info

**Status**: implemented
**Created**: 2026-08-15
**Domain module(s) touched**: iOS App target, `WGContent`, `WGAdapters`

## Overview

Users can look beyond Wikipedia, including official websites, tourism-office
pages and public institutional pages, even when a Wikipedia article exists.
WorldGuide shows a bounded `Infos officielles` sheet inside the app, with
practical fields for visitors and automatic translation when Apple
Translation is available.

## Requirements

- [x] Add an `ExternalContentProviding` port in `WGContent`.
- [x] Resolve official websites from Wikidata P856 first, then OSM website
  tags when available.
- [x] If no POI-specific website is available, try nearby institutional
  tourism sources from OpenStreetMap (`office=tourism`,
  `tourism=information`, visitor centres) and use their official website.
- [x] Fetch a bounded official page card in `WGAdapters`: title, metadata
  description and first meaningful paragraphs, not a full site mirror.
- [x] Surface practical fields when available: official website, address,
  opening hours, price hint and phone.
- [x] Add a localized `Infos officielles` button next to `S'y rendre` in POI
  detail.
- [x] Keep Wikipedia content unchanged: official info is available whether
  or not the POI has Wikipedia content.
- [x] Translate official text automatically to the selected app language on
  iOS 18+ via Apple Translation, with original text as fallback.

## Non-goals

- Full website crawling, multi-page scraping or mirroring institutional
  content.
- Bypassing robots/paywalls, adding a backend, or using an LLM to invent
  missing practical information.

## Review checklist

- [x] Network implementation remains confined to `WGAdapters`.
- [x] App UI depends on `ExternalContentProviding`, not concrete network
  clients.
- [x] New user-facing strings go through `AppStrings`.
- [x] Tests added for external content state, official site extraction and
  practical info helpers.
- [x] Tests added for the nearby institutional OpenStreetMap fallback.
