import SwiftUI
import UIKit

enum RemoteImageURL {
    static func thumbnailURL(for url: URL, width: Int) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name.lowercased() == "width" }
        queryItems.append(URLQueryItem(name: "width", value: String(width)))
        components.queryItems = queryItems
        return components.url ?? url
    }
}

@MainActor
private final class RemoteImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false

    private static let cache = NSCache<NSURL, UIImage>()
    private var loadedURL: URL?

    func load(_ url: URL?) async {
        guard let url else {
            loadedURL = nil
            image = nil
            isLoading = false
            return
        }

        if loadedURL == url, image != nil {
            return
        }

        if let cached = Self.cache.object(forKey: url as NSURL) {
            loadedURL = url
            image = cached
            isLoading = false
            return
        }

        loadedURL = url
        image = nil
        isLoading = true

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled else { return }
            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                isLoading = false
                return
            }
            guard let loadedImage = UIImage(data: data) else {
                isLoading = false
                return
            }
            Self.cache.setObject(loadedImage, forKey: url as NSURL)
            image = loadedImage
        } catch {
            guard !Task.isCancelled else { return }
        }

        isLoading = false
    }
}

struct RemoteImage: View {
    let url: URL?
    let placeholderSystemName: String

    @StateObject private var loader = RemoteImageLoader()

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                Rectangle()
                    .fill(.white.opacity(0.10))
                Image(systemName: placeholderSystemName)
                    .foregroundStyle(.white.opacity(0.70))
                if loader.isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.72)
                }
            }
        }
        .task(id: url) {
            await loader.load(url)
        }
    }
}
