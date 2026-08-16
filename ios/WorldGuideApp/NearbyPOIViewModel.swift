import Foundation
import WGCore
import WGPOI
import WGContent
import WGPlayback
import WGLocation
import WGWeather

/// Orchestrates location → nearby POIs → content → playback (specs/013).
/// Depends only on the four existing `Protocol` ports — never on a
/// concrete `WGAdapters`/`WGLocation` type directly.
@MainActor
final class NearbyPOIViewModel: ObservableObject {
    enum ListMode: String, CaseIterable, Identifiable {
        case nearby
        case smartWalk
        case journal
        case favorites
        case history

        var id: String { rawValue }

        var title: String {
            AppStrings(languageCode: Locale.current.language.languageCode?.identifier ?? "en").listModeTitle(self)
        }
    }

    enum ReadingMode: String, CaseIterable, Identifiable {
        case short
        case complete

        var id: String { rawValue }

        var title: String {
            AppStrings(languageCode: Locale.current.language.languageCode?.identifier ?? "en").readingModeTitle(self)
        }
    }

    enum SpeechRate: String, CaseIterable, Identifiable {
        case slow
        case normal
        case fast

        var id: String { rawValue }

        var multiplier: Float {
            switch self {
            case .slow: return 0.78
            case .normal: return 0.92
            case .fast: return 1.08
            }
        }
    }

    enum GuideMode: String, CaseIterable, Identifiable {
        case off
        case prompt
        case autoPlay

        var id: String { rawValue }
    }

    enum POIFilter: String, CaseIterable, Identifiable {
        case all
        case mustSee
        case monuments
        case museums
        case nature
        case food
        case wikipedia
        case complete

        var id: String { rawValue }
    }

    struct RadiusOption: Identifiable, Equatable {
        let meters: Double
        let title: String
        var id: Double { meters }
    }

    struct WalkDurationOption: Identifiable, Equatable {
        let minutes: Int
        let title: String
        var id: Int { minutes }
    }

    enum WalkDesire: String, CaseIterable, Identifiable {
        case balanced
        case monuments
        case streetArt
        case unusual
        case architecture
        case darkHistory
        case photoSpots

        var id: String { rawValue }

        var keywords: [String] {
            switch self {
            case .balanced:
                return []
            case .monuments:
                return ["monument", "statue", "memorial", "palace", "castle", "church", "cathedral", "monument", "statue", "mémorial", "palais", "château", "église", "cathédrale"]
            case .streetArt:
                return ["street art", "mural", "graffiti", "fresco", "art urbain", "murale", "fresque"]
            case .unusual:
                return ["curiosity", "unusual", "odd", "hidden", "secret", "insolite", "curiosité", "caché", "secret"]
            case .architecture:
                return ["architecture", "building", "house", "facade", "bridge", "tower", "immeuble", "maison", "façade", "pont", "tour"]
            case .darkHistory:
                return ["cemetery", "prison", "battle", "war", "memorial", "execution", "dark", "cimetière", "prison", "bataille", "guerre", "mémorial"]
            case .photoSpots:
                return ["view", "panorama", "photo", "bridge", "tower", "garden", "vue", "belvédère", "pont", "tour", "jardin"]
            }
        }
    }

    enum WeatherMood: String, CaseIterable, Identifiable {
        case clear
        case rain
        case hot

        var id: String { rawValue }
    }

    enum EnergyLevel: String, CaseIterable, Identifiable {
        case fresh
        case normal
        case low

        var id: String { rawValue }
    }

    struct WalkContext: Equatable {
        let weather: WeatherMood
        let energy: EnergyLevel
        let isEvening: Bool
        let isLowLight: Bool
        let isWeekend: Bool
        let likelyClosed: Bool
    }

    private enum CachedContent {
        case empty
        case loaded(ContentPackage)
    }

    enum LoadState {
        case idle
        case loadingLocation
        case loadingPOIs
        case loaded([POI])
        case failed(String)
    }

    enum ContentState {
        case loading
        case loaded(ContentPackage)
        case empty
        case failed(String)
    }

    enum ExternalContentState {
        case idle
        case loading
        case loaded(ExternalContentPackage)
        case empty
        case failed(String)
    }

    enum WeatherState: Equatable {
        case manual
        case loading
        case live(WeatherSnapshot)
        case failed(String)
    }

    struct SupportedLanguage: Identifiable, Equatable {
        let code: String
        let displayName: String
        var id: String { code }
    }

    /// A short, curated list of Wikipedia language editions — not
    /// exhaustive (Wikipedia has 300+), just the common ones worth a
    /// picker entry. `Locale.current` still picks the initial default;
    /// this list is only for the user's explicit override.
    static let supportedLanguages: [SupportedLanguage] = [
        SupportedLanguage(code: "fr", displayName: "Français"),
        SupportedLanguage(code: "en", displayName: "English"),
        SupportedLanguage(code: "es", displayName: "Español"),
        SupportedLanguage(code: "de", displayName: "Deutsch"),
        SupportedLanguage(code: "it", displayName: "Italiano"),
        SupportedLanguage(code: "pt", displayName: "Português"),
        SupportedLanguage(code: "nl", displayName: "Nederlands"),
        SupportedLanguage(code: "ja", displayName: "日本語"),
        SupportedLanguage(code: "zh-hans", displayName: "中文（简体）"),
        SupportedLanguage(code: "ar", displayName: "العربية"),
    ]

    static let radiusOptions: [RadiusOption] = [
        RadiusOption(meters: 250, title: "250 m"),
        RadiusOption(meters: 500, title: "500 m"),
        RadiusOption(meters: 1000, title: "1 km"),
        RadiusOption(meters: 3000, title: "3 km"),
    ]

    static let walkDurationOptions: [WalkDurationOption] = [
        WalkDurationOption(minutes: 30, title: "30 min"),
        WalkDurationOption(minutes: 60, title: "60 min"),
        WalkDurationOption(minutes: 90, title: "90 min"),
    ]

    enum PlaybackState: Equatable {
        case stopped
        case playing
        case paused
    }

    private enum CachedExternalContent {
        case loaded(ExternalContentPackage)
        case empty
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var contentState: ContentState = .loading
    @Published private(set) var externalContentState: ExternalContentState = .idle
    @Published private(set) var weatherState: WeatherState = .manual
    @Published private(set) var playbackState: PlaybackState = .stopped
    /// `nil` until the user picks a theme from the loaded package's
    /// sections (docs/adr/0015) — the app never reads a whole
    /// `ContentPackage` start to finish.
    @Published private(set) var selectedSectionID: String?
    /// Set once per `loadNearbyPOIs()` call — lets the view show each
    /// POI's distance without re-deriving it from raw provider calls.
    @Published private(set) var userCoordinate: Coordinate?
    @Published private(set) var favoritePOIs: [POI] = []
    @Published private(set) var recentPOIs: [POI] = []
    @Published private(set) var travelNotes: [String: String] = [:]
    @Published private(set) var offlinePacks: [OfflineAreaPack] = []
    @Published private(set) var offlinePackStatusText: String?
    @Published private(set) var autoGuideSuggestion: AutoGuideSuggestion?
    @Published private(set) var offlineNotice: String?
    @Published private(set) var placeSearchResults: [PlaceResult] = []
    @Published private(set) var placeSearchText: String?
    @Published private(set) var isSearchingPlaces = false
    @Published private(set) var placeSearchError: String?
    /// Set by `jumpToPlace(_:)` when the user picks a search result — while
    /// non-nil, `loadNearbyPOIs` explores around this coordinate instead of
    /// the device's real location (docs/adr/0016). `nil` means "use my
    /// real location," the default.
    @Published private(set) var browsingCoordinate: Coordinate?
    @Published private(set) var browsingPlaceName: String?
    @Published private(set) var browsingPlacePOI: POI?
    @Published private(set) var browsingPlaceIsAdministrative = false
    @Published var listMode: ListMode = .nearby
    @Published var readingMode: ReadingMode = .short
    @Published var speechRate: SpeechRate = .normal
    @Published var guideMode: GuideMode = .prompt
    @Published var poiFilter: POIFilter = .all
    @Published var radiusMeters: Double
    @Published private(set) var nearbyAlertsEnabled: Bool
    @Published var smartWalkMinutes: Int = 60
    @Published var walkDesire: WalkDesire = .balanced
    @Published var weatherMood: WeatherMood = .clear
    @Published var energyLevel: EnergyLevel = .normal
    /// User-selectable — defaults to the device's language but is not
    /// fixed to it, so content can be read in a different source edition
    /// (e.g. a French speaker deliberately reading English Wikipedia).
    @Published var language: String

    var strings: AppStrings {
        AppStrings(languageCode: language)
    }

    private let locationProvider: LocationProviding
    private let poiProvider: POIProviding
    private let placeSearcher: PlaceSearching
    private let contentProvider: ContentProviding
    private let externalContentProvider: ExternalContentProviding?
    private let weatherProvider: WeatherProviding?
    private let audioPlayer: AudioPlaying
    private let notificationScheduler: NearbyNotificationScheduling
    private let userDefaults: UserDefaults
    private var contentCache: [String: CachedContent] = [:]
    private var externalContentCache: [String: CachedExternalContent] = [:]
    private var placeSearchCache: [String: [PlaceResult]] = [:]
    private var lastNearbyPOICenterCoordinate: Coordinate?
    private var isRefreshingPOIsForLiveLocation = false
    private var announcedAutoGuidePOIIDs: Set<String> = []
    private var isAutoPlayingGuide = false

    private static let favoritesKey = "worldguide.favoritePOIs.v1"
    private static let historyKey = "worldguide.recentPOIs.v1"
    private static let travelNotesKey = "worldguide.travelNotes.v1"
    private static let offlinePacksKey = "worldguide.offlinePacks.v1"
    private static let nearbyCacheKey = "worldguide.cachedNearbyPOIs.v1"
    private static let contentCacheKey = "worldguide.cachedContentPackages.v1"
    private static let nearbyAlertsKey = "worldguide.nearbyAlerts.enabled.v1"
    private static let searchedPlacePOIPrefix = "place-search:"
    private static let administrativePlacePOIRadiusMeters = 3_000.0
    private static let administrativePlacePOILimit = 10
    private static let livePOIRefreshDistanceMeters = 75.0
    private static let guideDistanceMeters = 140.0

    init(
        locationProvider: LocationProviding,
        poiProvider: POIProviding,
        placeSearcher: PlaceSearching = MKLocalSearchPlaceSearcher(),
        contentProvider: ContentProviding,
        externalContentProvider: ExternalContentProviding? = nil,
        weatherProvider: WeatherProviding? = nil,
        audioPlayer: AudioPlaying,
        notificationScheduler: NearbyNotificationScheduling? = nil,
        language: String? = nil,
        radiusMeters: Double = 500,
        userDefaults: UserDefaults = .standard
    ) {
        self.locationProvider = locationProvider
        self.poiProvider = poiProvider
        self.placeSearcher = placeSearcher
        self.contentProvider = contentProvider
        self.externalContentProvider = externalContentProvider
        self.weatherProvider = weatherProvider
        self.audioPlayer = audioPlayer
        self.notificationScheduler = notificationScheduler ?? NoopNearbyNotificationScheduler()
        self.language = Self.supportedLanguageCode(for: language ?? Self.deviceLanguageCode())
        self.radiusMeters = radiusMeters
        self.userDefaults = userDefaults
        self.nearbyAlertsEnabled = userDefaults.bool(forKey: Self.nearbyAlertsKey)
        self.favoritePOIs = Self.loadPOIs(from: userDefaults, key: Self.favoritesKey)
        self.recentPOIs = Self.loadPOIs(from: userDefaults, key: Self.historyKey)
        self.travelNotes = Self.loadStringDictionary(from: userDefaults, key: Self.travelNotesKey)
        self.offlinePacks = Self.loadOfflinePacks(from: userDefaults)
    }

    func loadNearbyPOIs(radiusMeters: Double? = nil, preferLastKnownUserLocation: Bool = false) async {
        let radius = radiusMeters ?? self.radiusMeters
        state = .loadingLocation
        do {
            let coordinate: Coordinate
            if let browsingCoordinate {
                coordinate = browsingCoordinate
            } else if preferLastKnownUserLocation, let userCoordinate {
                coordinate = userCoordinate
            } else {
                coordinate = try await locationProvider.currentLocation()
                userCoordinate = coordinate
            }
            state = .loadingPOIs
            let searchRadius = browsingPlaceIsAdministrative ? max(radius, Self.administrativePlacePOIRadiusMeters) : radius
            let pois = try await poiProvider.nearbyPOI(around: coordinate, radiusMeters: searchRadius, language: language)
            let sortedPOIs = displayedPOIs(pois, around: coordinate)
            state = .loaded(sortedPOIs)
            await updateAutoGuideSuggestion(from: sortedPOIs, userCoordinate: coordinate)
            offlineNotice = nil
            lastNearbyPOICenterCoordinate = browsingCoordinate == nil ? coordinate : nil
            // A searched/browsed location isn't where the user actually
            // is — writing it to the real-location offline cache or
            // triggering "you're nearby" alerts for it would both be
            // wrong (docs/adr/0016).
            if browsingCoordinate == nil {
                persistCachedNearbyPOIs(sortedPOIs)
                if nearbyAlertsEnabled {
                    await notificationScheduler.notifyNearbyPOIIfNeeded(pois: sortedPOIs, userCoordinate: coordinate, strings: strings)
                }
            }
            await refreshWeatherContext(around: coordinate)
        } catch WGError.permissionDenied {
            state = .failed(strings.locationDenied)
        } catch {
            if let browsingPlacePOI {
                state = .loaded([browsingPlacePOI])
                return
            }
            if browsingCoordinate == nil, let cachedPOIs = loadCachedNearbyPOIs() {
                offlineNotice = strings.offlineResults
                state = .loaded(cachedPOIs)
                if let userCoordinate {
                    await updateAutoGuideSuggestion(from: cachedPOIs, userCoordinate: userCoordinate)
                }
            } else {
                state = .failed(strings.nearbyFailure)
            }
        }
    }

    func observeLiveLocationUpdates() async {
        do {
            for try await coordinate in locationProvider.locationUpdates() {
                userCoordinate = coordinate
                guard browsingCoordinate == nil else { continue }
                resortLoadedPOIs(from: coordinate)
                if case .loaded(let pois) = state {
                    await updateAutoGuideSuggestion(from: pois, userCoordinate: coordinate)
                }
                await refreshNearbyPOIsForLiveLocationIfNeeded(around: coordinate)
            }
        } catch WGError.permissionDenied {
            if userCoordinate == nil {
                state = .failed(strings.locationDenied)
            }
        } catch {
            if userCoordinate == nil {
                state = .failed(strings.nearbyFailure)
            }
        }
    }

    func setRadius(_ meters: Double) async {
        radiusMeters = meters
        clearPlaceSearch()
        await loadNearbyPOIs(radiusMeters: meters)
    }

    /// Recenters exploration on a place found via `searchPlaces` — the
    /// existing nearby-POI pipeline then runs around it unchanged
    /// (docs/adr/0016).
    func jumpToPlace(_ place: PlaceResult) async {
        browsingCoordinate = place.coordinate
        browsingPlaceName = place.name
        browsingPlacePOI = Self.poi(from: place)
        browsingPlaceIsAdministrative = place.isAdministrativePlace
        lastNearbyPOICenterCoordinate = nil
        if userCoordinate == nil {
            userCoordinate = try? await locationProvider.currentLocation()
        }
        clearPlaceSearch()
        await loadNearbyPOIs()
    }

    /// Leaves a browsed/searched location and returns to the device's real
    /// GPS fix.
    func returnToMyLocation() async {
        browsingCoordinate = nil
        browsingPlaceName = nil
        browsingPlacePOI = nil
        browsingPlaceIsAdministrative = false
        await loadNearbyPOIs(preferLastKnownUserLocation: true)
    }

    var walkContext: WalkContext {
        SmartWalkPlanner.context(for: Date(), weather: weatherMood, energy: energyLevel, daylightOverride: liveDaylightOverride)
    }

    var distanceReferenceCoordinate: Coordinate? {
        userCoordinate ?? browsingCoordinate
    }

    var explorationCoordinate: Coordinate? {
        browsingCoordinate ?? userCoordinate
    }

    var weatherStatusText: String {
        switch weatherState {
        case .manual:
            return strings.manualWeather
        case .loading:
            return strings.loadingWeather
        case .live(let snapshot):
            return strings.liveWeather(weatherDescription(for: snapshot))
        case .failed(let message):
            return message
        }
    }

    func refreshWeatherContext() async {
        guard let userCoordinate else {
            do {
                let coordinate = try await locationProvider.currentLocation()
                self.userCoordinate = coordinate
                await refreshWeatherContext(around: coordinate)
            } catch {
                weatherState = .failed(strings.weatherFailure)
            }
            return
        }
        await refreshWeatherContext(around: userCoordinate)
    }

    func smartWalkPlan(from pois: [POI]) -> SmartWalkPlan {
        SmartWalkPlanner.plan(
            from: filteredPOIs(pois),
            userCoordinate: userCoordinate ?? explorationCoordinate,
            durationMinutes: smartWalkMinutes,
            desire: walkDesire,
            context: walkContext,
            favoriteIDs: Set(favoritePOIs.map(\.id))
        )
    }

    var travelJournalSummary: TravelJournalSummary {
        TravelJournalBuilder.summary(from: recentPOIs, favoritePOIs: favoritePOIs, notes: travelNotes)
    }

    var travelJournalExportText: String {
        TravelJournalBuilder.exportText(summary: travelJournalSummary, strings: strings)
    }

    func clearHistory() {
        recentPOIs = []
        userDefaults.removeObject(forKey: Self.historyKey)
    }

    func note(for poi: POI) -> String {
        travelNotes[poi.id] ?? ""
    }

    func setNote(_ note: String, for poi: POI) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            travelNotes.removeValue(forKey: poi.id)
        } else {
            travelNotes[poi.id] = trimmed
        }
        persist(travelNotes, key: Self.travelNotesKey)
    }

    func dismissAutoGuideSuggestion() {
        autoGuideSuggestion = nil
    }

    func playAutoGuideSuggestion() async {
        guard let poi = autoGuideSuggestion?.poi else { return }
        await playAutoGuide(for: poi)
    }

    func downloadOfflinePackForCurrentArea() async {
        guard case .loaded(let pois) = state else {
            offlinePackStatusText = strings.offlinePackNeedsPOIs
            return
        }
        let packPOIs = Array(pois.prefix(20))
        guard packPOIs.isEmpty == false else {
            offlinePackStatusText = strings.offlinePackNeedsPOIs
            return
        }

        persistCachedNearbyPOIs(packPOIs)
        var contentCount = 0
        for poi in packPOIs.prefix(12) where Self.isSearchedPlacePOI(poi) == false {
            let cacheKey = "\(poi.id)|\(language)"
            if loadCachedContent(cacheKey: cacheKey) != nil {
                contentCount += 1
                continue
            }
            if let content = try? await contentProvider.content(forPOI: poi.id, language: language) {
                contentCache[cacheKey] = .loaded(content)
                persistCachedContent(content, cacheKey: cacheKey)
                contentCount += 1
            }
        }

        let pack = OfflineAreaPack(
            id: "\(language)|\(Int(radiusMeters.rounded()))|\(Int(Date().timeIntervalSince1970))",
            title: browsingPlaceName ?? strings.aroundYou,
            createdAt: Date(),
            poiCount: packPOIs.count,
            contentCount: contentCount
        )
        offlinePacks.removeAll { $0.title == pack.title }
        offlinePacks.insert(pack, at: 0)
        if offlinePacks.count > 8 {
            offlinePacks = Array(offlinePacks.prefix(8))
        }
        persistOfflinePacks()
        offlinePackStatusText = strings.offlinePackSaved(pack.title, poiCount: pack.poiCount, contentCount: pack.contentCount)
    }

    private func refreshWeatherContext(around coordinate: Coordinate) async {
        guard let weatherProvider else {
            weatherState = .manual
            return
        }
        weatherState = .loading
        do {
            let snapshot = try await weatherProvider.currentWeather(around: coordinate)
            if snapshot.suggestsRain {
                weatherMood = .rain
            } else if snapshot.suggestsHeat {
                weatherMood = .hot
            } else {
                weatherMood = .clear
            }
            weatherState = .live(snapshot)
        } catch {
            weatherState = .failed(strings.weatherFailure)
        }
    }

    private var liveDaylightOverride: Bool? {
        guard case .live(let snapshot) = weatherState else { return nil }
        return snapshot.isDaylight
    }

    private func weatherDescription(for snapshot: WeatherSnapshot) -> String {
        var pieces: [String] = []
        if let temperature = snapshot.temperatureCelsius {
            pieces.append("\(Int(temperature.rounded())) °C")
        }
        if snapshot.suggestsRain {
            pieces.append(strings.weatherMoodTitle(.rain))
        } else if snapshot.suggestsHeat {
            pieces.append(strings.weatherMoodTitle(.hot))
        } else {
            pieces.append(strings.weatherMoodTitle(.clear))
        }
        return pieces.joined(separator: " · ")
    }

    var isPlaceSearchActive: Bool {
        placeSearchText != nil
    }

    func clearPlaceSearch() {
        placeSearchResults = []
        placeSearchText = nil
        isSearchingPlaces = false
        placeSearchError = nil
    }

    /// Finds any place worldwide (address, business, landmark — not only
    /// Wikidata-notable ones) via `PlaceSearching`, biased toward the
    /// current exploration center. Picking a result recenters exploration
    /// there via `jumpToPlace(_:)` — this does not itself move anything
    /// (docs/adr/0016).
    func searchPlaces(matching query: String) async {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedQuery.count >= 2 else {
            clearPlaceSearch()
            return
        }

        placeSearchText = normalizedQuery
        isSearchingPlaces = true
        placeSearchError = nil
        let cacheKey = normalizedQuery.lowercased()
        if let cachedPlaces = placeSearchCache[cacheKey] {
            placeSearchResults = cachedPlaces
            isSearchingPlaces = false
            return
        }

        do {
            let places = try await placeSearcher.searchPlaces(matching: normalizedQuery, near: userCoordinate)
            guard placeSearchText == normalizedQuery else { return }
            placeSearchCache[cacheKey] = places
            placeSearchResults = places
            isSearchingPlaces = false
        } catch {
            guard placeSearchText == normalizedQuery else { return }
            placeSearchError = strings.placeSearchFailure
            placeSearchResults = []
            isSearchingPlaces = false
        }
    }

    func select(_ poi: POI) async {
        // Switching POIs must not leave the previous one's audio playing
        // under a UI that now shows a fresh "Écouter" button for the new
        // one.
        if playbackState != .stopped {
            await audioPlayer.stop()
            playbackState = .stopped
        }
        selectedSectionID = nil
        externalContentState = .idle
        contentState = .loading
        addToHistory(poi)
        guard Self.isSearchedPlacePOI(poi) == false else {
            contentState = .empty
            return
        }
        let cacheKey = "\(poi.id)|\(language)"
        if let cached = contentCache[cacheKey] {
            switch cached {
            case .loaded(let content):
                contentState = .loaded(content)
            case .empty:
                contentState = .empty
            }
            return
        }
        if let persistedContent = loadCachedContent(cacheKey: cacheKey) {
            contentCache[cacheKey] = .loaded(persistedContent)
            contentState = .loaded(persistedContent)
            return
        }
        do {
            if let content = try await contentProvider.content(forPOI: poi.id, language: language) {
                contentCache[cacheKey] = .loaded(content)
                persistCachedContent(content, cacheKey: cacheKey)
                contentState = .loaded(content)
            } else {
                contentCache[cacheKey] = .empty
                contentState = .empty
            }
        } catch {
            contentState = .failed(strings.contentFailure)
        }
    }

    func setNearbyAlertsEnabled(_ enabled: Bool) async {
        if enabled {
            guard await notificationScheduler.requestAuthorization() else {
                nearbyAlertsEnabled = false
                userDefaults.set(false, forKey: Self.nearbyAlertsKey)
                return
            }
        }
        nearbyAlertsEnabled = enabled
        userDefaults.set(enabled, forKey: Self.nearbyAlertsKey)
    }

    func loadExternalContent(for poi: POI) async {
        guard let externalContentProvider else {
            externalContentState = .empty
            return
        }
        let cacheKey = externalContentCacheKey(for: poi)
        if let cached = externalContentCache[cacheKey] {
            switch cached {
            case .loaded(let content):
                externalContentState = .loaded(content)
            case .empty:
                externalContentState = .empty
            }
            return
        }
        externalContentState = .loading
        do {
            if let content = try await externalContentProvider.externalContent(forPOI: poi.id, coordinate: poi.coordinate, language: language) {
                externalContentCache[cacheKey] = .loaded(content)
                externalContentState = .loaded(content)
            } else {
                externalContentCache[cacheKey] = .empty
                externalContentState = .empty
            }
        } catch {
            externalContentState = .failed(strings.externalContentFailure)
        }
    }

    /// Picking a theme, per docs/adr/0015 — stops any playback from a
    /// previously selected section first, same rule `select(_:)` already
    /// applies when switching POIs.
    func selectSection(_ section: ContentSection) async {
        if playbackState != .stopped {
            await audioPlayer.stop()
            playbackState = .stopped
        }
        selectedSectionID = section.id
    }

    func deselectSection() async {
        if playbackState != .stopped {
            await audioPlayer.stop()
            playbackState = .stopped
        }
        selectedSectionID = nil
    }

    func playSelectedContent() async {
        guard case .loaded(let package) = contentState,
              let sectionID = selectedSectionID,
              let section = package.sections.first(where: { $0.id == sectionID }) else { return }
        await play(section)
    }

    func play(_ section: ContentSection) async {
        guard case .loaded(let package) = contentState else { return }
        if playbackState != .stopped, selectedSectionID != section.id {
            await audioPlayer.stop()
            playbackState = .stopped
        }
        selectedSectionID = section.id
        playbackState = .playing
        // `play` returns once synthesis is initiated, not once it
        // finishes (specs/010 — the protocol has no completion signal),
        // so `playbackState` reflects user intent (play/pause/stop), not
        // a live "is audio currently coming out of the speaker" signal.
        try? await audioPlayer.play(AudioAsset(id: section.id, text: textForReading(section), language: package.language, rateMultiplier: speechRate.multiplier))
    }

    func pausePlayback() async {
        await audioPlayer.pause()
        playbackState = .paused
    }

    func resumePlayback() async {
        await audioPlayer.resume()
        playbackState = .playing
    }

    func stopPlaying() async {
        await audioPlayer.stop()
        playbackState = .stopped
    }

    func isFavorite(_ poi: POI) -> Bool {
        favoritePOIs.contains { $0.id == poi.id }
    }

    func toggleFavorite(_ poi: POI) {
        if let index = favoritePOIs.firstIndex(where: { $0.id == poi.id }) {
            favoritePOIs.remove(at: index)
        } else {
            favoritePOIs.insert(poi, at: 0)
        }
        persist(favoritePOIs, key: Self.favoritesKey)
    }

    func qualityScore(for poi: POI) -> Int {
        var score = 0
        if poi.imageURL != nil { score += 3 }
        if let category = poi.category, !category.isEmpty { score += 2 }
        if poi.hasWikipediaArticle { score += 2 }
        if isFavorite(poi) { score += 1 }
        return score
    }

    func filteredPOIs(_ pois: [POI]) -> [POI] {
        pois.filter { poi in
            switch poiFilter {
            case .all:
                return true
            case .mustSee:
                return Self.isSearchedPlacePOI(poi) || qualityScore(for: poi) >= 5
            case .monuments:
                return matches(poi, keywords: ["monument", "memorial", "palace", "castle", "church", "cathedral", "statue", "gate", "tower", "mémorial", "palais", "château", "église", "cathédrale"])
            case .museums:
                return matches(poi, keywords: ["museum", "gallery", "collection", "exhibition", "musée", "galerie", "exposition"])
            case .nature:
                return matches(poi, keywords: ["park", "garden", "river", "lake", "forest", "view", "parc", "jardin", "rivière", "lac", "forêt", "vue"])
            case .food:
                return matches(poi, keywords: ["restaurant", "cafe", "café", "market", "food", "bar", "marché"])
            case .wikipedia:
                return Self.isSearchedPlacePOI(poi) || poi.hasWikipediaArticle
            case .complete:
                return Self.isSearchedPlacePOI(poi) || (poi.hasWikipediaArticle && poi.imageURL != nil && (poi.category?.isEmpty == false))
            }
        }
    }

    private func displayedPOIs(_ pois: [POI], around coordinate: Coordinate) -> [POI] {
        let sortedPOIs = sortByDistanceThenQuality(pois, from: coordinate)
        guard let browsingPlacePOI else { return sortedPOIs }
        if browsingPlaceIsAdministrative == false,
           sortedPOIs.contains(where: { Self.isEquivalentSearchResult($0, to: browsingPlacePOI) }) {
            return sortedPOIs
        }
        let deduplicatedPOIs = sortedPOIs.filter { poi in
            poi.id != browsingPlacePOI.id
                && Self.isEquivalentSearchResult(poi, to: browsingPlacePOI) == false
        }
        if browsingPlaceIsAdministrative {
            let cityPOIs = Array(deduplicatedPOIs.prefix(Self.administrativePlacePOILimit))
            return cityPOIs.isEmpty ? [browsingPlacePOI] : cityPOIs
        }
        return [browsingPlacePOI] + deduplicatedPOIs
    }

    private func sortByDistanceThenQuality(_ pois: [POI], from coordinate: Coordinate) -> [POI] {
        pois.sorted {
            let lhsDistance = coordinate.distanceMeters(to: $0.coordinate)
            let rhsDistance = coordinate.distanceMeters(to: $1.coordinate)
            if abs(lhsDistance - rhsDistance) > 1 {
                return lhsDistance < rhsDistance
            }

            let lhsScore = qualityScore(for: $0)
            let rhsScore = qualityScore(for: $1)
            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }

            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func resortLoadedPOIs(from coordinate: Coordinate) {
        guard case .loaded(let pois) = state else { return }
        state = .loaded(sortByDistanceThenQuality(pois, from: coordinate))
    }

    private func refreshNearbyPOIsForLiveLocationIfNeeded(around coordinate: Coordinate) async {
        guard browsingCoordinate == nil, isRefreshingPOIsForLiveLocation == false else { return }
        guard let lastNearbyPOICenterCoordinate else {
            self.lastNearbyPOICenterCoordinate = coordinate
            return
        }
        guard coordinate.distanceMeters(to: lastNearbyPOICenterCoordinate) >= Self.livePOIRefreshDistanceMeters else { return }

        isRefreshingPOIsForLiveLocation = true
        defer { isRefreshingPOIsForLiveLocation = false }
        do {
            let pois = try await poiProvider.nearbyPOI(around: coordinate, radiusMeters: radiusMeters, language: language)
            let sortedPOIs = displayedPOIs(pois, around: coordinate)
            state = .loaded(sortedPOIs)
            await updateAutoGuideSuggestion(from: sortedPOIs, userCoordinate: coordinate)
            offlineNotice = nil
            self.lastNearbyPOICenterCoordinate = coordinate
            persistCachedNearbyPOIs(sortedPOIs)
            if nearbyAlertsEnabled {
                await notificationScheduler.notifyNearbyPOIIfNeeded(pois: sortedPOIs, userCoordinate: coordinate, strings: strings)
            }
        } catch {
            resortLoadedPOIs(from: coordinate)
        }
    }

    private func updateAutoGuideSuggestion(from pois: [POI], userCoordinate: Coordinate) async {
        guard guideMode != .off, browsingCoordinate == nil else {
            autoGuideSuggestion = nil
            return
        }
        guard let candidate = pois
            .map({ poi in (poi, userCoordinate.distanceMeters(to: poi.coordinate)) })
            .filter({ $0.1 <= Self.guideDistanceMeters })
            .sorted(by: { lhs, rhs in
                if abs(lhs.1 - rhs.1) > 1 { return lhs.1 < rhs.1 }
                return qualityScore(for: lhs.0) > qualityScore(for: rhs.0)
            })
            .first else {
            autoGuideSuggestion = nil
            return
        }

        autoGuideSuggestion = AutoGuideSuggestion(poi: candidate.0, distanceMeters: candidate.1)
        guard guideMode == .autoPlay,
              announcedAutoGuidePOIIDs.contains(candidate.0.id) == false,
              isAutoPlayingGuide == false else { return }
        announcedAutoGuidePOIIDs.insert(candidate.0.id)
        await playAutoGuide(for: candidate.0)
    }

    private func playAutoGuide(for poi: POI) async {
        guard Self.isSearchedPlacePOI(poi) == false else { return }
        isAutoPlayingGuide = true
        defer { isAutoPlayingGuide = false }
        await select(poi)
        guard case .loaded(let package) = contentState,
              let firstSection = package.sections.first else { return }
        await play(firstSection)
    }

    func qualityLabel(for poi: POI) -> String {
        switch qualityScore(for: poi) {
        case let score:
            return strings.qualityLabel(score: score)
        }
    }

    func confidenceBadges(for poi: POI) -> [String] {
        var badges: [String] = []
        if poi.hasWikipediaArticle { badges.append(strings.wikipediaSource) }
        if poi.imageURL != nil { badges.append(strings.imageAvailable) }
        if poi.category?.isEmpty == false { badges.append(strings.typedPlace) }
        if distanceText(for: poi) != nil { badges.append(strings.gpsDistance) }
        if badges.isEmpty { badges.append(strings.basicMapResult) }
        return badges
    }

    func distanceText(for poi: POI) -> String? {
        guard let distanceReferenceCoordinate else { return nil }
        let meters = distanceReferenceCoordinate.distanceMeters(to: poi.coordinate)
        if meters < 1000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }

    func textForReading(_ section: ContentSection) -> String {
        switch readingMode {
        case .complete:
            return section.text
        case .short:
            return Self.shortText(from: section.text)
        }
    }

    private func addToHistory(_ poi: POI) {
        recentPOIs.removeAll { $0.id == poi.id }
        recentPOIs.insert(poi, at: 0)
        if recentPOIs.count > 20 {
            recentPOIs = Array(recentPOIs.prefix(20))
        }
        persist(recentPOIs, key: Self.historyKey)
    }

    private static func shortText(from text: String) -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let paragraphs = trimmedText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let firstParagraph = paragraphs.first ?? trimmedText
        let sentences = firstParagraph
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let firstSentence = sentences.first ?? firstParagraph
        let words = firstSentence.split(separator: " ")

        if words.count > 32 {
            return words.prefix(32).joined(separator: " ") + "…"
        }
        if firstSentence.count < trimmedText.count {
            return firstSentence + "."
        }

        let fallbackWords = trimmedText.split(separator: " ")
        guard fallbackWords.count > 32 else { return trimmedText }
        return fallbackWords.prefix(32).joined(separator: " ") + "…"
    }

    private static func poi(from place: PlaceResult) -> POI {
        POI(
            id: place.wikidataID ?? searchedPlacePOIPrefix + place.id,
            name: place.name,
            coordinate: place.coordinate,
            category: place.subtitle?.isEmpty == false ? place.subtitle : nil,
            hasWikipediaArticle: place.wikidataID != nil
        )
    }

    private static func isSearchedPlacePOI(_ poi: POI) -> Bool {
        poi.id.hasPrefix(searchedPlacePOIPrefix)
    }

    private static func isEquivalentSearchResult(_ poi: POI, to searchedPlacePOI: POI) -> Bool {
        poi.name.localizedCaseInsensitiveCompare(searchedPlacePOI.name) == .orderedSame
            || poi.coordinate.distanceMeters(to: searchedPlacePOI.coordinate) <= 25
    }

    private static func loadPOIs(from userDefaults: UserDefaults, key: String) -> [POI] {
        guard let data = userDefaults.data(forKey: key),
              let pois = try? JSONDecoder().decode([POI].self, from: data) else {
            return []
        }
        return pois
    }

    private static func loadStringDictionary(from userDefaults: UserDefaults, key: String) -> [String: String] {
        guard let data = userDefaults.data(forKey: key),
              let values = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return values
    }

    private static func loadOfflinePacks(from userDefaults: UserDefaults) -> [OfflineAreaPack] {
        guard let data = userDefaults.data(forKey: offlinePacksKey),
              let packs = try? JSONDecoder().decode([OfflineAreaPack].self, from: data) else {
            return []
        }
        return packs
    }

    private func persistOfflinePacks() {
        guard let data = try? JSONEncoder().encode(offlinePacks) else { return }
        userDefaults.set(data, forKey: Self.offlinePacksKey)
    }

    private func matches(_ poi: POI, keywords: [String]) -> Bool {
        let text = "\(poi.name) \(poi.category ?? "")".lowercased()
        return keywords.contains { text.contains($0) }
    }

    private func persist(_ pois: [POI], key: String) {
        guard let data = try? JSONEncoder().encode(pois) else { return }
        userDefaults.set(data, forKey: key)
    }

    private func persist(_ values: [String: String], key: String) {
        guard let data = try? JSONEncoder().encode(values) else { return }
        userDefaults.set(data, forKey: key)
    }

    private func nearbyCacheID() -> String {
        "\(language)|\(Int(radiusMeters.rounded()))"
    }

    private func externalContentCacheKey(for poi: POI) -> String {
        "\(poi.id)|\(language)|official"
    }

    private func loadCachedNearbyPOIs() -> [POI]? {
        guard let data = userDefaults.data(forKey: Self.nearbyCacheKey),
              let cache = try? JSONDecoder().decode([String: [POI]].self, from: data) else {
            return nil
        }
        return cache[nearbyCacheID()]
    }

    private func persistCachedNearbyPOIs(_ pois: [POI]) {
        let decoder = JSONDecoder()
        let existingData = userDefaults.data(forKey: Self.nearbyCacheKey)
        var cache = existingData.flatMap { try? decoder.decode([String: [POI]].self, from: $0) } ?? [:]
        cache[nearbyCacheID()] = Array(pois.prefix(50))
        guard let data = try? JSONEncoder().encode(cache) else { return }
        userDefaults.set(data, forKey: Self.nearbyCacheKey)
    }

    private func loadCachedContent(cacheKey: String) -> ContentPackage? {
        guard let data = userDefaults.data(forKey: Self.contentCacheKey),
              let cache = try? JSONDecoder().decode([String: ContentPackage].self, from: data) else {
            return nil
        }
        return cache[cacheKey]
    }

    private func persistCachedContent(_ content: ContentPackage, cacheKey: String) {
        let decoder = JSONDecoder()
        let existingData = userDefaults.data(forKey: Self.contentCacheKey)
        var cache = existingData.flatMap { try? decoder.decode([String: ContentPackage].self, from: $0) } ?? [:]
        cache[cacheKey] = content
        guard let data = try? JSONEncoder().encode(cache) else { return }
        userDefaults.set(data, forKey: Self.contentCacheKey)
    }

    private static func deviceLanguageCode() -> String {
        Locale.preferredLanguages.first ?? Locale.current.language.languageCode?.identifier ?? "en"
    }

    private static func supportedLanguageCode(for rawCode: String) -> String {
        let code = rawCode.lowercased()
        if code.hasPrefix("zh") {
            return "zh-hans"
        }
        if supportedLanguages.contains(where: { $0.code == code }) {
            return code
        }
        if let match = supportedLanguages.first(where: { code.hasPrefix($0.code) }) {
            return match.code
        }
        return "en"
    }
}

@MainActor
struct NoopNearbyNotificationScheduler: NearbyNotificationScheduling {
    func requestAuthorization() async -> Bool { false }
    func notifyNearbyPOIIfNeeded(pois: [POI], userCoordinate: Coordinate, strings: AppStrings) async {}
}
