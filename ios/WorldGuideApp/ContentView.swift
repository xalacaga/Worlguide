import MapKit
import SwiftUI
import WGPOI
import WGLocation

/// Nearby-POI list, driven by `NearbyPOIViewModel.state` (specs/013).
struct ContentView: View {
    private enum ExplorationLayout: String, CaseIterable, Identifiable {
        case list
        case map

        var id: String { rawValue }
    }

    private enum WalkMode: String, CaseIterable, Identifiable {
        case suggested
        case custom

        var id: String { rawValue }
    }

    @ObservedObject var viewModel: NearbyPOIViewModel
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?
    @State private var layout: ExplorationLayout = .list
    @State private var walkMode: WalkMode = .suggested
    @State private var customWalkPOIs: [POI] = []
    @State private var isConfigurationPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                background
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        hero
                        controls
                        quickFilters
                        autoGuideBanner
                        content
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
            }
            .navigationTitle("WorldGuide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isConfigurationPresented = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel(viewModel.strings.configuration)
                    .tint(.white)
                }
            }
            .task(id: "\(viewModel.language)-\(Int(viewModel.radiusMeters))") {
                await viewModel.loadNearbyPOIs()
            }
            .task {
                await viewModel.observeLiveLocationUpdates()
            }
            .searchable(text: $searchText, prompt: viewModel.strings.searchPrompt)
            .sheet(isPresented: $isConfigurationPresented) {
                ConfigurationView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
            .onChange(of: searchText) { newValue in
                schedulePlaceSearch(newValue)
            }
            .onChange(of: viewModel.listMode) { _ in
                schedulePlaceSearch(searchText)
            }
            .onDisappear {
                searchTask?.cancel()
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.08, blue: 0.12),
                Color(red: 0.08, green: 0.15, blue: 0.18),
                Color(red: 0.95, green: 0.35, blue: 0.20).opacity(0.18),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.strings.exploreNow)
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(.white)
            Text(viewModel.strings.heroSubtitle)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.76))
                .lineLimit(1)
        }
        .padding(.top, 4)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(NearbyPOIViewModel.ListMode.allCases) { mode in
                        Button {
                            viewModel.listMode = mode
                        } label: {
                            Label(viewModel.strings.listModeTitle(mode), systemImage: icon(for: mode))
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 9)
                                .background(viewModel.listMode == mode ? .white.opacity(0.24) : .white.opacity(0.10))
                                .foregroundStyle(.white.opacity(viewModel.listMode == mode ? 1 : 0.78))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                layout = layout == .list ? .map : .list
            } label: {
                Image(systemName: layout == .list ? "map" : "list.bullet")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.14))
                    .foregroundStyle(.white.opacity(0.92))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(layout == .list ? viewModel.strings.map : viewModel.strings.list)
        }
        .padding(8)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NearbyPOIViewModel.POIFilter.allCases) { filter in
                    Button {
                        viewModel.poiFilter = filter
                    } label: {
                        Label(viewModel.strings.poiFilterTitle(filter), systemImage: filterIcon(filter))
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(viewModel.poiFilter == filter ? .white.opacity(0.24) : .white.opacity(0.10))
                            .foregroundStyle(.white.opacity(viewModel.poiFilter == filter ? 1 : 0.78))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var autoGuideBanner: some View {
        if let suggestion = viewModel.autoGuideSuggestion {
            HStack(spacing: 10) {
                Label(
                    viewModel.strings.autoGuideNearby(suggestion.poi.name, distance: distanceText(suggestion.distanceMeters)),
                    systemImage: "speaker.wave.2.fill"
                )
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(2)
                Spacer()
                Button {
                    Task { await viewModel.playAutoGuideSuggestion() }
                } label: {
                    Image(systemName: "play.fill")
                        .frame(width: 34, height: 34)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                Button {
                    viewModel.dismissAutoGuideSuggestion()
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 30, height: 30)
                        .background(.white.opacity(0.14))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func icon(for mode: NearbyPOIViewModel.ListMode) -> String {
        switch mode {
        case .nearby: return "location"
        case .smartWalk: return "figure.walk"
        case .journal: return "book.closed"
        case .favorites: return "heart"
        case .history: return "clock.arrow.circlepath"
        }
    }

    private func filterIcon(_ filter: NearbyPOIViewModel.POIFilter) -> String {
        switch filter {
        case .all: return "circle.grid.2x2"
        case .mustSee: return "star.fill"
        case .monuments: return "building.columns"
        case .museums: return "theatermasks"
        case .nature: return "leaf"
        case .food: return "cup.and.saucer"
        case .wikipedia: return "book"
        case .complete: return "checkmark.seal"
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.listMode {
        case .nearby:
            nearbyContent
        case .smartWalk:
            smartWalkContent
        case .journal:
            journalContent
        case .favorites:
            poiCollection(filtered(viewModel.filteredPOIs(viewModel.favoritePOIs)), emptyMessage: viewModel.strings.addFavoritesEmpty)
        case .history:
            poiCollection(filtered(viewModel.filteredPOIs(viewModel.recentPOIs)), emptyMessage: viewModel.strings.historyEmpty)
        }
    }

    @ViewBuilder
    private var smartWalkContent: some View {
        switch viewModel.state {
        case .idle, .loadingLocation, .loadingPOIs:
            loadingCard
        case .loaded(let pois):
            let basePOIs = filtered(viewModel.filteredPOIs(pois))
            walkModePicker
            switch walkMode {
            case .suggested:
                let plan = viewModel.smartWalkPlan(from: basePOIs)
                smartWalkHeader(plan)
                poiCollection(plan.stops, emptyMessage: viewModel.strings.noWalkResult)
            case .custom:
                customWalkBuilder(basePOIs)
            }
        case .failed(let message):
            offlineBanner(message)
        }
    }

    private var walkModePicker: some View {
        Picker(viewModel.strings.smartWalk, selection: $walkMode) {
            Text(viewModel.strings.suggestedWalk).tag(WalkMode.suggested)
            Text(viewModel.strings.customWalk).tag(WalkMode.custom)
        }
        .pickerStyle(.segmented)
    }

    private func smartWalkHeader(_ plan: SmartWalkPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.strings.smartWalk)
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                    Text(viewModel.strings.smartWalkSubtitle)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.74))
                }
                Spacer()
                Label("\(plan.durationMinutes) min", systemImage: "timer")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.14))
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                badge(viewModel.strings.walkDesireTitle(plan.desire), icon: "sparkles")
                badge("\(viewModel.strings.estimatedWalk) \(plan.estimatedMinutes) min", icon: "figure.walk")
                badge(distanceText(plan.estimatedDistanceMeters), icon: "point.topleft.down.curvedto.point.bottomright.up")
            }
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func customWalkBuilder(_ pois: [POI]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            CustomWalkRoutePanel(
                viewModel: viewModel,
                stops: customWalkPOIs,
                onRemove: removeFromCustomWalk,
                onMoveUp: moveCustomWalkPOIUp,
                onClear: { customWalkPOIs.removeAll() }
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(viewModel.strings.chooseWalkStops)
                    .font(.headline)
                    .foregroundStyle(.white)

                if pois.isEmpty {
                    Text(searchText.isEmpty ? viewModel.strings.noPOI : viewModel.strings.noSearchResult(searchText))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.72))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(24)
                        .background(.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        ForEach(pois) { poi in
                            CustomWalkPOIRow(
                                viewModel: viewModel,
                                poi: poi,
                                isSelected: customWalkPOIs.contains(where: { $0.id == poi.id }),
                                toggle: { toggleCustomWalkPOI(poi) }
                            )
                        }
                    }
                }
            }
        }
    }

    private var journalContent: some View {
        let summary = viewModel.travelJournalSummary
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.strings.travelJournal)
                        .font(.title3.weight(.black))
                        .foregroundStyle(.white)
                    Text("\(viewModel.strings.distanceWalked) \(distanceText(summary.distanceMeters)) · \(summary.favoriteCount) \(viewModel.strings.favorites.lowercased())")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.74))
                }
                Spacer()
                ShareLink(item: viewModel.travelJournalExportText) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.14))
                        .clipShape(Circle())
                }
                .accessibilityLabel(viewModel.strings.export)
                Button(role: .destructive) {
                    viewModel.clearHistory()
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.14))
                        .clipShape(Circle())
                }
                .disabled(summary.entries.isEmpty)
                .accessibilityLabel(viewModel.strings.clearHistory)
            }

            if summary.entries.isEmpty {
                Text(viewModel.strings.journalEmpty)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(24)
                    .background(.white.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    ForEach(summary.entries) { entry in
                        NavigationLink {
                            POIDetailView(
                                viewModel: viewModel,
                                poi: entry.poi,
                                isInCustomWalk: isInCustomWalk(entry.poi),
                                onToggleCustomWalk: { toggleCustomWalkPOI(entry.poi) }
                            )
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: entry.isFavorite ? "heart.fill" : "mappin.circle.fill")
                                    .foregroundStyle(entry.isFavorite ? .pink : .white.opacity(0.82))
                                    .frame(width: 30, height: 30)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.poi.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text(entry.anecdote)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.72))
                                        .lineLimit(2)
                                    if let note = entry.note {
                                        Text(note)
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.white.opacity(0.82))
                                            .lineLimit(2)
                                    }
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var nearbyContent: some View {
        switch viewModel.state {
        case .idle, .loadingLocation, .loadingPOIs:
            loadingCard
        case .loaded(let pois):
            if let placeName = viewModel.browsingPlaceName {
                browsingBanner(placeName)
            }
            if viewModel.browsingPlaceIsAdministrative {
                cityInsightCard(placeName: viewModel.browsingPlaceName, count: pois.count)
            }
            if let notice = viewModel.offlineNotice {
                offlineBanner(notice)
            }
            if viewModel.isSearchingPlaces {
                loadingSearchCard
            } else if let error = viewModel.placeSearchError {
                offlineBanner(error)
                poiCollection([], emptyMessage: viewModel.strings.noSearchResult(searchText))
            } else if viewModel.isPlaceSearchActive {
                placeResultsList(viewModel.placeSearchResults)
            } else {
                let displayedPOIs = filtered(viewModel.filteredPOIs(pois))
                poiCollection(displayedPOIs, emptyMessage: searchText.isEmpty ? viewModel.strings.noPOI : viewModel.strings.noSearchResult(searchText))
            }
        case .failed(let message):
            VStack(spacing: 14) {
                Label(message, systemImage: "location.slash")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                Button {
                    Task { await viewModel.loadNearbyPOIs() }
                } label: {
                    Label(viewModel.strings.retry, systemImage: "arrow.clockwise")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func offlineBanner(_ text: String) -> some View {
        Label(text, systemImage: "wifi.slash")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white.opacity(0.86))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func browsingBanner(_ placeName: String) -> some View {
        HStack(spacing: 10) {
            Label(viewModel.strings.exploringPlace(placeName), systemImage: "mappin.and.ellipse")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
                .lineLimit(1)
            Spacer()
            Button {
                Task { await viewModel.returnToMyLocation() }
            } label: {
                Label(viewModel.strings.returnToMyLocation, systemImage: "location.fill")
                    .font(.caption.weight(.bold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.22))
        }
        .padding(12)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func cityInsightCard(placeName: String?, count: Int) -> some View {
        Label(
            viewModel.strings.cityTopPlaces(placeName ?? viewModel.strings.aroundYou, count: min(count, 10)),
            systemImage: "building.2.crop.circle"
        )
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.white.opacity(0.86))
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func placeResultsList(_ places: [PlaceResult]) -> some View {
        VStack(spacing: 10) {
            ForEach(places) { place in
                Button {
                    searchText = ""
                    Task { await viewModel.jumpToPlace(place) }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.white.opacity(0.82))
                            .frame(width: 30, height: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(place.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            if let subtitle = place.subtitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.72))
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(12)
                    .background(.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            Text(viewModel.strings.loadingPlaces)
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(18)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var loadingSearchCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            Text(viewModel.strings.searchingPlaces)
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(18)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func poiCollection(_ pois: [POI], emptyMessage: String) -> some View {
        if pois.isEmpty {
            Text(emptyMessage)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(24)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            switch layout {
            case .list:
                poiList(pois)
            case .map:
                POIMapView(
                    viewModel: viewModel,
                    pois: pois,
                    isInCustomWalk: isInCustomWalk,
                    onToggleCustomWalk: toggleCustomWalkPOI
                )
            }
        }
    }

    private func poiList(_ pois: [POI]) -> some View {
        VStack(spacing: 12) {
            ForEach(pois) { poi in
                NavigationLink {
                    POIDetailView(
                        viewModel: viewModel,
                        poi: poi,
                        isInCustomWalk: isInCustomWalk(poi),
                        onToggleCustomWalk: { toggleCustomWalkPOI(poi) }
                    )
                } label: {
                    POIRow(viewModel: viewModel, poi: poi)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func filtered(_ pois: [POI]) -> [POI] {
        guard !searchText.isEmpty else { return pois }
        return pois.filter { poi in
            poi.name.localizedCaseInsensitiveContains(searchText)
                || (poi.category?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private func toggleCustomWalkPOI(_ poi: POI) {
        if let index = customWalkPOIs.firstIndex(where: { $0.id == poi.id }) {
            customWalkPOIs.remove(at: index)
        } else {
            customWalkPOIs.append(poi)
        }
    }

    private func isInCustomWalk(_ poi: POI) -> Bool {
        customWalkPOIs.contains { $0.id == poi.id }
    }

    private func removeFromCustomWalk(_ poi: POI) {
        customWalkPOIs.removeAll { $0.id == poi.id }
    }

    private func moveCustomWalkPOIUp(_ poi: POI) {
        guard let index = customWalkPOIs.firstIndex(where: { $0.id == poi.id }), index > 0 else { return }
        customWalkPOIs.swapAt(index, index - 1)
    }

    private func badge(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.bold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(0.13))
            .foregroundStyle(.white.opacity(0.84))
            .clipShape(Capsule())
    }

    private func distanceText(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }

    private func schedulePlaceSearch(_ query: String) {
        searchTask?.cancel()
        guard viewModel.listMode == .nearby else {
            viewModel.clearPlaceSearch()
            return
        }

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedQuery.count >= 2 else {
            viewModel.clearPlaceSearch()
            return
        }

        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await viewModel.searchPlaces(matching: normalizedQuery)
        }
    }
}

private struct ConfigurationView: View {
    @ObservedObject var viewModel: NearbyPOIViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(viewModel.strings.language) {
                    Picker(viewModel.strings.language, selection: $viewModel.language) {
                        ForEach(NearbyPOIViewModel.supportedLanguages) { language in
                            Text(language.displayName).tag(language.code)
                        }
                    }
                }

                Section(viewModel.strings.smartWalk) {
                    Picker(viewModel.strings.duration, selection: $viewModel.smartWalkMinutes) {
                        ForEach(NearbyPOIViewModel.walkDurationOptions) { option in
                            Text(option.title).tag(option.minutes)
                        }
                    }
                    Picker(viewModel.strings.mood, selection: $viewModel.walkDesire) {
                        ForEach(NearbyPOIViewModel.WalkDesire.allCases) { desire in
                            Text(viewModel.strings.walkDesireTitle(desire)).tag(desire)
                        }
                    }
                }

                Section(viewModel.strings.guideInWalk) {
                    Picker(viewModel.strings.guideInWalk, selection: $viewModel.guideMode) {
                        ForEach(NearbyPOIViewModel.GuideMode.allCases) { mode in
                            Text(viewModel.strings.guideModeTitle(mode)).tag(mode)
                        }
                    }
                    Picker(viewModel.strings.speechSpeed, selection: $viewModel.speechRate) {
                        ForEach(NearbyPOIViewModel.SpeechRate.allCases) { rate in
                            Text(viewModel.strings.speechRateTitle(rate)).tag(rate)
                        }
                    }
                }

                Section(viewModel.strings.offlinePack) {
                    Button {
                        Task { await viewModel.downloadOfflinePackForCurrentArea() }
                    } label: {
                        Label(viewModel.strings.downloadCurrentArea, systemImage: "arrow.down.circle")
                    }
                    if let status = viewModel.offlinePackStatusText {
                        Text(status)
                    }
                    if viewModel.offlinePacks.isEmpty == false {
                        ForEach(viewModel.offlinePacks) { pack in
                            Label("\(pack.title) · \(pack.poiCount) POI · \(pack.contentCount)", systemImage: "checkmark.circle")
                        }
                    }
                }

                Section(viewModel.strings.aroundYou) {
                    Picker(viewModel.strings.aroundYou, selection: radiusBinding) {
                        ForEach(NearbyPOIViewModel.radiusOptions) { option in
                            Text(option.title).tag(option.meters)
                        }
                    }
                    Picker(viewModel.strings.filter, selection: $viewModel.poiFilter) {
                        ForEach(NearbyPOIViewModel.POIFilter.allCases) { filter in
                            Text(viewModel.strings.poiFilterTitle(filter)).tag(filter)
                        }
                    }
                    Toggle(isOn: nearbyAlertsBinding) {
                        Label(viewModel.strings.nearbyAlerts, systemImage: viewModel.nearbyAlertsEnabled ? "bell.badge.fill" : "bell")
                    }
                }
            }
            .navigationTitle(viewModel.strings.configuration)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.strings.close) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var radiusBinding: Binding<Double> {
        Binding(
            get: { viewModel.radiusMeters },
            set: { meters in
                Task { await viewModel.setRadius(meters) }
            }
        )
    }

    private var nearbyAlertsBinding: Binding<Bool> {
        Binding(
            get: { viewModel.nearbyAlertsEnabled },
            set: { enabled in
                Task { await viewModel.setNearbyAlertsEnabled(enabled) }
            }
        )
    }

}

private struct POIMapView: View {
    @ObservedObject var viewModel: NearbyPOIViewModel
    let pois: [POI]
    let isInCustomWalk: (POI) -> Bool
    let onToggleCustomWalk: (POI) -> Void

    @State private var region: MKCoordinateRegion
    @State private var trackingMode: MapUserTrackingMode = .follow
    @State private var selectedPOIID: String?

    init(
        viewModel: NearbyPOIViewModel,
        pois: [POI],
        isInCustomWalk: @escaping (POI) -> Bool,
        onToggleCustomWalk: @escaping (POI) -> Void
    ) {
        self.viewModel = viewModel
        self.pois = pois
        self.isInCustomWalk = isInCustomWalk
        self.onToggleCustomWalk = onToggleCustomWalk
        _region = State(initialValue: POIMapRegionFactory.region(
            userCoordinate: viewModel.explorationCoordinate,
            pois: pois,
            radiusMeters: viewModel.radiusMeters
        ))
    }

    var body: some View {
        Map(
            coordinateRegion: $region,
            showsUserLocation: true,
            userTrackingMode: $trackingMode,
            annotationItems: annotations
        ) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                Button {
                    selectedPOIID = annotation.poi.id
                } label: {
                    mapMarker(for: annotation.poi)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 430)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topLeading) {
            Label(viewModel.strings.map, systemImage: "map.fill")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .foregroundStyle(.white)
                .background(.black.opacity(0.58))
                .clipShape(Capsule())
                .padding(12)
        }
        .overlay(alignment: .topTrailing) {
            if pois.count > annotations.count {
                Text("\(annotations.count)/\(pois.count)")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.48))
                    .clipShape(Capsule())
                    .padding(12)
            }
        }
        .overlay(alignment: .bottom) {
            if let selectedPOI {
                selectedPOICard(selectedPOI)
                    .padding(12)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        }
        .onAppear {
            recenter()
            enableHeadingTrackingWhenAvailable()
        }
        .onChange(of: pois.map(\.id)) { _ in recenter() }
        .onChange(of: viewModel.radiusMeters) { _ in recenter() }
        .onChange(of: viewModel.userCoordinate?.latitude) { _ in recenter() }
        .onChange(of: viewModel.userCoordinate?.longitude) { _ in recenter() }
    }

    private var annotations: [POIMapAnnotation] {
        POIMapAnnotationFactory.visibleAnnotations(userCoordinate: viewModel.explorationCoordinate, pois: pois)
    }

    private var selectedPOI: POI? {
        guard let selectedPOIID else { return nil }
        return annotations.first { $0.poi.id == selectedPOIID }?.poi
    }

    private func mapMarker(for poi: POI) -> some View {
        ZStack {
            Circle()
                .fill(viewModel.isFavorite(poi) ? Color.pink : Color.white)
                .frame(width: selectedPOIID == poi.id ? 28 : 22, height: selectedPOIID == poi.id ? 28 : 22)
                .shadow(color: .black.opacity(0.24), radius: 4, y: 2)
            Image(systemName: viewModel.isFavorite(poi) ? "heart.fill" : "circle.fill")
                .font(.system(size: selectedPOIID == poi.id ? 8 : 6, weight: .bold))
                .foregroundStyle(.black.opacity(0.74))
        }
        .accessibilityLabel(poi.name)
    }

    private func selectedPOICard(_ poi: POI) -> some View {
        NavigationLink {
            POIDetailView(
                viewModel: viewModel,
                poi: poi,
                isInCustomWalk: isInCustomWalk(poi),
                onToggleCustomWalk: { onToggleCustomWalk(poi) }
            )
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(poi.name)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                    if let distance = viewModel.distanceText(for: poi) {
                        Label(distance, systemImage: "location.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func recenter() {
        region = POIMapRegionFactory.region(
            userCoordinate: viewModel.explorationCoordinate,
            pois: pois,
            radiusMeters: viewModel.radiusMeters
        )
        if let selectedPOIID, annotations.contains(where: { $0.poi.id == selectedPOIID }) == false {
            self.selectedPOIID = nil
        }
    }

    private func enableHeadingTrackingWhenAvailable() {
        if #available(iOS 17.0, *) {
            trackingMode = .followWithHeading
        } else {
            trackingMode = .follow
        }
    }
}

private struct SearchableWhenEnabled: ViewModifier {
    let isEnabled: Bool
    @Binding var text: String
    let prompt: String

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $text, prompt: prompt)
        } else {
            content
        }
    }
}

private struct CustomWalkRoutePanel: View {
    @ObservedObject var viewModel: NearbyPOIViewModel
    let stops: [POI]
    let onRemove: (POI) -> Void
    let onMoveUp: (POI) -> Void
    let onClear: () -> Void

    @StateObject private var routeViewModel = WalkingRouteViewModel()

    private var routeTaskID: String {
        let origin = viewModel.userCoordinate.map { "\($0.latitude),\($0.longitude)" } ?? "none"
        return ([origin] + stops.map(\.id)).joined(separator: "|")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.strings.customWalk)
                        .font(.title3.weight(.black))
                    Text(viewModel.strings.customWalkSubtitle)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.74))
                }
                Spacer()
                if stops.isEmpty == false {
                    Button(role: .destructive, action: onClear) {
                        Image(systemName: "trash")
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(viewModel.strings.clearWalk)
                }
            }

            routeStatus
            routeActions

            WalkRouteMapView(
                origin: viewModel.userCoordinate,
                originLabel: viewModel.strings.departure,
                stops: stops,
                route: displayedRoute
            )
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            selectedStops
            routeLegs
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .task(id: routeTaskID) {
            await routeViewModel.load(
                origin: viewModel.userCoordinate,
                stops: stops,
                originName: viewModel.strings.youAreHere
            )
        }
    }

    @ViewBuilder
    private var routeStatus: some View {
        switch routeViewModel.state {
        case .empty:
            Label(viewModel.strings.pickAtLeastOneStop, systemImage: "plus.circle")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .tint(.white)
                Text(viewModel.strings.calculatingRoute)
                    .font(.footnote.weight(.semibold))
            }
        case .loaded(let route):
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    badge(distanceText(route.totalDistanceMeters), icon: "point.topleft.down.curvedto.point.bottomright.up")
                    badge(durationText(route.totalExpectedTravelTime), icon: "figure.walk")
                }
                if route.totalExpectedTravelTime > 90 * 60 {
                    Label(viewModel.strings.longWalkAlternative, systemImage: "exclamationmark.triangle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                }
                routeAlternatives
            }
        case .failed:
            VStack(alignment: .leading, spacing: 8) {
                Label(viewModel.strings.routeUnavailable, systemImage: "exclamationmark.triangle")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                routeAlternatives
            }
        }
    }

    @ViewBuilder
    private var routeAlternatives: some View {
        if routeViewModel.isLoadingAlternatives {
            Text(viewModel.strings.calculatingAlternatives)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
        } else {
            VStack(alignment: .leading, spacing: 6) {
                if case .loaded(let route) = routeViewModel.cyclingState {
                    routeSummary(route, title: viewModel.strings.cyclingAlternative, icon: "bicycle")
                }
                if case .loaded(let route) = routeViewModel.drivingState {
                    routeSummary(route, title: viewModel.strings.drivingAlternative, icon: "car.fill")
                }
            }
        }
    }

    private func routeSummary(_ route: WalkRoute, title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            badge(title, icon: icon)
            badge(distanceText(route.totalDistanceMeters), icon: "point.topleft.down.curvedto.point.bottomright.up")
            badge(durationText(route.totalExpectedTravelTime), icon: "timer")
        }
    }

    @ViewBuilder
    private var routeActions: some View {
        if let origin = viewModel.userCoordinate, stops.isEmpty == false {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.strings.openNextStopInMaps)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    routeActionButton(viewModel.strings.walkingDirections, icon: "figure.walk") {
                        MapDirections.openWalkingRoute(
                            origin: origin,
                            originName: routeOriginName,
                            stops: stops
                        )
                    }

                    routeActionButton(viewModel.strings.cyclingAlternative, icon: "bicycle") {
                        MapDirections.openCyclingRoute(
                            origin: origin,
                            originName: routeOriginName,
                            stops: stops
                        )
                    }

                    routeActionButton(viewModel.strings.drivingAlternative, icon: "car.fill") {
                        MapDirections.openDrivingRoute(
                            origin: origin,
                            originName: routeOriginName,
                            stops: stops
                        )
                    }

                    routeActionButton(viewModel.strings.transitDirections, icon: "tram.fill") {
                        if let nextStop = stops.first {
                            MapDirections.openTransitDirections(to: nextStop)
                        }
                    }
                }

                Label(viewModel.strings.transitToNextStop, systemImage: "info.circle")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.66))
            }
        }
    }

    private var routeOriginName: String {
        viewModel.strings.youAreHere
    }

    private func routeActionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.bold))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.white.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var selectedStops: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(stops.enumerated()), id: \.element.id) { index, poi in
                HStack(spacing: 10) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.black))
                        .frame(width: 24, height: 24)
                        .background(.white.opacity(0.16))
                        .clipShape(Circle())
                    Text(poi.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Spacer()
                    Button {
                        onMoveUp(poi)
                    } label: {
                        Image(systemName: "arrow.up")
                            .frame(width: 30, height: 30)
                    }
                    .disabled(index == 0)
                    .buttonStyle(.plain)
                    Button {
                        onRemove(poi)
                    } label: {
                        Image(systemName: "minus.circle")
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.white.opacity(index == 0 ? 1 : 0.88))
            }
        }
    }

    @ViewBuilder
    private var routeLegs: some View {
        if case .loaded(let route) = routeViewModel.state {
            VStack(alignment: .leading, spacing: 8) {
                Label(viewModel.strings.openEachTransitLeg, systemImage: "tram.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                ForEach(Array(route.legs.enumerated()), id: \.element.id) { index, leg in
                    HStack(spacing: 10) {
                        Image(systemName: "figure.walk")
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(index + 1). \(leg.fromName) → \(leg.toName)")
                                .font(.caption.weight(.semibold))
                                .lineLimit(1)
                            Text("\(distanceText(leg.distanceMeters)) · \(durationText(leg.expectedTravelTime))")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        Spacer()
                        Button {
                            MapDirections.openTransitLeg(
                                from: leg.fromCoordinate,
                                startName: leg.fromName,
                                to: leg.toCoordinate,
                                endName: leg.toName
                            )
                        } label: {
                            Image(systemName: "tram.fill")
                                .frame(width: 30, height: 30)
                                .background(.white.opacity(0.14))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(viewModel.strings.transitDirections)
                    }
                }
            }
        }
    }

    private var displayedRoute: WalkRoute? {
        if case .loaded(let route) = routeViewModel.state {
            return route
        }
        if case .loaded(let route) = routeViewModel.cyclingState {
            return route
        }
        if case .loaded(let route) = routeViewModel.drivingState {
            return route
        }
        return nil
    }

    private func badge(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.bold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(0.13))
            .foregroundStyle(.white.opacity(0.84))
            .clipShape(Capsule())
    }

    private func distanceText(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        "\(Int(ceil(seconds / 60))) min"
    }
}

private struct CustomWalkPOIRow: View {
    @ObservedObject var viewModel: NearbyPOIViewModel
    let poi: POI
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            POIRow(viewModel: viewModel, poi: poi)
            Button(action: toggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3.weight(.bold))
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.14))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSelected ? viewModel.strings.removeFromWalk : viewModel.strings.addToWalk)
        }
    }
}

private struct POIRow: View {
    @ObservedObject var viewModel: NearbyPOIViewModel
    let poi: POI

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(poi.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Image(systemName: viewModel.isFavorite(poi) ? "heart.fill" : "chevron.right")
                        .foregroundStyle(viewModel.isFavorite(poi) ? .pink : .white.opacity(0.5))
                }

                HStack(spacing: 8) {
                    if let category = poi.category, !category.isEmpty {
                        badge(category, icon: "sparkles")
                    }
                    if let distance = viewModel.distanceText(for: poi) {
                        badge(distance, icon: "location")
                    }
                    if poi.hasWikipediaArticle {
                        badge("Wikipedia", icon: "w.circle.fill")
                    }
                    badge(viewModel.qualityLabel(for: poi), icon: "bolt.fill")
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var thumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.12))
            RemoteImage(
                url: poi.imageURL.map { RemoteImageURL.thumbnailURL(for: $0, width: 240) },
                placeholderSystemName: "map"
            )
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func badge(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.white.opacity(0.13))
            .foregroundStyle(.white.opacity(0.84))
            .clipShape(Capsule())
    }
}
