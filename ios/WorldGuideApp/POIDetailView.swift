import SwiftUI
import WGPOI
import WGContent
import WGCore

/// Selected POI's content + playback controls (specs/013). Shows a list
/// of themes first, per docs/adr/0015 — the user picks one instead of
/// the app reading the whole article start to finish.
struct POIDetailView: View {
    @ObservedObject var viewModel: NearbyPOIViewModel
    let poi: POI
    let isInCustomWalk: Bool
    let onToggleCustomWalk: (() -> Void)?
    @State private var showsExternalInfo = false

    init(
        viewModel: NearbyPOIViewModel,
        poi: POI,
        isInCustomWalk: Bool = false,
        onToggleCustomWalk: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.poi = poi
        self.isInCustomWalk = isInCustomWalk
        self.onToggleCustomWalk = onToggleCustomWalk
    }

    var body: some View {
        ZStack {
            background
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        imageHeader
                        titleBlock

                        switch viewModel.contentState {
                        case .loading:
                            loadingCard
                        case .loaded(let package):
                            if package.language != viewModel.language {
                                fallbackLanguageNotice(package.language)
                            }
                            if let section = selectedSection(in: package) {
                                selectedSectionView(section, package: package)
                            } else {
                                themeList(package.sections)
                                sourcesView(package.provenance)
                            }
                        case .empty:
                            messageCard(viewModel.strings.noContent, icon: "text.page.slash")
                        case .failed(let message):
                            messageCard(message, icon: "wifi.exclamationmark")
                        }
                    }
                    .frame(width: max(geometry.size.width - 36, 0), alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                }
            }
        }
        .navigationTitle(poi.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: viewModel.language) {
            await viewModel.select(poi)
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.07, blue: 0.10),
                Color(red: 0.10, green: 0.12, blue: 0.18),
                Color(red: 0.05, green: 0.30, blue: 0.25).opacity(0.42),
            ],
            startPoint: .top,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var imageHeader: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: displayImageURL, placeholderSystemName: "sparkles")

            HStack {
                Label(viewModel.distanceText(for: poi) ?? viewModel.strings.aroundYou, systemImage: "location.fill")
                Spacer()
                Button {
                    viewModel.toggleFavorite(poi)
                } label: {
                    Image(systemName: viewModel.isFavorite(poi) ? "heart.fill" : "heart")
                        .font(.headline)
                        .frame(width: 38, height: 38)
                        .background(.black.opacity(0.32))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.55, contentMode: .fit)
        .frame(maxHeight: 230)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .clipped()
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Text(poi.name)
                    .font(.system(size: 30, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let category = poi.category, !category.isEmpty {
                    Label(category, systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.76))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                qualityPill
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Picker(viewModel.strings.reading, selection: $viewModel.readingMode) {
                ForEach(NearbyPOIViewModel.ReadingMode.allCases) { mode in
                    Text(viewModel.strings.readingModeTitle(mode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 10) {
                if let onToggleCustomWalk {
                    Button(action: onToggleCustomWalk) {
                        Label(
                            isInCustomWalk ? viewModel.strings.removeFromWalk : viewModel.strings.addToWalk,
                            systemImage: isInCustomWalk ? "checkmark.circle.fill" : "plus.circle.fill"
                        )
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.black)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                VStack(spacing: 10) {
                    walkingDirectionsButton
                    transitDirectionsButton
                }

                Button {
                    showsExternalInfo = true
                    Task { await viewModel.loadExternalContent(for: poi) }
                } label: {
                    Label(viewModel.strings.officialInfo, systemImage: "building.columns")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(.white.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .sheet(isPresented: $showsExternalInfo) {
            ExternalInfoSheet(viewModel: viewModel, poi: poi)
        }
    }

    private var qualityPill: some View {
        Label(viewModel.qualityLabel(for: poi), systemImage: "bolt.fill")
            .font(.caption.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .foregroundStyle(.black)
            .background(.white)
            .clipShape(Capsule())
    }

    private var walkingDirectionsButton: some View {
        Button {
            MapDirections.openWalkingDirections(to: poi)
        } label: {
            Label(viewModel.strings.walkingDirections, systemImage: "figure.walk")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var transitDirectionsButton: some View {
        Button {
            MapDirections.openTransitDirections(to: poi)
        } label: {
            Label(viewModel.strings.transitDirections, systemImage: "tram.fill")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    /// The POI's own (Wikidata) image if it has one, else the
    /// content-level Wikipedia fallback once loaded (docs/adr/0015).
    private var displayImageURL: URL? {
        if let poiImage = poi.imageURL {
            return poiImage
        }
        if case .loaded(let package) = viewModel.contentState {
            return package.imageURL
        }
        return nil
    }

    private func selectedSection(in package: ContentPackage) -> ContentSection? {
        guard let id = viewModel.selectedSectionID else { return nil }
        return package.sections.first { $0.id == id }
    }

    /// Content fell back to a different Wikipedia edition
    /// (`WikipediaContentProvider`'s English fallback) — say so, since
    /// otherwise a user picking "Français" would get no explanation for
    /// why the themes and article text below are in English.
    private func fallbackLanguageNotice(_ contentLanguage: String) -> some View {
        let displayName = NearbyPOIViewModel.supportedLanguages
            .first { $0.code == contentLanguage }?.displayName ?? contentLanguage
        return Label(viewModel.strings.fallbackLanguageNotice(displayName), systemImage: "globe")
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.76))
            .padding(12)
            .background(.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func themeList(_ sections: [ContentSection]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.strings.chooseAngle)
                .font(.title3.bold())
                .foregroundStyle(.white)
            ForEach(sections) { section in
                HStack(alignment: .top, spacing: 12) {
                    sectionPlaybackButton(section)
                        .padding(.top, 2)
                        .frame(width: 38)

                    Button {
                        Task { await viewModel.selectSection(section) }
                    } label: {
                        HStack(alignment: .center, spacing: 10) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(section.title)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                Text(section.text)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.62))
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.white.opacity(0.55))
                                .frame(width: 14)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private func selectedSectionView(_ section: ContentSection, package: ContentPackage) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                Task { await viewModel.deselectSection() }
            } label: {
                Label(viewModel.strings.themes, systemImage: "chevron.left")
            }
            .font(.headline)
            .foregroundStyle(.white)

            HStack(alignment: .top, spacing: 12) {
                sectionPlaybackButton(section)
                    .padding(.top, 2)
                    .frame(width: 38)

                Text(section.title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(viewModel.textForReading(section))
                .font(.body)
                .lineSpacing(4)
                .foregroundStyle(.white.opacity(0.84))
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            sourcesView(package.provenance)
        }
    }

    private func sectionPlaybackButton(_ section: ContentSection) -> some View {
        Button {
            Task { await togglePlayback(for: section) }
        } label: {
            Image(systemName: playbackIcon(for: section))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(playbackForeground(for: section))
                .frame(width: 38, height: 38)
                .background(playbackBackground(for: section))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(playbackAccessibilityLabel(for: section))
    }

    private func togglePlayback(for section: ContentSection) async {
        if viewModel.selectedSectionID == section.id {
            switch viewModel.playbackState {
            case .playing:
                await viewModel.pausePlayback()
            case .paused:
                await viewModel.resumePlayback()
            case .stopped:
                await viewModel.play(section)
            }
        } else {
            await viewModel.play(section)
        }
    }

    private func playbackIcon(for section: ContentSection) -> String {
        guard viewModel.selectedSectionID == section.id else { return "speaker.wave.2.fill" }
        switch viewModel.playbackState {
        case .playing:
            return "pause.fill"
        case .paused:
            return "play.fill"
        case .stopped:
            return "speaker.wave.2.fill"
        }
    }

    private func playbackForeground(for section: ContentSection) -> Color {
        viewModel.selectedSectionID == section.id && viewModel.playbackState != .stopped ? .black : .white
    }

    private func playbackBackground(for section: ContentSection) -> Color {
        viewModel.selectedSectionID == section.id && viewModel.playbackState != .stopped ? .white : .white.opacity(0.14)
    }

    private func playbackAccessibilityLabel(for section: ContentSection) -> String {
        guard viewModel.selectedSectionID == section.id else { return viewModel.strings.play }
        switch viewModel.playbackState {
        case .playing:
            return viewModel.strings.pause
        case .paused:
            return viewModel.strings.resume
        case .stopped:
            return viewModel.strings.play
        }
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            Text(viewModel.strings.loadingContent)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func messageCard(_ message: String, icon: String) -> some View {
        Label(message, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.white.opacity(0.78))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func sourcesView(_ provenance: [Provenance]) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                if provenance.isEmpty {
                    Text(viewModel.strings.noSources)
                } else {
                    ForEach(Array(provenance.enumerated()), id: \.offset) { _, source in
                        HStack {
                            Label(viewModel.strings.sourceTitle(source.sourceKind), systemImage: sourceIcon(source.sourceKind))
                                .lineLimit(2)
                            Spacer()
                            if let license = source.license {
                                Text(license)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.72))
            .padding(.top, 8)
        } label: {
            Label(viewModel.strings.sources, systemImage: "checkmark.seal")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .tint(.white)
    }

    private func sourceIcon(_ sourceKind: Provenance.SourceKind) -> String {
        switch sourceKind {
        case .wikidata: return "network"
        case .wikipedia: return "book"
        case .openStreetMap: return "map"
        case .institutional: return "building.columns"
        }
    }
}
