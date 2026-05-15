import Foundation

public enum AIError: Error, Sendable {
    case networkError(Error)
    case invalidResponse
    case encodingError(Error)
    case decodingError(Error)
    case apiError(statusCode: Int, message: String)
    case providerNotConfigured(String)
    case invalidModelString(String)
    case unsupportedFeature(String)
    case toolNotFound(String)
    case maxStepsExceeded(Int)
    case schemaValidationFailed([AISchemaValidationIssue])
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
        case .providerNotConfigured(let provider):
            return "Provider '\(provider)' not configured — call AI.configure { $0.\(provider)(apiKey:) } at app startup"
        case .invalidModelString(let model):
            return "Invalid model string '\(model)' — use 'provider/model' format, e.g. 'openai/gpt-4o-mini'"
        case .unsupportedFeature(let feature):
            return "Unsupported feature: \(feature)"
        case .toolNotFound(let name):
            return "Tool '\(name)' was requested but is not registered"
        case .maxStepsExceeded(let maxSteps):
            return "Tool loop exceeded maxSteps (\(maxSteps))"
        case .schemaValidationFailed(let issues):
            let details = issues.map { "\($0.path): \($0.message)" }.joined(separator: "; ")
            return "Schema validation failed: \(details)"
        }
    }
}
