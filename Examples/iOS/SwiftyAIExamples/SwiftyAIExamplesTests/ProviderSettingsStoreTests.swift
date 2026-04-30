import XCTest
@testable import SwiftyAIExamples

final class ProviderSettingsStoreTests: XCTestCase {
    func testSwitchingProviderSelectsDefaultModelAndCredential() throws {
        let defaults = try makeDefaults()
        let credentials = InMemoryCredentialStore()
        try credentials.save("groq-key", for: .groq)
        let store = ProviderSettingsStore(defaults: defaults, credentialStore: credentials)

        store.selectProvider(.groq)

        XCTAssertEqual(store.settings.provider, .groq)
        XCTAssertEqual(store.settings.model, ModelCatalog.defaultModel(for: .groq))
        XCTAssertEqual(store.apiKey, "groq-key")
    }

    func testSavePersistsSettingsAndCredential() throws {
        let defaults = try makeDefaults()
        let credentials = InMemoryCredentialStore()
        let store = ProviderSettingsStore(defaults: defaults, credentialStore: credentials)
        store.selectProvider(.openAI)
        store.settings.model = "gpt-4o-mini"
        store.apiKey = "test-key"

        store.save()

        let reloaded = ProviderSettingsStore(defaults: defaults, credentialStore: credentials)
        XCTAssertEqual(reloaded.settings.provider, .openAI)
        XCTAssertEqual(reloaded.settings.model, "gpt-4o-mini")
        XCTAssertEqual(reloaded.apiKey, "test-key")
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "SwiftyAIExamplesTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class InMemoryCredentialStore: CredentialStoring {
    private var values: [AIProvider: String] = [:]

    func credential(for provider: AIProvider) -> String? {
        values[provider]
    }

    func save(_ credential: String, for provider: AIProvider) throws {
        values[provider] = credential
    }

    func deleteCredential(for provider: AIProvider) throws {
        values[provider] = nil
    }
}
