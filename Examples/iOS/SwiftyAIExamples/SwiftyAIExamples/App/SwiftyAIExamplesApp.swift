import SwiftUI

@main
struct SwiftyAIExamplesApp: App {
    @State private var providerStore = ProviderSettingsStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(providerStore)
        }
    }
}
