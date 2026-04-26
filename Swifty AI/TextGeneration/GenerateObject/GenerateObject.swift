import Foundation

public func generateObject<T: Decodable & JSONSchemaConvertible & Sendable>(
    model: some AIModel,
    prompt: String,
    as type: T.Type = T.self
) async throws -> ObjectResponse<T> {
    let schema = T.jsonSchema
    let schemaData = try JSONSerialization.data(withJSONObject: schema)
    let schemaString = String(data: schemaData, encoding: .utf8) ?? "{}"

    let fullPrompt = """
    \(prompt)

    Respond with valid JSON matching this schema:
    \(schemaString)

    Return only the JSON object, no markdown, no explanation.
    """

    let response = try await model.generate(fullPrompt)
    let cleaned = stripMarkdownFences(response.text)

    guard !cleaned.isEmpty, let data = cleaned.data(using: .utf8) else {
        throw AIError.decodingError(
            DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Empty response"))
        )
    }

    do {
        let object = try JSONDecoder().decode(T.self, from: data)
        return ObjectResponse(
            object: object,
            usage: response.usage,
            finishReason: response.finishReason,
            model: response.model
        )
    } catch {
        throw AIError.decodingError(error)
    }
}

public func generateObject<T: Decodable & JSONSchemaConvertible & Sendable>(
    model: String,
    prompt: String,
    as type: T.Type = T.self
) async throws -> ObjectResponse<T> {
    let resolved = try await AIRegistry.shared.resolve(model)
    return try await generateObject(model: resolved, prompt: prompt, as: type)
}

private func stripMarkdownFences(_ text: String) -> String {
    var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("```") {
        let lines = s.components(separatedBy: "\n")
        s = lines.dropFirst().dropLast().joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return s
}
