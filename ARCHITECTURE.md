# Architecture

Cette page est un index. Le détail de chaque décision — et surtout le
*pourquoi* — vit dans [docs/adr/](docs/adr/) ; ce document se contente de
donner la vue d'ensemble pour s'y repérer. Pour "comment le système
fonctionne concrètement et où intervenir", relancer `/graphify` (voir
[docs/adr/0007](docs/adr/0007-documentation-governance-model.md)) plutôt que
de chercher la réponse ici.

## Vue d'ensemble

```
┌──────────────────────────────────────────────────────────┐
│  iOS app (SwiftUI)                                        │
│                                                             │
│  WGPOI / WGContent / WGPlayback / WGLocation               │
│    (domain-shaped Protocol ports — POIProviding,           │
│     ContentProviding, AudioPlaying, PlaceSearching,        │
│     LocationProviding)                                     │
│      ▲                                                      │
│  adapter module(s)  (implémentent ces Protocol, seuls       │
│    autorisés à parler réseau/vendor)                        │
└───────────┬───────────────┬───────────────┬────────────────┘
            │               │               │
            ▼               ▼               ▼
       Wikidata        Wikipedia          OSM          Apple services
      (SPARQL/API,    (REST, sources/   (Overpass,    (CoreLocation,
       POI/search)      extraction)      sources)       MapKit/Plans)
```

Pas de backend ([ADR 0012](docs/adr/0012-ios-only-no-backend.md)) : l'app
parle directement aux services publics dont elle a besoin, et fait
elle-même le tri/l'assemblage/le résumé. Synthèse vocale on-device via
`AVSpeechSynthesizer` ([ADR 0011](docs/adr/0011-tts-on-device-not-backend-vendor.md)).

## iOS — modules SPM locaux

`WGCore` (types partagés), `WGConfiguration`, `WGPOI`, `WGContent`,
`WGPlayback`, `WGLocation` — chacun expose un `Protocol` de port ; seul un
module adapter dédié peut importer un client réseau et parler à un service
externe. `WGLocation` encapsule les services système Apple liés à la
localisation et à la recherche de lieux (CoreLocation/MapKit), selon
[ADR 0014](docs/adr/0014-wglocation-module-corelocation.md) et
[ADR 0016](docs/adr/0016-mapkit-place-search-recenters-exploration.md).
Rationale : [ADR 0003](docs/adr/0003-provider-pattern-and-ios-module-scope.md).

## Décisions structurantes (ADR)

1. [Monorepo et frontières des modules](docs/adr/0001-monorepo-and-module-boundaries.md)
2. ~~[Architecture hexagonale backend](docs/adr/0002-hexagonal-architecture-backend.md)~~ — supersédée par l'ADR 12
3. [Pattern Provider partagé et périmètre des modules iOS](docs/adr/0003-provider-pattern-and-ios-module-scope.md)
4. [Provenance des Knowledge Packages](docs/adr/0004-knowledge-package-provenance.md)
5. [Configuration par variables d'environnement](docs/adr/0005-configuration-via-environment.md)
6. [Stratégie de tests et CI comme gate](docs/adr/0006-testing-strategy-and-ci-gate.md)
7. [Modèle de gouvernance documentaire](docs/adr/0007-documentation-governance-model.md)
8. [Frontière async des ports domaine](docs/adr/0008-async-io-boundary-for-domain-ports.md)
9. ~~[Services managés, zéro infra auto-gérée](docs/adr/0009-managed-services-no-self-operated-infrastructure.md)~~ — supersédée par l'ADR 12
10. [Contenu par extraction, pas par génération LLM](docs/adr/0010-content-via-extraction-not-llm-generation.md)
11. [TTS on-device, pas de vendor backend](docs/adr/0011-tts-on-device-not-backend-vendor.md)
12. [App iOS 100% autonome, pas de backend](docs/adr/0012-ios-only-no-backend.md)

## Qualité

- iOS : `swift build && swift test` (macOS, sans simulateur).
- CI : `.github/workflows/ci.yml` fait tourner ce job en gate de fusion.
