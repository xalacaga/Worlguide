import Foundation
import WGCore
import WGLocation

public struct CompositePlaceSearcher: PlaceSearching {
    private let searchers: [PlaceSearching]

    public init(searchers: [PlaceSearching]) {
        self.searchers = searchers
    }

    public func searchPlaces(matching query: String, near coordinate: Coordinate?) async throws -> [PlaceResult] {
        var results: [[PlaceResult]] = []
        var firstError: Error?

        await withTaskGroup(of: (Int, Result<[PlaceResult], Error>).self) { group in
            for (index, searcher) in searchers.enumerated() {
                group.addTask {
                    do {
                        return (index, .success(try await searcher.searchPlaces(matching: query, near: coordinate)))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }

            var indexedResults: [(Int, [PlaceResult])] = []
            for await (index, result) in group {
                switch result {
                case .success(let searchResults):
                    indexedResults.append((index, searchResults))
                case .failure(let error):
                    firstError = firstError ?? error
                }
            }
            results = indexedResults
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }

        let deduplicatedResults = Self.deduplicate(results.flatMap { $0 })
        if deduplicatedResults.isEmpty, let firstError {
            throw firstError
        }
        return deduplicatedResults
    }

    // Keeps first-seen ordering (searcher priority), but a later duplicate
    // that carries a Wikidata QID upgrades the kept entry — otherwise
    // whichever searcher happens to run first (e.g. Apple's, which never
    // sets `wikidataID`) would silently swallow the enriched Wikidata
    // result for any place both searchers find, defeating the point of
    // combining them (docs/adr/0016 addendum).
    private static func deduplicate(_ results: [PlaceResult]) -> [PlaceResult] {
        var kept: [PlaceResult] = []
        for result in results {
            if let index = kept.firstIndex(where: { isDuplicate($0, result) }) {
                if kept[index].wikidataID == nil, result.wikidataID != nil {
                    kept[index] = result
                }
                continue
            }
            kept.append(result)
        }
        return kept
    }

    private static func isDuplicate(_ lhs: PlaceResult, _ rhs: PlaceResult) -> Bool {
        if let lhsQID = lhs.wikidataID, lhsQID == rhs.wikidataID {
            return true
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedSame
            && lhs.coordinate.distanceMeters(to: rhs.coordinate) <= 50
    }
}
