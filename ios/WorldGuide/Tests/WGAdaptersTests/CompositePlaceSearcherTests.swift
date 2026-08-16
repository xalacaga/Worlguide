import XCTest
import WGCore
import WGLocation
@testable import WGAdapters

private struct FakePlaceSearching: PlaceSearching {
    let results: [PlaceResult]
    var error: Error?

    func searchPlaces(matching query: String, near coordinate: Coordinate?) async throws -> [PlaceResult] {
        if let error {
            throw error
        }
        return results
    }
}

private struct DummySearchError: Error {}

final class CompositePlaceSearcherTests: XCTestCase {
    /// The scenario that mattered most in practice: Apple's searcher (no
    /// `wikidataID`) and Wikidata's searcher both find the same landmark.
    /// Regardless of which searcher is listed first, the merged result must
    /// keep the Wikidata QID — otherwise `NearbyPOIViewModel.poi(from:)`
    /// never builds a content-backed POI for a place both searchers agree
    /// on, which defeats the point of combining them.
    func testSearchPlacesKeepsTheWikidataQIDWhenBothSearchersFindTheSamePlace() async throws {
        let coordinate = Coordinate(latitude: 52.7658, longitude: 13.2647)
        let appleResult = PlaceResult(id: "apple-1", name: "Sachsenhausen Memorial", subtitle: "Oranienburg, Germany", coordinate: coordinate)
        let wikidataResult = PlaceResult(id: "Q152081", name: "Sachsenhausen Memorial", subtitle: "concentration camp", coordinate: coordinate, wikidataID: "Q152081")
        let searcher = CompositePlaceSearcher(searchers: [
            FakePlaceSearching(results: [appleResult]),
            FakePlaceSearching(results: [wikidataResult]),
        ])

        let results = try await searcher.searchPlaces(matching: "Sachsenhausen", near: nil)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.wikidataID, "Q152081")
    }

    /// Same scenario with the searchers in the opposite order — the fix
    /// must not depend on which searcher happens to run first.
    func testSearchPlacesKeepsTheWikidataQIDRegardlessOfSearcherOrder() async throws {
        let coordinate = Coordinate(latitude: 52.7658, longitude: 13.2647)
        let appleResult = PlaceResult(id: "apple-1", name: "Sachsenhausen Memorial", subtitle: "Oranienburg, Germany", coordinate: coordinate)
        let wikidataResult = PlaceResult(id: "Q152081", name: "Sachsenhausen Memorial", subtitle: "concentration camp", coordinate: coordinate, wikidataID: "Q152081")
        let searcher = CompositePlaceSearcher(searchers: [
            FakePlaceSearching(results: [wikidataResult]),
            FakePlaceSearching(results: [appleResult]),
        ])

        let results = try await searcher.searchPlaces(matching: "Sachsenhausen", near: nil)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.wikidataID, "Q152081")
    }

    func testSearchPlacesKeepsOrdinaryApplePlacesWithNoWikidataMatch() async throws {
        let place = PlaceResult(id: "apple-1", name: "Nonna Café", subtitle: "Berlin", coordinate: Coordinate(latitude: 52.5001, longitude: 13.4222))
        let searcher = CompositePlaceSearcher(searchers: [
            FakePlaceSearching(results: [place]),
            FakePlaceSearching(results: []),
        ])

        let results = try await searcher.searchPlaces(matching: "Nonna", near: nil)

        XCTAssertEqual(results, [place])
    }

    func testSearchPlacesSucceedsWhenOneSearcherFailsButTheOtherReturnsResults() async throws {
        let place = PlaceResult(id: "Q1", name: "Brandenburg Gate", subtitle: nil, coordinate: Coordinate(latitude: 52.5163, longitude: 13.3777), wikidataID: "Q1")
        let searcher = CompositePlaceSearcher(searchers: [
            FakePlaceSearching(results: [], error: DummySearchError()),
            FakePlaceSearching(results: [place]),
        ])

        let results = try await searcher.searchPlaces(matching: "Brandenburg", near: nil)

        XCTAssertEqual(results, [place])
    }

    func testSearchPlacesThrowsWhenEverySearcherFails() async throws {
        let searcher = CompositePlaceSearcher(searchers: [
            FakePlaceSearching(results: [], error: DummySearchError()),
            FakePlaceSearching(results: [], error: DummySearchError()),
        ])

        do {
            _ = try await searcher.searchPlaces(matching: "anything", near: nil)
            XCTFail("Expected an error to propagate")
        } catch is DummySearchError {
            // expected
        }
    }
}
