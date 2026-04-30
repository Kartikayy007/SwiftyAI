import Foundation

public struct CohereRerankProvider: AIRerankModel {
    let baseURL: String
    let apiKey: String
    let model: String
    let session: URLSession

    public init(
        baseURL: String = "https://api.cohere.com/v1",
        apiKey: String,
        model: String,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    public func rerank(
        query: String,
        documents: [RerankDocument],
        options: RerankOptions = RerankOptions()
    ) async throws -> RerankResponse {
        guard let url = URL(string: "\(baseURL)/rerank") else {
            throw AIError.invalidResponse
        }

        let body = Request(
            model: model,
            query: query,
            documents: documents.map(Request.Document.init),
            topN: options.topN,
            returnDocuments: options.returnDocuments
        )
        let data = try await httpPost(
            url: url,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: body,
            session: session,
            options: GenerationOptions(headers: options.headers, retryPolicy: options.retryPolicy)
        )

        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return RerankResponse(
                id: decoded.id,
                model: model,
                results: decoded.results.map {
                    RerankResult(
                        index: $0.index,
                        relevanceScore: $0.relevanceScore,
                        document: $0.document
                    )
                }
            )
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.decodingError(error)
        }
    }
}

private extension CohereRerankProvider {
    struct Request: Encodable {
        let model: String
        let query: String
        let documents: [Document]
        let topN: Int?
        let returnDocuments: Bool?

        enum CodingKeys: String, CodingKey {
            case model, query, documents
            case topN = "top_n"
            case returnDocuments = "return_documents"
        }

        struct Document: Encodable {
            let document: RerankDocument

            init(_ document: RerankDocument) {
                self.document = document
            }

            func encode(to encoder: Encoder) throws {
                try document.encode(to: encoder)
            }
        }
    }

    struct Response: Decodable {
        let id: String?
        let results: [Result]

        struct Result: Decodable {
            let index: Int
            let relevanceScore: Double
            let document: RerankDocument?

            enum CodingKeys: String, CodingKey {
                case index, document, text
                case relevanceScore = "relevance_score"
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.index = try container.decode(Int.self, forKey: .index)
                self.relevanceScore = try container.decode(Double.self, forKey: .relevanceScore)
                if let document = try container.decodeIfPresent(RerankDocument.self, forKey: .document) {
                    self.document = document
                } else if let text = try container.decodeIfPresent(String.self, forKey: .text) {
                    self.document = RerankDocument(text)
                } else {
                    self.document = nil
                }
            }
        }
    }
}
