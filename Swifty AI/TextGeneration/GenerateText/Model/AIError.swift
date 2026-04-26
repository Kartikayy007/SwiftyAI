import Foundation

public enum AIError: Error, Sendable {
    case networkError(Error)
    case invalidResponse
    case encodingError(Error)
    case decodingError(Error)
    case apiError(statusCode: Int, message: String)
}

extension AIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "API error \(statusCode): \(message)"
        }
    }
}
