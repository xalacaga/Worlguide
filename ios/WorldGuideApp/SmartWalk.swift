import Foundation
import WGCore
import WGPOI

struct SmartWalkPlan: Equatable {
    let durationMinutes: Int
    let desire: NearbyPOIViewModel.WalkDesire
    let context: NearbyPOIViewModel.WalkContext
    let stops: [POI]
    let estimatedDistanceMeters: Double
    let estimatedMinutes: Int
}

struct TravelJournalSummary: Equatable {
    let date: Date
    let entries: [TravelJournalEntry]
    let distanceMeters: Double
    let favoriteCount: Int

    var hasContent: Bool {
        entries.isEmpty == false
    }
}

struct AutoGuideSuggestion: Equatable {
    let poi: POI
    let distanceMeters: Double
}

struct OfflineAreaPack: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let createdAt: Date
    let poiCount: Int
    let contentCount: Int
}

struct TravelJournalEntry: Identifiable, Equatable {
    let id: String
    let poi: POI
    let anecdote: String
    let isFavorite: Bool
    let note: String?
}

enum SmartWalkPlanner {
    private static let walkingMetersPerMinute = 80.0
    private static let minutesPerStop = 8.0

    static func plan(
        from pois: [POI],
        userCoordinate: Coordinate?,
        durationMinutes: Int,
        desire: NearbyPOIViewModel.WalkDesire,
        context: NearbyPOIViewModel.WalkContext,
        favoriteIDs: Set<String>
    ) -> SmartWalkPlan {
        let sorted = pois.sorted {
            score($0, userCoordinate: userCoordinate, desire: desire, context: context, favoriteIDs: favoriteIDs)
                > score($1, userCoordinate: userCoordinate, desire: desire, context: context, favoriteIDs: favoriteIDs)
        }

        var stops: [POI] = []
        var previousCoordinate = userCoordinate
        var distance = 0.0
        var estimatedMinutes = 0.0
        let budget = Double(durationMinutes)

        for poi in sorted {
            let legDistance = previousCoordinate?.distanceMeters(to: poi.coordinate) ?? 0
            let candidateMinutes = estimatedMinutes + legDistance / walkingMetersPerMinute + minutesPerStop
            if candidateMinutes <= budget || stops.isEmpty {
                stops.append(poi)
                distance += legDistance
                estimatedMinutes = candidateMinutes
                previousCoordinate = poi.coordinate
            }
            if stops.count >= maxStopCount(for: durationMinutes) {
                break
            }
        }

        return SmartWalkPlan(
            durationMinutes: durationMinutes,
            desire: desire,
            context: context,
            stops: stops,
            estimatedDistanceMeters: distance,
            estimatedMinutes: Int(ceil(estimatedMinutes))
        )
    }

    static func context(
        for date: Date,
        calendar: Calendar = .current,
        weather: NearbyPOIViewModel.WeatherMood,
        energy: NearbyPOIViewModel.EnergyLevel,
        daylightOverride: Bool? = nil
    ) -> NearbyPOIViewModel.WalkContext {
        let hour = calendar.component(.hour, from: date)
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7
        let isEvening = daylightOverride.map { $0 == false } ?? (hour >= 18 || hour < 6)
        let isLowLight = daylightOverride.map { $0 == false } ?? (hour >= 20 || hour < 8)
        let likelyClosed = hour < 9 || hour >= 19

        return NearbyPOIViewModel.WalkContext(
            weather: weather,
            energy: energy,
            isEvening: isEvening,
            isLowLight: isLowLight,
            isWeekend: isWeekend,
            likelyClosed: likelyClosed
        )
    }

    private static func maxStopCount(for durationMinutes: Int) -> Int {
        switch durationMinutes {
        case ..<45: return 4
        case ..<75: return 6
        default: return 8
        }
    }

    private static func score(
        _ poi: POI,
        userCoordinate: Coordinate?,
        desire: NearbyPOIViewModel.WalkDesire,
        context: NearbyPOIViewModel.WalkContext,
        favoriteIDs: Set<String>
    ) -> Int {
        let text = "\(poi.name) \(poi.category ?? "")".lowercased()
        var value = 0

        if poi.hasWikipediaArticle { value += 14 }
        if poi.imageURL != nil { value += 10 }
        if favoriteIDs.contains(poi.id) { value += 8 }
        if let userCoordinate {
            let distance = userCoordinate.distanceMeters(to: poi.coordinate)
            if distance < 300 { value += 16 }
            else if distance < 800 { value += 10 }
            else if distance < 1_500 { value += 4 }
            else { value -= 6 }
        }

        value += desire.keywords.reduce(0) { partial, keyword in
            partial + (text.contains(keyword) ? 18 : 0)
        }

        if context.isEvening {
            value += any(["view", "panorama", "square", "bridge", "restaurant", "theater", "quartier", "district", "night", "light", "vue", "place", "pont"], in: text) ? 12 : 0
            value -= any(["museum", "church", "library", "mairie", "hôtel de ville"], in: text) && context.likelyClosed ? 8 : 0
        }
        if context.isLowLight {
            value += any(["illuminated", "light", "view", "photo", "bridge", "tower", "éclair", "vue", "tour"], in: text) ? 10 : 0
        }
        if context.weather == .rain {
            value += any(["museum", "gallery", "arcade", "covered", "eglise", "church", "musée", "galerie"], in: text) ? 12 : 0
            value -= any(["park", "garden", "square", "street art", "parc", "jardin"], in: text) ? 7 : 0
        }
        if context.weather == .hot || context.energy == .low {
            value += any(["garden", "park", "cafe", "restaurant", "shade", "jardin", "parc"], in: text) ? 8 : 0
        }
        if context.isWeekend {
            value += any(["market", "street", "quartier", "district", "marché", "rue"], in: text) ? 5 : 0
        }

        return value
    }

    private static func any(_ keywords: [String], in text: String) -> Bool {
        keywords.contains { text.contains($0) }
    }
}

enum TravelJournalBuilder {
    static func summary(from recentPOIs: [POI], favoritePOIs: [POI], notes: [String: String] = [:], date: Date = Date()) -> TravelJournalSummary {
        let favoriteIDs = Set(favoritePOIs.map(\.id))
        let entries = recentPOIs.prefix(12).map { poi in
            TravelJournalEntry(
                id: poi.id,
                poi: poi,
                anecdote: anecdote(for: poi),
                isFavorite: favoriteIDs.contains(poi.id),
                note: notes[poi.id]?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            )
        }

        var distance = 0.0
        for pair in zip(entries, entries.dropFirst()) {
            distance += pair.0.poi.coordinate.distanceMeters(to: pair.1.poi.coordinate)
        }

        return TravelJournalSummary(
            date: date,
            entries: entries,
            distanceMeters: distance,
            favoriteCount: entries.filter(\.isFavorite).count
        )
    }

    static func exportText(summary: TravelJournalSummary, strings: AppStrings) -> String {
        guard summary.hasContent else { return strings.journalEmpty }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let lines = summary.entries.enumerated().map { index, entry in
            let note = entry.note.map { " - \($0)" } ?? ""
            return "\(index + 1). \(entry.poi.name) - \(entry.anecdote)\(note)"
        }

        return """
        \(strings.travelJournal) - \(formatter.string(from: summary.date))
        \(strings.distanceWalked): \(distanceText(summary.distanceMeters))
        \(strings.favorites): \(summary.favoriteCount)

        \(lines.joined(separator: "\n"))
        """
    }

    private static func anecdote(for poi: POI) -> String {
        if poi.hasWikipediaArticle, poi.imageURL != nil {
            return "Un arrêt bien documenté, parfait pour garder une trace visuelle."
        }
        if poi.hasWikipediaArticle {
            return "Une histoire locale à relire tranquillement."
        }
        if poi.imageURL != nil {
            return "Un repère visuel ajouté à ta journée."
        }
        return "Une découverte de passage dans ton itinéraire."
    }

    private static func distanceText(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
