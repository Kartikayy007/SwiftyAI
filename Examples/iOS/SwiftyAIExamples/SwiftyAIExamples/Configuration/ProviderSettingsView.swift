import SwiftUI

struct ProviderSettingsView: View {
    @Environment(ProviderSettingsStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            Form {
                Section("Provider") {
                    Picker("Provider", selection: Binding(
                        get: { store.settings.provider },
                        set: { store.selectProvider($0) }
                    )) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }

                    Picker("Model", selection: $store.settings.model) {
                        ForEach(ModelCatalog.options(for: store.settings.provider)) { option in
                            Text(option.label).tag(option.name)
                        }
                    }

                    TextField("Custom model", text: $store.settings.model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if store.settings.provider.requiresAPIKey {
                    Section("Credentials") {
                        SecureField("API key", text: $store.apiKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Button("Clear API key", role: .destructive) {
                            store.clearCredential()
                        }
                    }
                }

                if store.settings.provider.requiresAccountID {
                    Section("Cloudflare") {
                        TextField("Account ID", text: $store.settings.accountID)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }

                if store.settings.provider.supportsBaseURL {
                    Section("Ollama") {
                        TextField("Base URL", text: $store.settings.ollamaBaseURL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }

                if let error = store.lastError {
                    Section {
                        ErrorBanner(message: error)
                    }
                }
            }
            .navigationTitle("Provider Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
