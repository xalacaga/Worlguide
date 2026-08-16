import SwiftUI

@main
struct WorldGuideApp: App {
    @StateObject private var viewModel = CompositionRoot.makeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
