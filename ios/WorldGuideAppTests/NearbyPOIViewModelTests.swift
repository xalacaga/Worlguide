import XCTest
import WGCore
import WGPOI
import WGContent
import WGPlayback
import WGLocation
import WGWeather
@testable import WorldGuide

private struct FakeLocationProviding: LocationProviding {
    var result: Result<Coordinate, Error> = .success(Coordinate(latitude: 48.8584, longitude: 2.2945))

    func currentLocation() async throws -> Coordinate {
        try result.get()
    }
}

private final class LiveFakeLocationProviding: LocationProviding, @unchecked Sendable {
    private let initialCoordinate: Coordinate
    private var continuation: AsyncThrowingStream<Coordinate, Error>.Continuation?

    init(initialCoordinate: Coordinate = Coordinate(latitude: 48.8584, longitude: 2.2945)) {
        self.initialCoordinate = initialCoordinate
    }

    func currentLocation() async throws -> Coordinate {
        initialCoordinate
    }

    func locationUpdates() -> AsyncThrowingStream<Coordinate, Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
        }
    }

    func yield(_ coordinate: Coordinate) {
        continuation?.yield(coordinate)
    }

    func finish() {
        continuation?.finish()
    }
}

private struct FakePOIProviding: POIProviding {
    var result: Result<[POI], Error> = .success([])

    func nearbyPOI(around coordinate: Coordinate, radiusMeters: Double, language: String) async throws -> [POI] {
        try result.get()
    }
}

private final class SequencedPOIProviding: POIProviding, @unchecked Sendable {
    private var results: [[POI]]

    init(results: [[POI]]) {
        self.results = results
    }

    func nearbyPOI(around coordinate: Coordinate, radiusMeters: Double, language: String) async throws -> [POI] {
        guard results.count > 1 else {
            return results.first ?? []
        }
        return results.removeFirst()
    }
}

private actor CapturingPOIProviding: POIProviding {
    private let result: [POI]
    private let results: [[POI]]?
    private var resultIndex = 0
    private var capturedCoordinate: Coordinate?
    private var capturedRadiusMeters: Double?
    private var capturedCoordinates: [Coordinate] = []

    init(result: [POI]) {
        self.result = result
        self.results = nil
    }

    init(results: [[POI]]) {
        self.result = []
        self.results = results
    }

    func nearbyPOI(around coordinate: Coordinate, radiusMeters: Double, language: String) async throws -> [POI] {
        capturedCoordinate = coordinate
        capturedRadiusMeters = radiusMeters
        capturedCoordinates.append(coordinate)
        if let results {
            guard results.count > 1, resultIndex < results.count - 1 else {
                return results.last ?? []
            }
            defer { resultIndex += 1 }
            return results[resultIndex]
        }
        return result
    }

    func capturedCoordinateValue() -> Coordinate? {
        capturedCoordinate
    }

    func capturedRadiusMetersValue() -> Double? {
        capturedRadiusMeters
    }

    func capturedCoordinatesValue() -> [Coordinate] {
        capturedCoordinates
    }
}

private struct FakePlaceSearching: PlaceSearching {
    var result: Result<[PlaceResult], Error> = .success([])

    func searchPlaces(matching query: String, near coordinate: Coordinate?) async throws -> [PlaceResult] {
        try result.get()
    }
}

private struct FakeContentProviding: ContentProviding {
    var result: Result<ContentPackage?, Error> = .success(nil)

    func content(forPOI poiID: String, language: String) async throws -> ContentPackage? {
        try result.get()
    }
}

private struct FakeExternalContentProviding: ExternalContentProviding {
    var result: Result<ExternalContentPackage?, Error> = .success(nil)

    func externalContent(forPOI poiID: String, coordinate: Coordinate?, language: String) async throws -> ExternalContentPackage? {
        try result.get()
    }
}

private struct FakeWeatherProviding: WeatherProviding {
    var result: Result<WeatherSnapshot, Error>

    func currentWeather(around coordinate: Coordinate) async throws -> WeatherSnapshot {
        try result.get()
    }
}

private actor CapturingExternalContentProviding: ExternalContentProviding {
    private var capturedCoordinate: Coordinate?
    private var callCount = 0
    let package: ExternalContentPackage?

    init(package: ExternalContentPackage? = nil) {
        self.package = package
    }

    func externalContent(forPOI poiID: String, coordinate: Coordinate?, language: String) async throws -> ExternalContentPackage? {
        callCount += 1
        capturedCoordinate = coordinate
        return package
    }

    func capturedCoordinateValue() -> Coordinate? {
        capturedCoordinate
    }

    func callCountValue() -> Int {
        callCount
    }
}

private actor CountingContentProviding: ContentProviding {
    private(set) var callCount = 0
    let package: ContentPackage?

    init(package: ContentPackage?) {
        self.package = package
    }

    func content(forPOI poiID: String, language: String) async throws -> ContentPackage? {
        callCount += 1
        return package
    }
}

private final class CapturingPlaceSearching: PlaceSearching, @unchecked Sendable {
    private(set) var capturedQuery: String?
    private(set) var capturedCoordinate: Coordinate?
    let searchResult: [PlaceResult]

    init(searchResult: [PlaceResult]) {
        self.searchResult = searchResult
    }

    func searchPlaces(matching query: String, near coordinate: Coordinate?) async throws -> [PlaceResult] {
        capturedQuery = query
        capturedCoordinate = coordinate
        return searchResult
    }
}

private actor FakeAudioPlaying: AudioPlaying {
    private(set) var playedAssets: [AudioAsset] = []
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0
    private(set) var stopCount = 0

    func play(_ asset: AudioAsset) async throws {
        playedAssets.append(asset)
    }

    func pause() async {
        pauseCount += 1
    }

    func resume() async {
        resumeCount += 1
    }

    func stop() async {
        stopCount += 1
    }
}

@MainActor
private final class FakeNearbyNotificationScheduler: NearbyNotificationScheduling {
    var authorizationGranted = true
    private(set) var authorizationRequestCount = 0
    private(set) var notifiedPOICounts: [Int] = []

    func requestAuthorization() async -> Bool {
        authorizationRequestCount += 1
        return authorizationGranted
    }

    func notifyNearbyPOIIfNeeded(pois: [POI], userCoordinate: Coordinate, strings: AppStrings) async {
        notifiedPOICounts.append(pois.count)
    }
}

@MainActor
final class NearbyPOIViewModelTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var userDefaultsSuiteName: String!

    override func setUp() {
        super.setUp()
        userDefaultsSuiteName = "NearbyPOIViewModelTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults = nil
        userDefaultsSuiteName = nil
        super.tearDown()
    }

    private func makeViewModel(
        location: LocationProviding = FakeLocationProviding(),
        pois: POIProviding = FakePOIProviding(),
        placeSearcher: PlaceSearching = FakePlaceSearching(),
        content: FakeContentProviding = FakeContentProviding(),
        externalContent: ExternalContentProviding? = nil,
        weather: WeatherProviding? = nil,
        audio: FakeAudioPlaying = FakeAudioPlaying(),
        notificationScheduler: NearbyNotificationScheduling? = nil,
        userDefaults: UserDefaults? = nil
    ) -> (NearbyPOIViewModel, FakeAudioPlaying) {
        let viewModel = NearbyPOIViewModel(
            locationProvider: location,
            poiProvider: pois,
            placeSearcher: placeSearcher,
            contentProvider: content,
            externalContentProvider: externalContent,
            weatherProvider: weather,
            audioPlayer: audio,
            notificationScheduler: notificationScheduler ?? NoopNearbyNotificationScheduler(),
            language: "en",
            userDefaults: userDefaults ?? self.userDefaults
        )
        return (viewModel, audio)
    }

    private func makeViewModel(
        content: CountingContentProviding,
        userDefaults: UserDefaults? = nil
    ) -> NearbyPOIViewModel {
        NearbyPOIViewModel(
            locationProvider: FakeLocationProviding(),
            poiProvider: FakePOIProviding(),
            placeSearcher: FakePlaceSearching(),
            contentProvider: content,
            weatherProvider: nil,
            audioPlayer: FakeAudioPlaying(),
            notificationScheduler: NoopNearbyNotificationScheduler(),
            language: "en",
            userDefaults: userDefaults ?? self.userDefaults
        )
    }

    // MARK: - loadNearbyPOIs

    func testDefaultRadiusIs500Meters() {
        let (viewModel, _) = makeViewModel()

        XCTAssertEqual(viewModel.radiusMeters, 500)
    }

    func testLoadNearbyPOIsSortsResultsByDistanceFromTheFetchedCoordinate() async throws {
        let origin = Coordinate(latitude: 0, longitude: 0)
        let near = POI(id: "near", name: "Near", coordinate: Coordinate(latitude: 0.001, longitude: 0))
        let far = POI(id: "far", name: "Far", coordinate: Coordinate(latitude: 0.01, longitude: 0))
        let (viewModel, _) = makeViewModel(
            location: FakeLocationProviding(result: .success(origin)),
            pois: FakePOIProviding(result: .success([far, near]))
        )

        await viewModel.loadNearbyPOIs()

        guard case .loaded(let sorted) = viewModel.state else {
            return XCTFail("Expected .loaded, got \(viewModel.state)")
        }
        XCTAssertEqual(sorted.map(\.id), ["near", "far"])
        XCTAssertEqual(viewModel.userCoordinate, origin)
    }

    func testSetRadiusUpdatesRadiusAndReloadsPOIs() async throws {
        let (viewModel, _) = makeViewModel()

        await viewModel.setRadius(3000)

        XCTAssertEqual(viewModel.radiusMeters, 3000)
        guard case .loaded = viewModel.state else {
            return XCTFail("Expected .loaded, got \(viewModel.state)")
        }
    }

    func testLoadNearbyPOIsSurfacesAPermissionDeniedMessage() async throws {
        let (viewModel, _) = makeViewModel(location: FakeLocationProviding(result: .failure(WGError.permissionDenied)))

        await viewModel.loadNearbyPOIs()

        guard case .failed(let message) = viewModel.state else {
            return XCTFail("Expected .failed, got \(viewModel.state)")
        }
        XCTAssertTrue(message.localizedCaseInsensitiveContains("location"))
    }

    func testLoadNearbyPOIsSurfacesAGenericFailureMessage() async throws {
        let (viewModel, _) = makeViewModel(pois: FakePOIProviding(result: .failure(WGError.network("boom"))))

        await viewModel.loadNearbyPOIs()

        guard case .failed = viewModel.state else {
            return XCTFail("Expected .failed, got \(viewModel.state)")
        }
    }

    func testLoadNearbyPOIsFallsBackToOfflineCacheWhenNetworkFails() async throws {
        let poi = POI(id: "cached", name: "Cached", coordinate: Coordinate(latitude: 0, longitude: 0))
        let (onlineViewModel, _) = makeViewModel(pois: FakePOIProviding(result: .success([poi])), userDefaults: userDefaults)
        await onlineViewModel.loadNearbyPOIs()

        let (offlineViewModel, _) = makeViewModel(pois: FakePOIProviding(result: .failure(WGError.network("offline"))), userDefaults: userDefaults)
        await offlineViewModel.loadNearbyPOIs()

        guard case .loaded(let cachedPOIs) = offlineViewModel.state else {
            return XCTFail("Expected cached .loaded state, got \(offlineViewModel.state)")
        }
        XCTAssertEqual(cachedPOIs.map(\.id), ["cached"])
        XCTAssertEqual(offlineViewModel.offlineNotice, "Offline mode: showing your last saved places.")
    }

    func testLoadNearbyPOIsRefreshesLiveWeatherContext() async throws {
        let coordinate = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let weather = FakeWeatherProviding(result: .success(WeatherSnapshot(
            coordinate: coordinate,
            temperatureCelsius: 12,
            precipitationMillimeters: 1.2,
            weatherCode: 61,
            isDaylight: false
        )))
        let (viewModel, _) = makeViewModel(
            location: FakeLocationProviding(result: .success(coordinate)),
            weather: weather
        )

        await viewModel.loadNearbyPOIs()

        XCTAssertEqual(viewModel.weatherMood, .rain)
        guard case .live(let snapshot) = viewModel.weatherState else {
            return XCTFail("Expected live weather, got \(viewModel.weatherState)")
        }
        XCTAssertEqual(snapshot, WeatherSnapshot(
            coordinate: coordinate,
            temperatureCelsius: 12,
            precipitationMillimeters: 1.2,
            weatherCode: 61,
            isDaylight: false
        ))
        XCTAssertTrue(viewModel.walkContext.isLowLight)
    }

    func testWeatherFailureKeepsManualContextAvailable() async throws {
        let (viewModel, _) = makeViewModel(
            weather: FakeWeatherProviding(result: .failure(WGError.network("offline")))
        )
        viewModel.weatherMood = .hot

        await viewModel.loadNearbyPOIs()

        XCTAssertEqual(viewModel.weatherMood, .hot)
        guard case .failed(let message) = viewModel.weatherState else {
            return XCTFail("Expected failed weather, got \(viewModel.weatherState)")
        }
        XCTAssertTrue(message.localizedCaseInsensitiveContains("weather"))
    }

    func testFilteredPOIsCanKeepOnlyWikipediaOrCompleteItems() {
        let wikipediaOnly = POI(
            id: "wiki",
            name: "Wiki",
            coordinate: Coordinate(latitude: 0, longitude: 0),
            hasWikipediaArticle: true
        )
        let complete = POI(
            id: "complete",
            name: "Complete",
            coordinate: Coordinate(latitude: 0, longitude: 0),
            category: "museum",
            hasWikipediaArticle: true,
            imageURL: URL(string: "https://example.com/image.jpg")!
        )
        let basic = POI(id: "basic", name: "Basic", coordinate: Coordinate(latitude: 0, longitude: 0))
        let (viewModel, _) = makeViewModel()

        viewModel.poiFilter = .wikipedia
        XCTAssertEqual(viewModel.filteredPOIs([wikipediaOnly, complete, basic]).map(\.id), ["wiki", "complete"])

        viewModel.poiFilter = .complete
        XCTAssertEqual(viewModel.filteredPOIs([wikipediaOnly, complete, basic]).map(\.id), ["complete"])
    }

    func testNearbyAlertsAreOptInAndNotifyAfterLoadingPOIs() async throws {
        let scheduler = FakeNearbyNotificationScheduler()
        let poi = POI(id: "near", name: "Near", coordinate: Coordinate(latitude: 48.8584, longitude: 2.2945))
        let (viewModel, _) = makeViewModel(
            location: FakeLocationProviding(result: .success(Coordinate(latitude: 48.8584, longitude: 2.2945))),
            pois: FakePOIProviding(result: .success([poi])),
            notificationScheduler: scheduler
        )

        await viewModel.setNearbyAlertsEnabled(true)
        await viewModel.loadNearbyPOIs()

        XCTAssertTrue(viewModel.nearbyAlertsEnabled)
        XCTAssertEqual(scheduler.authorizationRequestCount, 1)
        XCTAssertEqual(scheduler.notifiedPOICounts, [1])
    }

    func testNearbyAlertsStayDisabledWhenAuthorizationIsDenied() async throws {
        let scheduler = FakeNearbyNotificationScheduler()
        scheduler.authorizationGranted = false
        let (viewModel, _) = makeViewModel(notificationScheduler: scheduler)

        await viewModel.setNearbyAlertsEnabled(true)

        XCTAssertFalse(viewModel.nearbyAlertsEnabled)
        XCTAssertEqual(scheduler.authorizationRequestCount, 1)
    }

    func testSearchPlacesForwardsTrimmedQueryAndCurrentCoordinateAsBias() async throws {
        let coordinate = Coordinate(latitude: 52.52, longitude: 13.405)
        let berlin = PlaceResult(id: "1", name: "Berlin", subtitle: "Germany", coordinate: coordinate)
        let placeSearcher = CapturingPlaceSearching(searchResult: [berlin])
        let (viewModel, _) = makeViewModel(
            location: FakeLocationProviding(result: .success(coordinate)),
            placeSearcher: placeSearcher
        )
        await viewModel.loadNearbyPOIs()

        await viewModel.searchPlaces(matching: " Berlin ")

        XCTAssertEqual(placeSearcher.capturedQuery, "Berlin")
        XCTAssertEqual(placeSearcher.capturedCoordinate, coordinate)
        XCTAssertEqual(viewModel.placeSearchResults, [berlin])
        XCTAssertFalse(viewModel.isSearchingPlaces)
        XCTAssertTrue(viewModel.isPlaceSearchActive)
    }

    func testSearchPlacesClearsResultsForShortQuery() async throws {
        let (viewModel, _) = makeViewModel()

        await viewModel.searchPlaces(matching: "a")

        XCTAssertFalse(viewModel.isPlaceSearchActive)
        XCTAssertEqual(viewModel.placeSearchResults, [])
    }

    func testJumpToPlaceRecentersExplorationAndSkipsTheRealLocationCache() async throws {
        let realLocation = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let berlinPOI = POI(id: "Q64", name: "Berlin", coordinate: Coordinate(latitude: 52.52, longitude: 13.405))
        let pois = FakePOIProviding(result: .success([berlinPOI]))
        let (viewModel, _) = makeViewModel(
            location: FakeLocationProviding(result: .success(realLocation)),
            pois: pois
        )
        let place = PlaceResult(id: "1", name: "Berlin", subtitle: "Germany", coordinate: Coordinate(latitude: 52.52, longitude: 13.405))

        await viewModel.jumpToPlace(place)

        XCTAssertEqual(viewModel.browsingPlaceName, "Berlin")
        XCTAssertEqual(viewModel.userCoordinate, realLocation)
        XCTAssertEqual(viewModel.explorationCoordinate, place.coordinate)
        guard case .loaded(let loadedPOIs) = viewModel.state else {
            return XCTFail("Expected .loaded, got \(viewModel.state)")
        }
        XCTAssertEqual(loadedPOIs.map(\.id), ["Q64"])
        XCTAssertEqual(loadedPOIs.first?.coordinate, berlinPOI.coordinate)
        XCTAssertFalse(viewModel.isPlaceSearchActive)
    }

    func testJumpToPlaceKeepsSearchedMapPlaceWhenNoWikipediaPOIExists() async throws {
        let realLocation = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let searchedCoordinate = Coordinate(latitude: 52.5001, longitude: 13.4222)
        let (viewModel, _) = makeViewModel(
            location: FakeLocationProviding(result: .success(realLocation)),
            pois: FakePOIProviding(result: .success([]))
        )
        let place = PlaceResult(id: "nonna-cafe", name: "Nonna Café", subtitle: "Berlin", coordinate: searchedCoordinate)

        await viewModel.jumpToPlace(place)

        guard case .loaded(let loadedPOIs) = viewModel.state else {
            return XCTFail("Expected .loaded, got \(viewModel.state)")
        }
        XCTAssertEqual(loadedPOIs.count, 1)
        XCTAssertEqual(loadedPOIs[0].id, "place-search:nonna-cafe")
        XCTAssertEqual(loadedPOIs[0].name, "Nonna Café")
        XCTAssertEqual(loadedPOIs[0].coordinate, searchedCoordinate)
        XCTAssertEqual(viewModel.userCoordinate, realLocation)
        XCTAssertNotEqual(viewModel.distanceText(for: loadedPOIs[0]), "0 m")
    }

    func testSearchedMapPlaceRemainsVisibleWithStrictPOIFilters() async throws {
        let searchedCoordinate = Coordinate(latitude: 52.5001, longitude: 13.4222)
        let (viewModel, _) = makeViewModel(
            pois: FakePOIProviding(result: .success([]))
        )
        let place = PlaceResult(id: "nonna-cafe", name: "Nonna Café", subtitle: "Berlin", coordinate: searchedCoordinate)

        await viewModel.jumpToPlace(place)
        guard case .loaded(let loadedPOIs) = viewModel.state else {
            return XCTFail("Expected .loaded, got \(viewModel.state)")
        }

        viewModel.poiFilter = .complete

        XCTAssertEqual(viewModel.filteredPOIs(loadedPOIs).map(\.id), ["place-search:nonna-cafe"])
    }

    func testSelectingSearchedMapPlaceDoesNotAskWikipediaContentProvider() async throws {
        let (viewModel, _) = makeViewModel(content: FakeContentProviding(result: .failure(WGError.network("should not be called"))))
        let place = PlaceResult(
            id: "nonna-cafe",
            name: "Nonna Café",
            subtitle: "Berlin",
            coordinate: Coordinate(latitude: 52.5001, longitude: 13.4222)
        )
        await viewModel.jumpToPlace(place)
        guard case .loaded(let loadedPOIs) = viewModel.state, let poi = loadedPOIs.first else {
            return XCTFail("Expected a searched place POI")
        }

        await viewModel.select(poi)

        guard case .empty = viewModel.contentState else {
            return XCTFail("Expected .empty, got \(viewModel.contentState)")
        }
    }

    func testJumpToAdministrativePlaceShowsTenInterestingCityPOIs() async throws {
        let realLocation = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let cityCoordinate = Coordinate(latitude: 52.52, longitude: 13.405)
        let cityPOIs = (0..<12).map { index in
            POI(
                id: "Q\(index)",
                name: "Berlin POI \(index)",
                coordinate: Coordinate(latitude: cityCoordinate.latitude, longitude: cityCoordinate.longitude + Double(index + 1) * 0.001),
                hasWikipediaArticle: index.isMultiple(of: 2),
                imageURL: index.isMultiple(of: 3) ? URL(string: "https://example.com/\(index).jpg") : nil
            )
        }
        let provider = CapturingPOIProviding(result: cityPOIs)
        let (viewModel, _) = makeViewModel(
            location: FakeLocationProviding(result: .success(realLocation)),
            pois: provider
        )
        let place = PlaceResult(
            id: "berlin",
            name: "Berlin",
            subtitle: "Germany",
            coordinate: cityCoordinate,
            isAdministrativePlace: true
        )

        await viewModel.jumpToPlace(place)

        let capturedCoordinate = await provider.capturedCoordinateValue()
        let capturedRadiusMeters = await provider.capturedRadiusMetersValue()
        XCTAssertEqual(capturedCoordinate, cityCoordinate)
        XCTAssertEqual(capturedRadiusMeters, 3_000)
        XCTAssertEqual(viewModel.userCoordinate, realLocation)
        XCTAssertEqual(viewModel.explorationCoordinate, cityCoordinate)
        guard case .loaded(let loadedPOIs) = viewModel.state else {
            return XCTFail("Expected .loaded, got \(viewModel.state)")
        }
        XCTAssertEqual(loadedPOIs.count, 10)
        XCTAssertFalse(loadedPOIs.contains { $0.id.hasPrefix("place-search:") })
        XCTAssertNotEqual(viewModel.distanceText(for: loadedPOIs[0]), "0 m")
    }

    func testDistanceTextKeepsRealLocationAsReferenceWhileBrowsing() async throws {
        let realLocation = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let searchedCoordinate = Coordinate(latitude: 52.52, longitude: 13.405)
        let searchedPlacePOI = POI(id: "Q64", name: "Berlin", coordinate: searchedCoordinate)
        let (viewModel, _) = makeViewModel(
            location: FakeLocationProviding(result: .success(realLocation)),
            pois: FakePOIProviding(result: .success([searchedPlacePOI]))
        )
        let place = PlaceResult(id: "1", name: "Berlin", subtitle: "Germany", coordinate: searchedCoordinate)

        await viewModel.jumpToPlace(place)

        XCTAssertEqual(viewModel.userCoordinate, realLocation)
        XCTAssertEqual(viewModel.explorationCoordinate, searchedCoordinate)
        XCTAssertNotEqual(viewModel.distanceText(for: searchedPlacePOI), "0 m")
        XCTAssertTrue(viewModel.distanceText(for: searchedPlacePOI)?.hasSuffix("km") == true)
    }

    func testReturnToMyLocationClearsBrowsingAndReloadsTheRealLocation() async throws {
        let realLocation = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let (viewModel, _) = makeViewModel(location: FakeLocationProviding(result: .success(realLocation)))
        let place = PlaceResult(id: "1", name: "Berlin", subtitle: "Germany", coordinate: Coordinate(latitude: 52.52, longitude: 13.405))
        await viewModel.jumpToPlace(place)

        await viewModel.returnToMyLocation()

        XCTAssertNil(viewModel.browsingPlaceName)
        XCTAssertEqual(viewModel.userCoordinate, realLocation)
    }

    func testReturnToMyLocationUsesLatestLiveGPSFixAfterBrowsing() async throws {
        let initialLocation = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let latestLocation = Coordinate(latitude: 48.8600, longitude: 2.3600)
        let browsedLocation = Coordinate(latitude: 52.52, longitude: 13.405)
        let location = LiveFakeLocationProviding(initialCoordinate: initialLocation)
        let provider = CapturingPOIProviding(results: [[], []])
        let (viewModel, _) = makeViewModel(location: location, pois: provider)
        let task = Task { await viewModel.observeLiveLocationUpdates() }

        await Task.yield()
        location.yield(initialLocation)
        await Task.yield()
        await viewModel.jumpToPlace(PlaceResult(id: "berlin", name: "Berlin", subtitle: "Germany", coordinate: browsedLocation))
        location.yield(latestLocation)
        await Task.yield()

        await viewModel.returnToMyLocation()
        location.finish()
        await task.value

        XCTAssertEqual(viewModel.userCoordinate, latestLocation)
        let capturedCoordinates = await provider.capturedCoordinatesValue()
        XCTAssertEqual(capturedCoordinates.first, browsedLocation)
        XCTAssertEqual(capturedCoordinates.last, latestLocation)
        XCTAssertTrue(capturedCoordinates.contains(latestLocation))
    }

    func testLiveLocationUpdatesMoveTheUserCoordinate() async throws {
        let location = LiveFakeLocationProviding()
        let (viewModel, _) = makeViewModel(location: location)
        let task = Task { await viewModel.observeLiveLocationUpdates() }

        await Task.yield()
        location.yield(Coordinate(latitude: 48, longitude: 2))
        await Task.yield()
        location.yield(Coordinate(latitude: 49, longitude: 3))
        await Task.yield()
        location.finish()
        await task.value

        XCTAssertEqual(viewModel.userCoordinate, Coordinate(latitude: 49, longitude: 3))
    }

    func testLiveLocationUpdatesResortLoadedPOIsByCurrentDistance() async throws {
        let location = LiveFakeLocationProviding(initialCoordinate: Coordinate(latitude: 0, longitude: 0))
        let nearbyPOI = POI(id: "near-start", name: "Near Start", coordinate: Coordinate(latitude: 0, longitude: 0.001))
        let movedTowardPOI = POI(id: "near-after-move", name: "Near After Move", coordinate: Coordinate(latitude: 0, longitude: 0.01))
        let (viewModel, _) = makeViewModel(
            location: location,
            pois: FakePOIProviding(result: .success([movedTowardPOI, nearbyPOI]))
        )
        await viewModel.loadNearbyPOIs()
        let task = Task { await viewModel.observeLiveLocationUpdates() }

        await Task.yield()
        location.yield(Coordinate(latitude: 0, longitude: 0.01))
        await Task.yield()
        location.finish()
        await task.value

        guard case .loaded(let pois) = viewModel.state else {
            return XCTFail("Expected .loaded, got \(viewModel.state)")
        }
        XCTAssertEqual(pois.map(\.id), ["near-after-move", "near-start"])
    }

    func testLiveLocationUpdatesRefreshThePOICatalogWhenUserMovesIntoANewZone() async throws {
        let location = LiveFakeLocationProviding(initialCoordinate: Coordinate(latitude: 0, longitude: 0))
        let firstZonePOI = POI(id: "first-zone", name: "First Zone", coordinate: Coordinate(latitude: 0, longitude: 0.001))
        let newZonePOI = POI(id: "new-zone", name: "New Zone", coordinate: Coordinate(latitude: 0, longitude: 0.002))
        let poiProvider = SequencedPOIProviding(results: [[firstZonePOI], [newZonePOI]])
        let (viewModel, _) = makeViewModel(location: location, pois: poiProvider)
        await viewModel.loadNearbyPOIs()
        let task = Task { await viewModel.observeLiveLocationUpdates() }

        await Task.yield()
        location.yield(Coordinate(latitude: 0, longitude: 0.001))
        await Task.yield()
        location.finish()
        await task.value

        guard case .loaded(let pois) = viewModel.state else {
            return XCTFail("Expected .loaded, got \(viewModel.state)")
        }
        XCTAssertEqual(pois.map(\.id), ["new-zone"])
    }

    // MARK: - select

    func testSelectSetsLoadedContentState() async throws {
        let package = ContentPackage(
            id: "c1",
            poiID: "poi-1",
            language: "en",
            sections: [ContentSection(id: "s1", title: "Section", text: "Hello")],
            provenance: []
        )
        let (viewModel, _) = makeViewModel(content: FakeContentProviding(result: .success(package)))
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))

        await viewModel.select(poi)

        guard case .loaded(let loaded) = viewModel.contentState else {
            return XCTFail("Expected .loaded, got \(viewModel.contentState)")
        }
        XCTAssertEqual(loaded, package)
    }

    func testLoadExternalContentSetsLoadedState() async throws {
        let package = ExternalContentPackage(
            id: "e1",
            poiID: "poi-1",
            sourceURL: URL(string: "https://example.com/place")!,
            sourceTitle: "Official place",
            sourceLanguage: "fr",
            practicalInfo: ExternalPracticalInfo(
                officialWebsite: URL(string: "https://example.com/place")!,
                address: "1 avenue Exemple, 75000 Paris",
                openingHours: "Mo-Su 10:00-18:00",
                price: "12 EUR",
                phone: "+33 1 00 00 00 00"
            ),
            originalText: "Texte officiel court.",
            provenance: [Provenance(sourceKind: .institutional, retrievedAt: Date(timeIntervalSince1970: 0))]
        )
        let (viewModel, _) = makeViewModel(
            externalContent: FakeExternalContentProviding(result: .success(package))
        )
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))

        await viewModel.loadExternalContent(for: poi)

        guard case .loaded(let loaded) = viewModel.externalContentState else {
            return XCTFail("Expected .loaded, got \(viewModel.externalContentState)")
        }
        XCTAssertEqual(loaded, package)
    }

    func testLoadExternalContentPassesPOICoordinate() async throws {
        let externalProvider = CapturingExternalContentProviding()
        let (viewModel, _) = makeViewModel(externalContent: externalProvider)
        let coordinate = Coordinate(latitude: 48.8584, longitude: 2.2945)
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: coordinate)

        await viewModel.loadExternalContent(for: poi)

        let capturedCoordinate = await externalProvider.capturedCoordinateValue()
        XCTAssertEqual(capturedCoordinate, coordinate)
    }

    func testLoadExternalContentUsesSessionCacheForSamePOIAndLanguage() async throws {
        let package = ExternalContentPackage(
            id: "e1",
            poiID: "poi-1",
            sourceURL: URL(string: "https://example.com/place")!,
            sourceTitle: "Official place",
            sourceLanguage: "fr",
            practicalInfo: ExternalPracticalInfo(officialWebsite: URL(string: "https://example.com/place")!),
            originalText: "Texte officiel court.",
            provenance: []
        )
        let externalProvider = CapturingExternalContentProviding(package: package)
        let (viewModel, _) = makeViewModel(externalContent: externalProvider)
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))

        await viewModel.loadExternalContent(for: poi)
        await viewModel.loadExternalContent(for: poi)

        let callCount = await externalProvider.callCountValue()
        XCTAssertEqual(callCount, 1)
        guard case .loaded(let loaded) = viewModel.externalContentState else {
            return XCTFail("Expected .loaded, got \(viewModel.externalContentState)")
        }
        XCTAssertEqual(loaded, package)
    }

    func testSelectUsesCachedContentForTheSamePOIAndLanguage() async throws {
        let package = ContentPackage(
            id: "c1",
            poiID: "poi-1",
            language: "en",
            sections: [ContentSection(id: "s1", title: "Section", text: "Hello")],
            provenance: []
        )
        let provider = CountingContentProviding(package: package)
        let viewModel = makeViewModel(content: provider)
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))

        await viewModel.select(poi)
        await viewModel.select(poi)

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 1)
    }

    func testSelectUsesPersistedContentCacheAcrossViewModels() async throws {
        let package = ContentPackage(
            id: "c1",
            poiID: "poi-1",
            language: "en",
            sections: [ContentSection(id: "s1", title: "Section", text: "Hello")],
            provenance: []
        )
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))
        let (onlineViewModel, _) = makeViewModel(content: FakeContentProviding(result: .success(package)), userDefaults: userDefaults)
        await onlineViewModel.select(poi)

        let (offlineViewModel, _) = makeViewModel(content: FakeContentProviding(result: .failure(WGError.network("offline"))), userDefaults: userDefaults)
        await offlineViewModel.select(poi)

        guard case .loaded(let cachedPackage) = offlineViewModel.contentState else {
            return XCTFail("Expected cached package, got \(offlineViewModel.contentState)")
        }
        XCTAssertEqual(cachedPackage, package)
    }

    func testSelectSetsEmptyContentStateWhenNoContentFound() async throws {
        let (viewModel, _) = makeViewModel(content: FakeContentProviding(result: .success(nil)))
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))

        await viewModel.select(poi)

        guard case .empty = viewModel.contentState else {
            return XCTFail("Expected .empty, got \(viewModel.contentState)")
        }
    }

    func testSelectSetsFailedContentStateOnError() async throws {
        let (viewModel, _) = makeViewModel(content: FakeContentProviding(result: .failure(WGError.network("boom"))))
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))

        await viewModel.select(poi)

        guard case .failed = viewModel.contentState else {
            return XCTFail("Expected .failed, got \(viewModel.contentState)")
        }
    }

    func testSelectingANewPOIStopsInFlightPlayback() async throws {
        let package = ContentPackage(
            id: "c1",
            poiID: "poi-1",
            language: "en",
            sections: [ContentSection(id: "s1", title: "Section", text: "Hello")],
            provenance: []
        )
        let (viewModel, audio) = makeViewModel(content: FakeContentProviding(result: .success(package)))
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))
        await viewModel.select(poi)
        await viewModel.selectSection(package.sections[0])
        await viewModel.playSelectedContent()
        XCTAssertEqual(viewModel.playbackState, .playing)

        await viewModel.select(poi)

        XCTAssertEqual(viewModel.playbackState, .stopped)
        let stopCount = await audio.stopCount
        XCTAssertEqual(stopCount, 1)
    }

    func testToggleFavoritePersistsFavoritePOIs() async throws {
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))
        let (viewModel, _) = makeViewModel()

        viewModel.toggleFavorite(poi)

        XCTAssertTrue(viewModel.isFavorite(poi))
        let (reloaded, _) = makeViewModel(userDefaults: userDefaults)
        XCTAssertTrue(reloaded.isFavorite(poi))
    }

    func testSelectAddsPOIToHistory() async throws {
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))
        let (viewModel, _) = makeViewModel(content: FakeContentProviding(result: .success(nil)))

        await viewModel.select(poi)

        XCTAssertEqual(viewModel.recentPOIs.map(\.id), ["poi-1"])
    }

    func testClearHistoryRemovesPersistedRecentPOIs() async throws {
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))
        let (viewModel, _) = makeViewModel(content: FakeContentProviding(result: .success(nil)), userDefaults: userDefaults)
        await viewModel.select(poi)

        viewModel.clearHistory()

        XCTAssertEqual(viewModel.recentPOIs, [])
        let (reloaded, _) = makeViewModel(userDefaults: userDefaults)
        XCTAssertEqual(reloaded.recentPOIs, [])
    }

    func testSmartWalkPlanUsesDurationDesireAndEveningContext() async throws {
        let origin = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let viewpoint = POI(
            id: "view",
            name: "Pont viewpoint",
            coordinate: Coordinate(latitude: 48.8570, longitude: 2.3522),
            category: "view photo bridge",
            hasWikipediaArticle: true,
            imageURL: URL(string: "https://example.com/view.jpg")
        )
        let closedMuseum = POI(
            id: "museum",
            name: "Quiet museum",
            coordinate: Coordinate(latitude: 48.8571, longitude: 2.3522),
            category: "museum",
            hasWikipediaArticle: true
        )
        let (viewModel, _) = makeViewModel(
            location: FakeLocationProviding(result: .success(origin)),
            pois: FakePOIProviding(result: .success([closedMuseum, viewpoint]))
        )

        await viewModel.loadNearbyPOIs()
        viewModel.smartWalkMinutes = 30
        viewModel.walkDesire = .photoSpots
        viewModel.weatherMood = .clear
        viewModel.energyLevel = .normal

        guard case .loaded(let pois) = viewModel.state else {
            return XCTFail("Expected .loaded, got \(viewModel.state)")
        }
        let eveningContext = NearbyPOIViewModel.WalkContext(
            weather: .clear,
            energy: .normal,
            isEvening: true,
            isLowLight: true,
            isWeekend: false,
            likelyClosed: true
        )
        let plan = SmartWalkPlanner.plan(
            from: pois,
            userCoordinate: origin,
            durationMinutes: viewModel.smartWalkMinutes,
            desire: viewModel.walkDesire,
            context: eveningContext,
            favoriteIDs: []
        )

        XCTAssertEqual(plan.stops.first?.id, "view")
        XCTAssertLessThanOrEqual(plan.estimatedMinutes, 30)
    }

    func testSmartWalkPlanStartsFromRealGPSLocationWhileBrowsingAnotherPlace() async throws {
        let realLocation = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let browsedLocation = Coordinate(latitude: 52.52, longitude: 13.405)
        let nearUser = POI(
            id: "near-user",
            name: "Near user",
            coordinate: Coordinate(latitude: 48.8568, longitude: 2.3522)
        )
        let nearBrowsedPlace = POI(
            id: "near-browsed",
            name: "Near browsed place",
            coordinate: Coordinate(latitude: 52.5202, longitude: 13.405)
        )
        let (viewModel, _) = makeViewModel(
            location: FakeLocationProviding(result: .success(realLocation)),
            pois: FakePOIProviding(result: .success([nearBrowsedPlace, nearUser]))
        )
        let place = PlaceResult(id: "berlin", name: "Berlin", subtitle: "Germany", coordinate: browsedLocation)

        await viewModel.jumpToPlace(place)
        viewModel.smartWalkMinutes = 30
        let plan = viewModel.smartWalkPlan(from: [nearBrowsedPlace, nearUser])

        XCTAssertEqual(viewModel.userCoordinate, realLocation)
        XCTAssertEqual(viewModel.explorationCoordinate, browsedLocation)
        XCTAssertEqual(plan.stops.first?.id, "near-user")
    }

    func testTravelJournalSummarizesHistoryFavoritesAndExportText() async throws {
        let favorite = POI(
            id: "favorite",
            name: "Favorite bridge",
            coordinate: Coordinate(latitude: 48.8570, longitude: 2.3522),
            hasWikipediaArticle: true
        )
        let second = POI(
            id: "second",
            name: "Second stop",
            coordinate: Coordinate(latitude: 48.8580, longitude: 2.3522),
            imageURL: URL(string: "https://example.com/second.jpg")
        )
        let (viewModel, _) = makeViewModel(content: FakeContentProviding(result: .success(nil)))
        viewModel.toggleFavorite(favorite)

        await viewModel.select(second)
        await viewModel.select(favorite)

        let summary = viewModel.travelJournalSummary
        XCTAssertEqual(summary.entries.map(\.poi.id), ["favorite", "second"])
        XCTAssertEqual(summary.favoriteCount, 1)
        XCTAssertGreaterThan(summary.distanceMeters, 0)
        XCTAssertTrue(viewModel.travelJournalExportText.contains("Favorite bridge"))
    }

    func testShortReadingModeUsesACondensedText() async throws {
        let longText = "This first sentence gives the essential idea quickly. " + Array(repeating: "detail", count: 90).joined(separator: " ")
        let section = ContentSection(id: "s1", title: "Section", text: longText)
        let (viewModel, _) = makeViewModel()

        viewModel.readingMode = .short

        XCTAssertLessThan(viewModel.textForReading(section).count, longText.count)
        XCTAssertEqual(viewModel.textForReading(section), "This first sentence gives the essential idea quickly.")
        viewModel.readingMode = .complete
        XCTAssertEqual(viewModel.textForReading(section), longText)
    }

    func testQualityLabelExplainsTheInternalScoreForUsers() async throws {
        let (viewModel, _) = makeViewModel()
        let plain = POI(id: "plain", name: "Plain", coordinate: Coordinate(latitude: 0, longitude: 0))
        let documented = POI(
            id: "documented",
            name: "Documented",
            coordinate: Coordinate(latitude: 0, longitude: 0),
            category: "museum",
            imageURL: URL(string: "https://example.com/image.jpg")
        )

        XCTAssertEqual(viewModel.qualityLabel(for: plain), "Discovery")
        XCTAssertEqual(viewModel.qualityLabel(for: documented), "Must see")
    }

    func testAppStringsFollowTheSelectedLanguage() async throws {
        let (viewModel, _) = makeViewModel()

        XCTAssertEqual(viewModel.strings.nearby, "Nearby")
        viewModel.language = "fr"
        XCTAssertEqual(viewModel.strings.nearby, "Autour")
        XCTAssertEqual(viewModel.qualityLabel(for: POI(id: "plain", name: "Plain", coordinate: Coordinate(latitude: 0, longitude: 0))), "Découverte")
    }

    // MARK: - playback state machine

    func testPlaybackStateMachineTransitionsThroughPlayPauseResumeStop() async throws {
        let package = ContentPackage(
            id: "c1",
            poiID: "poi-1",
            language: "en",
            sections: [ContentSection(id: "s1", title: "Section", text: "Hello")],
            provenance: []
        )
        let (viewModel, audio) = makeViewModel(content: FakeContentProviding(result: .success(package)))
        let poi = POI(id: "poi-1", name: "POI 1", coordinate: Coordinate(latitude: 0, longitude: 0))
        await viewModel.select(poi)
        await viewModel.selectSection(package.sections[0])

        await viewModel.playSelectedContent()
        XCTAssertEqual(viewModel.playbackState, .playing)

        await viewModel.pausePlayback()
        XCTAssertEqual(viewModel.playbackState, .paused)

        await viewModel.resumePlayback()
        XCTAssertEqual(viewModel.playbackState, .playing)

        await viewModel.stopPlaying()
        XCTAssertEqual(viewModel.playbackState, .stopped)

        let played = await audio.playedAssets
        let pauseCount = await audio.pauseCount
        let resumeCount = await audio.resumeCount
        let stopCount = await audio.stopCount
        XCTAssertEqual(played.map(\.text), ["Hello"])
        XCTAssertEqual(pauseCount, 1)
        XCTAssertEqual(resumeCount, 1)
        XCTAssertEqual(stopCount, 1)
    }
}
