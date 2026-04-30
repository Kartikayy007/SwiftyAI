import SwiftUI

struct AppRootView: View {
    @Environment(ProviderSettingsStore.self) private var providerStore
    @State private var route: AppRoute? = .generateText
    @State private var isShowingSettings = false

    var body: some View {
        NavigationSplitView {
            List(AppRoute.allCases, selection: $route) { item in
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: item.symbolName)
                }
                .tag(item)
            }
            .navigationTitle("SwiftyAI")
            .toolbar {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Provider settings")
            }
        } detail: {
            Group {
                switch route ?? .generateText {
                case .generateText:
                    GenerateTextExampleView()
                case .streamText:
                    StreamTextExampleView()
                case .multimodal:
                    MultimodalExampleView()
                case .generateObject:
                    GenerateObjectExampleView()
                case .chat:
                    ChatExampleView()
                case .aiChatHook:
                    AIChatHookExampleView()
                case .aiCompletionHook:
                    AICompletionHookExampleView()
                case .embeddings:
                    EmbeddingsExampleView()
                case .tools:
                    ToolsExampleView()
                case .options:
                    GenerationOptionsExampleView()
                }
            }
            .navigationTitle((route ?? .generateText).title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            ProviderSettingsView()
                .environment(providerStore)
        }
    }
}
