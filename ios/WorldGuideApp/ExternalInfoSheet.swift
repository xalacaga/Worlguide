import SwiftUI
import WGCore
import WGContent
import WGPOI

#if canImport(Translation) && canImport(_Translation_SwiftUI)
import Translation
import _Translation_SwiftUI
#endif

struct ExternalInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: NearbyPOIViewModel
    let poi: POI

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.07, blue: 0.10).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 14) {
                    backButton
                    content
                }
                    .padding(18)
            }
            .navigationTitle(viewModel.strings.officialInfo)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label(viewModel.strings.back, systemImage: "chevron.left")
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Label(viewModel.strings.back, systemImage: "chevron.left")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.black)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.externalContentState {
        case .idle, .loading:
            VStack(spacing: 14) {
                ProgressView()
                    .tint(.white)
                Text(viewModel.strings.loadingOfficialInfo)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let package):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sourceHeader(package)
                    practicalInfo(package.practicalInfo)
                    translatedText(package)
                    sourcesView(package.provenance)
                }
            }
        case .empty:
            VStack(spacing: 18) {
                Spacer()
                Label(viewModel.strings.noOfficialInfo, systemImage: "building.columns")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
                if let searchURL = OnlineSearch.searchURL(for: poi) {
                    Link(destination: searchURL) {
                        Label(viewModel.strings.searchOnline, systemImage: "magnifyingglass")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .foregroundStyle(.black)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let text):
            message(text, icon: "wifi.exclamationmark")
        }
    }

    private func sourceHeader(_ package: ExternalContentPackage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(viewModel.strings.officialWebsite, systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.mint)
            Text(package.sourceTitle)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Link(package.sourceURL.host ?? package.sourceURL.absoluteString, destination: package.sourceURL)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func practicalInfo(_ info: ExternalPracticalInfo) -> some View {
        let rows = practicalRows(info)
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.strings.practicalInfo)
                    .font(.headline)
                    .foregroundStyle(.white)
                ForEach(rows) { row in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: row.icon)
                            .foregroundStyle(.mint)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(row.title)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.62))
                            if let url = row.url {
                                Link(row.value, destination: url)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            } else {
                                Text(row.value)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    @ViewBuilder
    private func translatedText(_ package: ExternalContentPackage) -> some View {
        if #available(iOS 18.0, *) {
            AutomaticTranslatedText(
                package: package,
                targetLanguageCode: viewModel.language,
                strings: viewModel.strings
            )
        } else {
            TextCard(
                title: viewModel.strings.originalText,
                subtitle: package.sourceLanguage?.uppercased(),
                text: package.originalText
            )
        }
    }

    private func sourcesView(_ provenance: [Provenance]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(viewModel.strings.sources, systemImage: "building.columns")
                .font(.headline)
                .foregroundStyle(.white)
            ForEach(Array(provenance.enumerated()), id: \.offset) { _, source in
                Text(viewModel.strings.sourceTitle(source.sourceKind))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func message(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.white.opacity(0.82))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func practicalRows(_ info: ExternalPracticalInfo) -> [PracticalInfoRow] {
        var rows: [PracticalInfoRow] = []
        if let website = info.officialWebsite {
            rows.append(PracticalInfoRow(
                title: viewModel.strings.officialWebsite,
                value: website.host ?? website.absoluteString,
                icon: "safari",
                url: website
            ))
        }
        if let address = info.address {
            rows.append(PracticalInfoRow(title: viewModel.strings.address, value: address, icon: "mappin.and.ellipse"))
        }
        if let openingHours = info.openingHours {
            rows.append(PracticalInfoRow(title: viewModel.strings.openingHours, value: openingHours, icon: "clock"))
        }
        if let price = info.price {
            rows.append(PracticalInfoRow(title: viewModel.strings.price, value: price, icon: "ticket"))
        }
        if let phone = info.phone {
            rows.append(PracticalInfoRow(title: viewModel.strings.phone, value: phone, icon: "phone"))
        }
        return rows
    }
}

private struct PracticalInfoRow: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    var url: URL?
}

private struct TextCard: View {
    let title: String
    let subtitle: String?
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.white)
                        .clipShape(Capsule())
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                ForEach(formattedParagraphs, id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.body)
                        .lineSpacing(5)
                        .foregroundStyle(.white.opacity(0.86))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var formattedParagraphs: [String] {
        let paragraphs = text
            .components(separatedBy: "\n\n")
            .map { $0.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return paragraphs.isEmpty ? [text] : paragraphs
    }
}

#if canImport(Translation) && canImport(_Translation_SwiftUI)
@available(iOS 18.0, *)
private struct AutomaticTranslatedText: View {
    let package: ExternalContentPackage
    let targetLanguageCode: String
    let strings: AppStrings

    @State private var translatedText: String?
    @State private var translationFailed = false

    var body: some View {
        TextCard(
            title: translatedText == nil ? strings.originalText : strings.translatedAutomatically,
            subtitle: translationSubtitle,
            text: translatedText ?? package.originalText
        )
        .translationTask(source: sourceLanguage, target: targetLanguage) { session in
            guard shouldTranslate else { return }
            do {
                let response = try await session.translate(package.originalText)
                translatedText = response.targetText
            } catch {
                translationFailed = true
            }
        }
    }

    private var sourceLanguage: Locale.Language? {
        package.sourceLanguage.map { Locale.Language(identifier: $0) }
    }

    private var targetLanguage: Locale.Language? {
        Locale.Language(identifier: targetLanguageCode)
    }

    private var shouldTranslate: Bool {
        guard let source = package.sourceLanguage?.lowercased() else { return true }
        let target = targetLanguageCode.lowercased()
        return source != target && !target.hasPrefix("\(source)-")
    }

    private var translationSubtitle: String? {
        if translationFailed {
            return package.sourceLanguage?.uppercased()
        }
        return translatedText == nil ? package.sourceLanguage?.uppercased() : targetLanguageCode.uppercased()
    }
}
#else
@available(iOS 18.0, *)
private struct AutomaticTranslatedText: View {
    let package: ExternalContentPackage
    let targetLanguageCode: String
    let strings: AppStrings

    var body: some View {
        TextCard(title: strings.originalText, subtitle: package.sourceLanguage?.uppercased(), text: package.originalText)
    }
}
#endif
