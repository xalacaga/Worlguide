# WorldGuide

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

## Structure

```
.
├── ios/           # Swift/SwiftUI — modules SPM locaux, toute la logique
│                  # (POI, sources, contenu, TTS on-device)
├── docs/adr/      # décisions structurantes (pourquoi)
├── specs/         # Spec Kit — features (quoi)
├── .specify/      # Spec Kit — constitution + templates
├── .github/       # CI
└── AGENTS.md      # règles permanentes pour tout agent IA
```

Modèle de gouvernance complet (qui répond à quelle question) :
[docs/adr/0007-documentation-governance-model.md](docs/adr/0007-documentation-governance-model.md).

## Démarrage

### iOS

```bash
cd ios/WorldGuide
swift build
swift test
```

Le `.xcodeproj` n'est pas versionné — `ios/project.yml`
([XcodeGen](https://github.com/yonaskolb/XcodeGen), voir
[specs/011](specs/011-ios-app-target/)) est la source de vérité, texte et
review-friendly. Pour générer/régénérer le projet :

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

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — vue d'ensemble technique, index des ADR.
- [docs/adr/](docs/adr/) — pourquoi chaque décision structurante a été prise.
- [AGENTS.md](AGENTS.md) — règles permanentes pour tout agent IA travaillant ici.
- [ROADMAP.md](ROADMAP.md) — prochaines étapes.
- [CHANGELOG.md](CHANGELOG.md) — historique des changements.
- [specs/](specs/) — spécifications de features (Spec Kit), numérotation reprend à `007` (voir [specs/README.md](specs/README.md)).

## Contribution

Avant de modifier le projet, lire [AGENTS.md](AGENTS.md) — il résume les
règles non négociables (indépendance du domaine vis-à-vis des fournisseurs,
séparation stricte des modules, configuration par variables d'environnement,
aucun secret commité, typage strict, tests dès la création d'un module) et
la checklist de fin de tâche (ADR, specs, `/graphify`, CI).
