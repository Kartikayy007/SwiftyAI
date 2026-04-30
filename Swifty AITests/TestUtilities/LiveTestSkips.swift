import XCTest
@testable import Swifty_AI

func skipLiveProviderError(_ error: Error, provider: String) throws {
    guard case AIError.apiError(let statusCode, let message) = error,
          [401, 403, 429].contains(statusCode) else {
        throw error
    }

    throw XCTSkip("\(provider) live test skipped: provider returned \(statusCode): \(message)")
}

