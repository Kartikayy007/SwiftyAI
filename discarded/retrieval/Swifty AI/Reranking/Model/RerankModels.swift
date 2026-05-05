public struct RerankOptions: Sendable {
    public var topN: Int?
    public var returnDocuments: Bool?
    public var headers: [String: String]
    public var retryPolicy: RetryPolicy

    public init(
        topN: Int? = nil,
        returnDocuments: Bool? = nil,
        headers: [String: String] = [:],
        retryPolicy: RetryPolicy = .none
    ) {
        self.topN = topN
        self.returnDocuments = returnDocuments
        self.headers = headers
        self.retryPolicy = retryPolicy
    }
}

public struct RerankDocument: Sendable, Equatable, Codable {
    public let text: String
    public let metadata: [String: String]

    public init(_ text: String, metadata: [String: String] = [:]) {
        self.text = text
        self.metadata = metadata.filter { $0.key != "text" }
    }

    public init(text: String, metadata: [String: String] = [:]) {
        self.text = text
        self.metadata = metadata.filter { $0.key != "text" }
    }

    public init(from decoder: Decoder) throws {
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self.text = string
            self.metadata = [:]
            return
        }

        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        var metadata: [String: String] = [:]
        var text = ""

        for key in container.allKeys {
            if key.stringValue == "text" {
                text = (try? container.decode(String.self, forKey: key)) ?? ""
            } else if let value = try? container.decode(String.self, forKey: key) {
                metadata[key.stringValue] = value
            }
        }

        self.text = text
        self.metadata = metadata
    }

    public func encode(to encoder: Encoder) throws {
        if metadata.isEmpty {
            var container = encoder.singleValueContainer()
            try container.encode(text)
            return
        }

        var container = encoder.container(keyedBy: DynamicCodingKey.self)
        try container.encode(text, forKey: DynamicCodingKey("text"))
        for (key, value) in metadata where key != "text" {
            try container.encode(value, forKey: DynamicCodingKey(key))
        }
    }
}

public struct RerankResult: Sendable, Equatable {
    public let index: Int
    public let relevanceScore: Double
    public let document: RerankDocument?

    public init(index: Int, relevanceScore: Double, document: RerankDocument? = nil) {
        self.index = index
        self.relevanceScore = relevanceScore
        self.document = document
    }
}

public struct RerankResponse: Sendable, Equatable {
    public let id: String?
    public let model: String?
    public let results: [RerankResult]

    public init(id: String? = nil, model: String? = nil, results: [RerankResult]) {
        self.id = id
        self.model = model
        self.results = results
    }
}

public extension AIRerankModel where Self == CohereRerankProvider {
    static func cohere(apiKey: String, model: String) -> CohereRerankProvider {
        CohereRerankProvider(apiKey: apiKey, model: model)
    }
}

struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init(_ stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
