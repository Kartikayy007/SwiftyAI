import Foundation
import Observation
import Security

@Observable
final class ProviderSettingsStore {
    var settings: ProviderSettings
    var apiKey: String
    var lastError: String?

    private let defaults: UserDefaults
    private let credentialStore: CredentialStoring
    private let settingsKey = "com.swiftyai.examples.provider-settings"

    init(
        defaults: UserDefaults = .standard,
        credentialStore: CredentialStoring = KeychainCredentialStore()
    ) {
        self.defaults = defaults
        self.credentialStore = credentialStore

        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(ProviderSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = ProviderSettings()
        }
        self.apiKey = credentialStore.credential(for: self.settings.provider) ?? ""
    }

    func selectProvider(_ provider: AIProvider) {
        if provider != settings.provider {
            settings.provider = provider
            settings.model = ModelCatalog.defaultModel(for: provider)
            apiKey = credentialStore.credential(for: provider) ?? ""
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(settings)
            defaults.set(data, forKey: settingsKey)
            if settings.provider.requiresAPIKey {
                try credentialStore.save(apiKey, for: settings.provider)
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func clearCredential() {
        do {
            try credentialStore.deleteCredential(for: settings.provider)
            apiKey = ""
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}

protocol CredentialStoring {
    func credential(for provider: AIProvider) -> String?
    func save(_ credential: String, for provider: AIProvider) throws
    func deleteCredential(for provider: AIProvider) throws
}

struct KeychainCredentialStore: CredentialStoring {
    private let service = "com.swiftyai.examples.credentials"

    func credential(for provider: AIProvider) -> String? {
        var query = baseQuery(for: provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    func save(_ credential: String, for provider: AIProvider) throws {
        if credential.isEmpty {
            try deleteCredential(for: provider)
            return
        }

        let data = Data(credential.utf8)
        var query = baseQuery(for: provider)
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError(status: addStatus) }
        } else if status != errSecSuccess {
            throw KeychainError(status: status)
        }
    }

    func deleteCredential(for provider: AIProvider) throws {
        let status = SecItemDelete(baseQuery(for: provider) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    private func baseQuery(for provider: AIProvider) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue
        ]
    }
}

struct KeychainError: LocalizedError {
    let status: OSStatus

    var errorDescription: String? {
        "Keychain operation failed with status \(status)."
    }
}
