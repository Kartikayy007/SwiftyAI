import Foundation

public struct ObjectResponse<T: Decodable & Sendable>: Sendable {
    public let object: T
    public let usage: TokenUsage?
    public let finishReason: String?
    public let model: String?
}
