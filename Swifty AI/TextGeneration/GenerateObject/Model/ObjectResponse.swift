import Foundation

public struct ObjectResponse<T: Decodable> {
    public let object: T
    public let usage: TokenUsage?
    public let finishReason: String?
    public let model: String?
}
