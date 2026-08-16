# WorldGuide

[Français](#francais) | [English](#english)

<a id="francais"></a>

## Français

WorldGuide est un audioguide intelligent mondial : une app iOS **100%
autonome** ([ADR 0012](docs/adr/0012-ios-only-no-backend.md), pas de
backend) qui géolocalise l'utilisateur, retrouve les points d'intérêt (POI)
à proximité en interrogeant directement Wikidata/Wikipedia/OpenStreetMap,
assemble un contenu par extraction de ces sources (pas de génération LLM,
[ADR 0010](docs/adr/0010-content-via-extraction-not-llm-generation.md)) et
le lit à voix haute en synthèse vocale on-device
([ADR 0011](docs/adr/0011-tts-on-device-not-backend-vendor.md)).

L'app dispose déjà d'un premier flux utilisable : localisation de
l'utilisateur, recherche de POI proches via Wikidata à 500 m par défaut,
résultats triés du plus proche au plus loin, recherche textuelle mondiale
de destination via Apple Plans/Wikidata avec cache de requête, suivi GPS en
temps réel tant que l'app est ouverte, rafraîchissement des POI après
déplacement significatif, interface d'exploration allégée avec réglages
rangés dans un menu compact, vue liste ou carte interactive avec direction
utilisateur, extraction de contenu Wikipedia/OSM, choix d'un thème
d'article, affichage d'image Wikidata/Wikipedia, favoris, historique,
cache offline local des derniers POI et contenus déjà ouverts, rayon de
recherche réglable, mode Flash/Complet, notifications locales optionnelles
quand un POI est vraiment proche, construction de balade à partir de POI
choisis avec distances/temps issus de MapKit, itinéraires dans Apple Plans
(à pied, vélo, voiture, transports quand disponible), fiche `Infos
officielles` avec site officiel, adresse, horaires, prix/téléphone quand
disponibles et traduction automatique iOS 18+, ainsi que lecture vocale
on-device par chapitre. Voir [ROADMAP.md](ROADMAP.md) pour l'état détaillé
et les prochaines étapes.

### Structure

```text
.
|-- ios/           # Swift/SwiftUI - modules SPM locaux, toute la logique
|                  # (POI, sources, contenu, TTS on-device)
|-- docs/adr/      # décisions structurantes (pourquoi)
|-- specs/         # Spec Kit - features (quoi)
|-- .specify/      # Spec Kit - constitution + templates
|-- .github/       # CI
`-- AGENTS.md      # règles permanentes pour tout agent IA
```

Modèle de gouvernance complet :
[docs/adr/0007-documentation-governance-model.md](docs/adr/0007-documentation-governance-model.md).

### Démarrage

```bash
cd ios/WorldGuide
swift build
swift test
```

Le `.xcodeproj` n'est pas versionné. `ios/project.yml`
([XcodeGen](https://github.com/yonaskolb/XcodeGen), voir
[specs/011](specs/011-ios-app-target/)) est la source de vérité. Pour
générer ou régénérer le projet :

```bash
xcodegen generate --spec ios/project.yml
open ios/WorldGuide.xcodeproj
```

Le target App `WorldGuide` dépend du package SPM local (`ios/WorldGuide`,
tous les modules). Pour lancer l'app avec les adapters réels, copier
`ios/WorldGuide/Secrets.xcconfig.example` vers `Secrets.xcconfig`
(gitignored) et renseigner les endpoints publics utilisés par Wikidata,
Wikipedia et Overpass. Les `Infos officielles` sont ensuite résolues depuis
Wikidata/OSM puis chargées depuis le site officiel du POI quand une page
exploitable est disponible ; si aucun site propre au POI n'est trouvé,
l'app tente aussi les offices/centres touristiques institutionnels proches
déclarés dans OpenStreetMap.

La CI vérifie deux niveaux :

```bash
cd ios/WorldGuide && swift build && swift test
cd ios && xcodegen generate --spec project.yml
cd ios && xcodebuild build -project WorldGuide.xcodeproj -scheme WorldGuide \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

### Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - vue d'ensemble technique, index des ADR.
- [docs/adr/](docs/adr/) - pourquoi chaque décision structurante a été prise.
- [AGENTS.md](AGENTS.md) - règles permanentes pour tout agent IA travaillant ici.
- [ROADMAP.md](ROADMAP.md) - prochaines étapes.
- [CHANGELOG.md](CHANGELOG.md) - historique des changements.
- [specs/](specs/) - spécifications de features (Spec Kit), numérotation reprend à `007` (voir [specs/README.md](specs/README.md)).

### Contribution

Avant de modifier le projet, lire [AGENTS.md](AGENTS.md). Il résume les
règles non négociables : indépendance du domaine vis-à-vis des fournisseurs,
séparation stricte des modules, configuration par variables d'environnement,
aucun secret commité, typage strict, tests dès la création d'un module, et
checklist de fin de tâche (ADR, specs, `/graphify`, CI).

## English

WorldGuide is a global intelligent audio guide: a **fully standalone** iOS app
([ADR 0012](docs/adr/0012-ios-only-no-backend.md), no backend) that locates the
user, discovers nearby points of interest (POIs) by querying
Wikidata/Wikipedia/OpenStreetMap directly, assembles content by extracting from
those sources (no LLM generation,
[ADR 0010](docs/adr/0010-content-via-extraction-not-llm-generation.md)), and
reads it aloud with on-device text-to-speech
([ADR 0011](docs/adr/0011-tts-on-device-not-backend-vendor.md)).

The app already has a usable end-to-end flow: user location, nearby POI search
through Wikidata within 500 m by default, results sorted from nearest to
farthest, worldwide text destination search through Apple Maps/Wikidata with a
query cache, realtime GPS tracking while the app is open, POI refresh after
significant movement, a lighter exploration UI with settings grouped in a
compact menu, list or interactive map views with user heading, Wikipedia/OSM
content extraction, article theme selection, Wikidata/Wikipedia images,
favorites, history, a local offline cache for recent POIs and opened content,
adjustable search radius, Flash/Full modes, optional local notifications when a
POI is genuinely nearby, custom walks built from selected POIs with
MapKit-provided distances and durations, Apple Maps directions (walking,
cycling, driving, and transit when available), an `Official info` sheet with
official website, address, opening hours, prices/phone when available and
automatic translation on iOS 18+, plus on-device per-chapter audio playback.
See [ROADMAP.md](ROADMAP.md) for the detailed status and next steps.

### Structure

```text
.
|-- ios/           # Swift/SwiftUI - local SPM modules, all app logic
|                  # (POIs, sources, content, on-device TTS)
|-- docs/adr/      # architectural decisions (why)
|-- specs/         # Spec Kit - features (what)
|-- .specify/      # Spec Kit - constitution + templates
|-- .github/       # CI
`-- AGENTS.md      # permanent rules for AI coding agents
```

Full governance model:
[docs/adr/0007-documentation-governance-model.md](docs/adr/0007-documentation-governance-model.md).

### Getting Started

```bash
cd ios/WorldGuide
swift build
swift test
```

The `.xcodeproj` is not versioned. `ios/project.yml`
([XcodeGen](https://github.com/yonaskolb/XcodeGen), see
[specs/011](specs/011-ios-app-target/)) is the review-friendly source of
truth. To generate or regenerate the project:

```bash
xcodegen generate --spec ios/project.yml
open ios/WorldGuide.xcodeproj
```

The `WorldGuide` app target depends on the local SPM package
(`ios/WorldGuide`, all modules). To run the app with real adapters, copy
`ios/WorldGuide/Secrets.xcconfig.example` to `Secrets.xcconfig` (gitignored)
and fill in the public endpoints used by Wikidata, Wikipedia, and Overpass.
`Official info` is resolved from Wikidata/OSM and then loaded from the POI's
official website when an extractable page is available. If no POI-specific
website is found, the app also tries nearby official tourist offices or
institutional tourism centers declared in OpenStreetMap.

CI checks two levels:

```bash
cd ios/WorldGuide && swift build && swift test
cd ios && xcodegen generate --spec project.yml
cd ios && xcodebuild build -project WorldGuide.xcodeproj -scheme WorldGuide \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

### Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - technical overview and ADR index.
- [docs/adr/](docs/adr/) - why each structural decision was made.
- [AGENTS.md](AGENTS.md) - permanent rules for AI coding agents working here.
- [ROADMAP.md](ROADMAP.md) - next steps.
- [CHANGELOG.md](CHANGELOG.md) - change history.
- [specs/](specs/) - feature specifications (Spec Kit), numbering resumes at `007` (see [specs/README.md](specs/README.md)).

### Contributing

Before changing the project, read [AGENTS.md](AGENTS.md). It summarizes the
non-negotiable rules: domain independence from vendors, strict module
separation, configuration through environment-style build settings, no committed
secrets, strict typing, tests whenever a module is created, and the completion
checklist (ADR, specs, `/graphify`, CI).
