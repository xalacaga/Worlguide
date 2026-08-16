# Changelog

Tous les changements notables de ce projet seront documentés dans ce fichier.

Le format suit l'esprit de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/) et le versionnement pourra suivre [Semantic Versioning](https://semver.org/lang/fr/) lorsque le projet aura des versions publiées.

## [Unreleased]

### Added

- App iOS SwiftUI `WorldGuide` générée via XcodeGen, dépendant du package
  SPM local et couverte par un target `WorldGuideAppTests`.
- Découverte des POI proches via Wikidata SPARQL en direct depuis l'app,
  avec libellés localisés, distance depuis la position utilisateur et image
  Wikidata quand disponible, avec requêtes bornées et triées par distance
  côté Wikidata pour garder les rayons larges réactifs. Les POI indiquent
  aussi s'ils ont un article Wikipedia dans la langue active.
- Recherche de destination via `MKLocalSearch` (comme dans Plans) : le champ
  `Chercher un lieu` trouve n'importe quel lieu dans le monde (adresse,
  commerce, lieu-dit...), pas seulement ceux ayant une fiche Wikidata.
  Sélectionner un résultat recentre l'exploration à cet endroit — les POI
  WorldGuide à proximité s'y rechargent ensuite normalement — avec un
  bandeau `Ma position` pour revenir à sa position réelle.
- Recherche de destination enrichie par `CompositePlaceSearcher` : Apple
  `MKLocalSearch` et Wikidata sont interrogés en parallèle, Wikidata est
  tenté en plusieurs langues, les résultats sont dédupliqués et les requêtes
  répétées sont servies depuis un cache local de session. Les lieux
  ordinaires sans Wikipedia gardent une localisation exploitable, et les
  villes/villages affichent jusqu'à 10 POI intéressants autour d'eux.
- Resolver `WGLocation.CountryCodeProviding` basé sur `CLGeocoder`, pour
  obtenir le code pays ISO depuis la position courante sans mélanger cette
  logique dans l'interface.
- Récupération des sources Wikipedia/OSM côté iOS : sitelinks Wikipedia,
  tags OpenStreetMap via Overpass, provenance associée aux contenus.
- Extraction d'articles Wikipedia complets par sections, image fallback
  `pageimages`, section OpenStreetMap complémentaire et fallback vers
  Wikipedia anglais quand l'édition demandée n'a pas d'article.
- Flux SwiftUI localisation → liste de POI → détail → choix d'un thème →
  lecture vocale, avec états loading/empty/error et sélection de langue.
- Suivi GPS en temps réel pendant que l'app est ouverte : le point
  utilisateur, les distances et l'ordre des POI se mettent à jour, et le
  catalogue POI se renouvelle quand l'utilisateur entre dans une nouvelle
  zone.
- Synthèse vocale on-device via `AVSpeechSynthesizer`, résolution de voix
  par langue, respect des réglages iOS de contenu énoncé, pause/reprise/arrêt
  et mode audio background déclaré.
- Provider CoreLocation isolé dans `WGLocation`, avec gestion des refus de
  permission.
- CI étendue pour vérifier à la fois le package SPM et le build du target
  App généré par XcodeGen.
- Expérience SwiftUI modernisée : écran d'exploration visuel,
  Autour/Favoris/Historique, cartes POI avec images et badges, détail plus
  immersif, sources visibles, contrôles audio plus clairs.
- Cache de contenu en mémoire par POI/langue, favoris et historique
  persistés en local, rayon de recherche réglable et mode de lecture
  Flash/Complet.
- Interface localisée dynamiquement à partir de la langue choisie dans
  l'app, avec initialisation depuis la langue de l'iPhone et fallback anglais.
- Bouton `S'y rendre` dans le détail POI, ouvrant Apple Plans avec un
  itinéraire piéton préconfiguré vers le lieu sélectionné.
- Construction de balades personnalisées : bouton `Ajouter à la balade`
  dans chaque fiche POI, circuit affiché sur la carte, distances et temps
  issus de MapKit, départ forcé depuis la vraie géolocalisation quand elle
  est connue, et ouverture d'itinéraires à pied/vélo/voiture/transports via
  Apple Plans.
- Carte interactive depuis l'écran principal, avec bascule Liste/Carte,
  marqueurs limités aux POI prioritaires pour rester lisible, sélection d'un
  POI par tap, direction utilisateur affichée et accès au détail depuis une
  fiche compacte.
- Filtre de qualité sur l'écran principal : tous les POI, seulement ceux
  avec Wikipedia, ou seulement les fiches complètes avec Wikipedia + photo +
  catégorie.
- Cache offline persistant des derniers résultats POI par langue/rayon et
  des contenus déjà ouverts, avec bannière explicite quand l'app affiche des
  données locales après une erreur réseau.
- Notifications locales intelligentes, opt-in, déclenchées seulement quand
  un POI est à moins de 180 m et protégées par un cooldown pour éviter le
  spam.
- Infos OpenStreetMap enrichies avec données structurées utiles
  (`website`, horaires, opérateur, téléphone, adresse quand disponibles)
  sans scraping de sites tiers.
- Bouton `Infos officielles` dans le détail POI : charge une fiche externe
  depuis le site officiel résolu par Wikidata/OSM, même quand une fiche
  Wikipedia existe, avec résumé borné, source, site officiel, adresse,
  horaires, prix et téléphone quand disponibles ; si le POI n'a pas de site
  exploitable, fallback vers les offices/centres touristiques institutionnels
  proches déclarés dans OpenStreetMap.
- Traduction automatique des infos officielles dans la langue choisie dans
  l'app via Apple Translation sur iOS 18+ ; le texte source reste affiché en
  fallback sur les versions antérieures ou en cas d'échec.
- Lien `Rechercher en ligne` dans la fiche `Infos officielles` quand aucune
  des sources structurées (Wikidata, OSM, offices de tourisme à proximité)
  n'a rien trouvé : ouvre le moteur de recherche du téléphone avec le nom
  du POI, sans jamais présenter ce résultat comme une source extraite.

### Fixed

- La recherche de destination composite gardait le résultat Apple (sans
  identifiant Wikidata) plutôt que le résultat Wikidata enrichi quand les
  deux moteurs trouvaient le même lieu — l'ordre des chercheurs dans
  `CompositePlaceSearcher` faisait perdre l'identifiant Wikidata pour la
  plupart des lieux connus (musées, monuments), empêchant l'app de charger
  leur contenu Wikipedia après une recherche.
- La recherche Wikidata de lieux ne décodait jamais la langue de la
  correspondance (`match.language` mal placé dans le décodage), donc les
  libellés retournés étaient toujours en anglais quel que soit la langue
  de recherche ayant réellement trouvé le résultat.

### Changed

- Interface principale allégée : les contrôles secondaires (vue, rayon,
  filtre POI, alertes) sont regroupés dans des actions compactes afin de
  laisser les résultats apparaître plus vite à l'écran.
- La langue est gérée depuis le menu de configuration ; la météo et le
  réglage d'énergie ne sont plus visibles dans l'expérience principale.
- Carte rendue plus lisible : moins de marqueurs affichés par défaut, pas
  de fiche POI présélectionnée au chargement, et compteur visible seulement
  quand une partie des résultats est masquée.
- Fiche POI durcie avec une mise en page unique et bornée pour tous les
  contenus : image, titre, boutons, sources et chapitres ne peuvent plus
  élargir la page au-delà de l'écran iPhone.
- Lecture vocale déplacée sur une icône au début de chaque chapitre, avec
  pause/reprise sur le chapitre actif, au lieu d'un bouton texte placé en
  bas du chapitre ouvert.
- Les circuits de balade sont calculés en tronçons séquentiels testés
  (`position → POI 1 → POI 2 → ...`) pour que la carte interne prenne en
  compte tous les points choisis. Les boutons Apple Plans ouvrent la
  prochaine étape, et chaque tronçon de la balade dispose maintenant de son
  bouton transport dédié, car l'API Plans ne garantit pas un guidage
  multi-stop complet depuis l'app.

### Removed

- Ancien fallback `Sources officielles` par URL de recherche configurée
  (`WG_OFFICIAL_SEARCH_URL_TEMPLATE`), remplacé par la fiche officielle
  intégrée.
- Recherche de destination via Wikidata `EntitySearch`
  (`POIProviding.searchPOI`), remplacée par la recherche `MKLocalSearch`
  ci-dessus — elle ne trouvait que les lieux ayant une fiche Wikidata,
  ratant la plupart des adresses et commerces ordinaires.
- Le backend Python/FastAPI (Phases 0-3 : POI, Sources, Knowledge,
  Validation, Content, Postgres/PostGIS), `infra/docker-compose.yml`,
  `specs/001-006` et `.env.example` — supprimés
  ([ADR 0012](docs/adr/0012-ios-only-no-backend.md)). WorldGuide devient
  une app iOS 100% autonome : elle interroge Wikidata/Wikipedia/OSM
  directement et fait elle-même le tri/l'assemblage/le résumé, sans
  infrastructure tierce à opérer. ADR 0002 et 0009 marquées supersédées ;
  `.specify/memory/constitution.md` amendée en conséquence.

### Historical

- Scaffolding architectural initial de WorldGuide, sans logique métier :
  - Backend Python/FastAPI en architecture hexagonale (`domain`/`application`/
    `infrastructure`/`interface`) pour les sept modules POI, Sources,
    Knowledge, Validation, Content, LLM, TTS, avec tests placeholder par
    module (fakes conformes aux `Protocol`).
  - Package SPM iOS local (`WGCore`, `WGConfiguration`, `WGPOI`, `WGContent`,
    `WGPlayback`) avec tests XCTest par module.
  - Gouvernance documentaire : Spec Kit (`specs/`, `.specify/`), 7 ADR
    (`docs/adr/`), `AGENTS.md`, CI (`.github/workflows/ci.yml`).
  - Configuration exclusivement par variables d'environnement
    (`.env.example`, `Secrets.xcconfig.example`), aucun secret commité.
  - `infra/docker-compose.yml` pour PostgreSQL/PostGIS et Redis en local.
