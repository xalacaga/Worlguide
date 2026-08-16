# Roadmap

> [ADR 0012](docs/adr/0012-ios-only-no-backend.md) (2026-08-14) : WorldGuide
> devient une app iOS 100% autonome, sans backend. Le backend
> Python/FastAPI des phases 0-3 ci-dessous a été supprimé ; les phases
> suivantes sont redéfinies pour reprendre leurs objectifs côté Swift,
> on-device.

## Phase 0 — Architecture iOS (fait, redéfinie)

- Modules SPM iOS (`WGCore`, `WGConfiguration`, `WGPOI`, `WGContent`,
  `WGPlayback`), chacun exposant un `Protocol` de port
  (`POIProviding`, `ContentProviding`, `AudioPlaying`,
  `ConfigurationProviding`) — pattern Provider ([ADR 0003](docs/adr/0003-provider-pattern-and-ios-module-scope.md))
  conçu justement pour recevoir un adapter réel sans toucher l'interface.
- Gouvernance : Spec Kit (`specs/`, `.specify/`), ADR (`docs/adr/`),
  `AGENTS.md`, CI (`ios` seul désormais).
- Le squelette backend hexagonal (`domain`/`application`/`infrastructure`/
  `interface` pour POI, Sources, Knowledge, Validation, Content, LLM, TTS)
  a existé de la Phase 0 à la Phase 3, puis a été **supprimé** avec `infra/`
  et `specs/001-006` ([ADR 0012](docs/adr/0012-ios-only-no-backend.md)) —
  sauvegarde locale conservée hors dépôt (voir l'ADR).

## Phase 1 — Découverte des POI (fait)

- Adapter `POIProviding` réel : requête SPARQL Wikidata directement depuis
  Swift, avec filtre géospatial (`wikibase:around` ou équivalent) pour
  "POI à proximité" — reprend l'objectif des anciennes `specs/001` et
  `specs/002` (recherche géospatiale, import Wikidata avec `wikidata_qid`
  porté par chaque POI), sans backend ni PostGIS.
- Réalisé dans [specs/007](specs/007-poi-discovery-wikidata/) avec tests
  unitaires fake-based et test réseau live opt-in.

## Phase 2 — Sources & assemblage (fait)

- Récupération directe depuis l'app : sitelinks Wikipedia (une source par
  édition linguistique) et tags OpenStreetMap pertinents via Overpass —
  reprend l'objectif des anciennes `specs/003` et `specs/005`.
- Tri/validation léger avant assemblage (source présente, licence) —
  équivalent client de ce que faisait la Knowledge Package côté backend
  ([ADR 0004](docs/adr/0004-knowledge-package-provenance.md) reste la
  référence de principe), sans persistance serveur : le résultat vit en
  mémoire ou dans un cache local le temps de la session.
- Réalisé dans [specs/008](specs/008-poi-sources-wikipedia-osm/).

## Phase 3 — Contenu par extraction + thèmes (fait)

- [ADR 0010](docs/adr/0010-content-via-extraction-not-llm-generation.md)
  reste la décision de fond : le contenu est assemblé par extraction
  directe des sources, pas généré par un LLM.
- `ContentProviding` réel côté `WGAdapters` : sitelink Wikipedia,
  extraction d'article, résolution de coordonnées, tags Overpass, ligne OSM,
  provenance et fallback partiel si OSM/coordonnées échouent.
- [ADR 0015](docs/adr/0015-content-package-carries-sections.md) a remplacé
  le bloc de texte plat par des sections thématiques : l'utilisateur choisit
  quoi lire/écouter. Réalisé dans
  [specs/009](specs/009-poi-content-extraction/) puis
  [specs/016](specs/016-sectioned-content-and-images/).

## Phase 4 — TTS multilingue (fait)

- [ADR 0011](docs/adr/0011-tts-on-device-not-backend-vendor.md) : pas de
  vendor TTS backend (coût, clé API, lock-in) — la synthèse vocale se fait
  **on-device** dans l'app iOS via `AVSpeechSynthesizer`, gratuite et déjà
  disponible dans `AVFoundation`. Elle utilise les voix de synthèse installées
  sur iOS et respecte les réglages `Contenu énoncé`, mais n'accède pas à la
  voix Siri assistant elle-même. Cette
  décision a en fait précédé et annoncé le pivot plus large de
  [ADR 0012](docs/adr/0012-ios-only-no-backend.md).
- Implémentation réelle dans [specs/010](specs/010-tts-avspeechsynthesizer/) :
  `AVSpeechSynthesizerAudioPlayer`, résolution de voix multilingue,
  pause/reprise/arrêt. Le mode audio background est déclaré et câblé dans
  [specs/014](specs/014-background-audio-playback/).

## Phase 5 — App iOS (premier flux fait)

- Target App Xcode généré via XcodeGen
  ([specs/011](specs/011-ios-app-target/)), CoreLocation
  ([specs/012](specs/012-corelocation-provider/)), écran POI proche
  ([specs/013](specs/013-nearby-poi-ui/)) et tests du ViewModel
  ([specs/015](specs/015-app-target-test-coverage/)).
- Flux actuellement livré : localisation → recherche POI → détail →
  thèmes Wikipedia/OSM → image fallback → favoris/historique → lecture
  Flash/Complet → lecture vocale par chapitre → itinéraires dans Apple
  Plans → balade personnalisée à suivre sur la carte.
- Les recherches POI sont optimisées côté Wikidata : tri par distance,
  regroupement des catégories et limite de résultats adaptée au rayon
  (notamment pour 3 km).
- La recherche textuelle de destination est séparée de la découverte
  proche : elle combine Apple `MKLocalSearch` pour les lieux ordinaires et
  un `WikidataPlaceSearcher` pour les POI nommés/historiques, lance les
  recherches en parallèle, cache les requêtes répétées, puis garde les
  distances depuis la position réelle quand elle est connue. Une ville ou
  un village déclenche une exploration élargie et remonte jusqu'à 10 POI
  intéressants autour du lieu.
- Les POI peuvent être filtrés dans l'app : tous, avec Wikipedia, ou fiches
  complètes avec Wikipedia + photo + catégorie.
- L'expérience SwiftUI a été modernisée dans
  [specs/017](specs/017-modern-experience-cache-favorites/) avec écran
  visuel, cartes POI, contrôles principaux allégés, réglages secondaires
  regroupés dans un menu compact, rayon réglable, favoris, historique,
  cache session, score qualité, sources visibles et interface alignée sur
  la langue choisie ou la langue de l'iPhone. Le détail POI propose aussi
  un bouton `S'y rendre` qui ouvre un trajet piéton dans Apple Plans.
- [specs/018](specs/018-map-offline-notifications/) ajoute la carte
  interactive lisible avec marqueurs limités et fiche affichée seulement
  après sélection, le suivi de la direction utilisateur, le cache offline
  persistant des résultats/contenus déjà vus et les notifications locales
  intelligentes opt-in.
- [specs/019](specs/019-official-source-search/) ajoute des infos OSM
  structurées plus riches et un bouton `Infos officielles` qui charge une
  fiche institutionnelle externe dans l'app, même si Wikipedia existe, avec
  site officiel, adresse, horaires, prix/téléphone quand disponibles et
  traduction automatique iOS 18+ ; si le POI n'a pas de site exploitable,
  l'app tente les offices/centres touristiques institutionnels proches via
  OpenStreetMap.
- [specs/021](specs/021-field-test-realtime-search-walk-polish/) documente
  l'itération de test réel sur iPhone : suivi GPS continu pendant que
  l'app est ouverte, renouvellement des POI après déplacement, recherche
  optimisée Apple/Wikidata, retour immédiat à `Ma position`, balades
  personnalisées démarrant toujours du GPS réel, transports via Apple Plans
  et fiche détail à largeur strictement contrainte pour toutes les fiches.
- Reste à durcir côté produit : meilleure UX des erreurs réseau publiques,
  parcours audio automatique, meilleure présentation des sources non
  Wikipedia, tests visuels automatisés des fiches détail longues, et
  vérification humaine du comportement audio en arrière-plan sur appareil.

## Phase 6 — Distribution (à faire)

- Pas de serveur à déployer ([ADR 0012](docs/adr/0012-ios-only-no-backend.md)
  supersède [ADR 0009](docs/adr/0009-managed-services-no-self-operated-infrastructure.md)
  sur ce point). Publication App Store : build release, signing,
  TestFlight — détails à préciser le moment venu.

## Prochaines priorités

- Étendre/maintenir la CI pour couvrir le package SPM et le target App iOS.
- Améliorer les états d'erreur et de retry quand un service public est lent
  ou indisponible.
- Améliorer les infos officielles : meilleure extraction des horaires/prix
  par pays, meilleure hiérarchisation des sources institutionnelles quand
  plusieurs offices/centres touristiques sont proches, et cache local dédié
  aux fiches externes.
- Ajouter un mode parcours audio automatique.
- Préparer la distribution : bundle id définitif, signing, icône finale,
  privacy strings, TestFlight.

## Continu, à chaque phase

- ADR ajouté si une décision structurante change.
- `specs/<NNN>` tenu à jour (spec/plan/tasks) ; numérotation reprend à
  `007` (jamais réutilisée, même après suppression de `001-006`).
- `/graphify` relancé pour refléter la structure réelle.
- CI verte avant fusion.
