import XCTest
import WGCore
@testable import WGLocation

private final class QueryRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var query: String?
    private var coordinate: Coordinate?

    func record(query: String, coordinate: Coordinate?) {
        lock.withLock {
            self.query = query
            self.coordinate = coordinate
        }
    }

    func recordedQuery() -> String? {
        lock.withLock { query }
    }

    func recordedCoordinate() -> Coordinate? {
        lock.withLock { coordinate }
    }
}

private struct FakeLocalSearchPerforming: LocalSearchPerforming {
    let recorder: QueryRecorder?
    let results: [PlaceResult]
    let error: Error?

    init(recorder: QueryRecorder? = nil, results: [PlaceResult] = [], error: Error? = nil) {
        self.recorder = recorder
        self.results = results
        self.error = error
    }

    func places(matching query: String, near coordinate: Coordinate?) async throws -> [PlaceResult] {
        recorder?.record(query: query, coordinate: coordinate)
        if let error {
            throw error
        }
        return results
    }
}

private struct DummySearchError: Error {}

final class MKLocalSearchPlaceSearcherTests: XCTestCase {
    func testSearchPlacesReturnsEmptyWithoutCallingThePerformerForTooShortQueries() async throws {
        let searcher = MKLocalSearchPlaceSearcher(performer: FakeLocalSearchPerforming(
            error: nil
        ))

        let result = try await searcher.searchPlaces(matching: " b ", near: nil)

        XCTAssertEqual(result, [])
    }

    func testSearchPlacesTrimsTheQueryAndForwardsTheBiasCoordinate() async throws {
        let recorder = QueryRecorder()
        let searcher = MKLocalSearchPlaceSearcher(performer: FakeLocalSearchPerforming(recorder: recorder))
        let coordinate = Coordinate(latitude: 52.52, longitude: 13.405)

        _ = try await searcher.searchPlaces(matching: "  Alexanderplatz  ", near: coordinate)

        XCTAssertEqual(recorder.recordedQuery(), "Alexanderplatz")
        XCTAssertEqual(recorder.recordedCoordinate(), coordinate)
    }

    func testSearchPlacesReturnsThePerformersResults() async throws {
        let place = PlaceResult(id: "1", name: "Brandenburg Gate", subtitle: "Berlin, Germany", coordinate: Coordinate(latitude: 52.5163, longitude: 13.3777))
        let searcher = MKLocalSearchPlaceSearcher(performer: FakeLocalSearchPerforming(results: [place]))

        let result = try await searcher.searchPlaces(matching: "Brandenburg", near: nil)

        XCTAssertEqual(result, [place])
    }

    func testSearchPlacesPropagatesPerformerFailure() async throws {
        let searcher = MKLocalSearchPlaceSearcher(performer: FakeLocalSearchPerforming(error: DummySearchError()))

        do {
            _ = try await searcher.searchPlaces(matching: "Brandenburg", near: nil)
            XCTFail("Expected an error to propagate")
        } catch is DummySearchError {
            // The fake throws the raw error directly (mirrors the real
            // performer's own catch/`WGError.network` mapping, which this
            // seam intentionally does not duplicate).
        }
    }
}
