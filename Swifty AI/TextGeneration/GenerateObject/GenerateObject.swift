import Foundation

public func generateObject<T: Decodable & JSONSchemaConvertible>(
    model: some AIModel,
    prompt: String,
    as type: T.Type = T.self,
    options: GenerationOptions = GenerationOptions()
) async throws -> ObjectResponse<T> {
    try await generateObject(
        model: model,
        prompt: prompt,
        output: Output<T>(schema: AISchema(jsonSchema: T.jsonSchema)),
        options: options
    )
}

public func generateObject<T: Decodable & JSONSchemaConvertible>(
    model: some AIModel,
    prompt: [AIMessageContent],
    as type: T.Type = T.self,
    options: GenerationOptions = GenerationOptions()
) async throws -> ObjectResponse<T> {
    try await generateObject(
        model: model,
        prompt: prompt,
        output: Output<T>(schema: AISchema(jsonSchema: T.jsonSchema)),
        options: options
    )
}

public func generateObject<T: Decodable & JSONSchemaConvertible>(
    model: String,
    prompt: String,
    as type: T.Type = T.self,
    options: GenerationOptions = GenerationOptions()
) async throws -> ObjectResponse<T> {
    let resolved = try await AIRegistry.shared.resolve(model)
    return try await generateObject(model: resolved, prompt: prompt, as: type, options: options)
}

public func generateObject<T: Decodable & JSONSchemaConvertible>(
    model: String,
    prompt: [AIMessageContent],
    as type: T.Type = T.self,
    options: GenerationOptions = GenerationOptions()
) async throws -> ObjectResponse<T> {
    let resolved = try await AIRegistry.shared.resolve(model)
    return try await generateObject(model: resolved, prompt: prompt, as: type, options: options)
}

public func generateObject<T: Decodable>(
    model: some AIModel,
    prompt: String,
    output: Output<T>,
    options: GenerationOptions = GenerationOptions()
) async throws -> ObjectResponse<T> {
    let fullPrompt = try structuredOutputPrompt(prompt: prompt, schema: output.schema)
    let response = try await model.generate(fullPrompt, options: options)
    let data = try cleanedJSONData(response.text)
    try validate(data: data, schema: output.schema)

    do {
        let object = try output.decode(data)
        return ObjectResponse(
            object: object,
            usage: response.usage,
            finishReason: response.finishReason,
            model: response.model
        )
    } catch let error as AIError {
        throw error
    } catch {
        throw AIError.decodingError(error)
    }
}

public func generateObject<T: Decodable>(
    model: some AIModel,
    prompt: [AIMessageContent],
    output: Output<T>,
    options: GenerationOptions = GenerationOptions()
) async throws -> ObjectResponse<T> {
    let fullPrompt = try structuredOutputPrompt(prompt: prompt, schema: output.schema)
    let response = try await model.generate(fullPrompt, options: options)
    let data = try cleanedJSONData(response.text)
    try validate(data: data, schema: output.schema)

    do {
        let object = try output.decode(data)
        return ObjectResponse(
            object: object,
            usage: response.usage,
            finishReason: response.finishReason,
            model: response.model
        )
    } catch let error as AIError {
        throw error
    } catch {
        throw AIError.decodingError(error)
    }
}

public func generateObject<T: Decodable>(
    model: String,
    prompt: String,
    output: Output<T>,
    options: GenerationOptions = GenerationOptions()
) async throws -> ObjectResponse<T> {
    let resolved = try await AIRegistry.shared.resolve(model)
    return try await generateObject(model: resolved, prompt: prompt, output: output, options: options)
}

public func generateObject<T: Decodable>(
    model: String,
    prompt: [AIMessageContent],
    output: Output<T>,
    options: GenerationOptions = GenerationOptions()
) async throws -> ObjectResponse<T> {
    let resolved = try await AIRegistry.shared.resolve(model)
    return try await generateObject(model: resolved, prompt: prompt, output: output, options: options)
}

public func streamObject<T: Decodable>(
    model: some AIStreamModel,
    prompt: String,
    output: Output<T>,
    options: GenerationOptions = GenerationOptions(),
    onPartial: ((ObjectStreamChunk<T>) -> Void)? = nil,
    onFinish: ((ObjectResponse<T>) -> Void)? = nil
) -> AsyncThrowingStream<ObjectStreamChunk<T>, Error> {
    AsyncThrowingStream { continuation in
        Task {
            var fullText = ""
            var lastUsage: TokenUsage?
            var lastFinishReason: String?

            do {
                let fullPrompt = try structuredOutputPrompt(prompt: prompt, schema: output.schema)
                for try await chunk in model.stream(fullPrompt, options: options) {
                    if Task.isCancelled {
                        continuation.finish()
                        return
                    }

                    fullText += chunk.text
                    lastUsage = chunk.usage ?? lastUsage
                    lastFinishReason = chunk.finishReason ?? lastFinishReason

                    let partial = partialChunk(
                        textDelta: chunk.text,
                        accumulatedText: fullText,
                        output: output,
                        usage: chunk.usage,
                        finishReason: chunk.finishReason
                    )
                    onPartial?(partial)
                    continuation.yield(partial)
                }

                let data = try cleanedJSONData(fullText)
                try validate(data: data, schema: output.schema)
                let object = try output.decode(data)
                let response = ObjectResponse(object: object, usage: lastUsage, finishReason: lastFinishReason, model: nil)
                let final = ObjectStreamChunk<T>(
                    partialJSON: stripMarkdownFences(fullText),
                    partialObject: object,
                    object: object,
                    usage: lastUsage,
                    finishReason: lastFinishReason
                )
                onFinish?(response)
                continuation.yield(final)
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

public func streamObject<T: Decodable>(
    model: some AIStreamModel,
    prompt: [AIMessageContent],
    output: Output<T>,
    options: GenerationOptions = GenerationOptions(),
    onPartial: ((ObjectStreamChunk<T>) -> Void)? = nil,
    onFinish: ((ObjectResponse<T>) -> Void)? = nil
) -> AsyncThrowingStream<ObjectStreamChunk<T>, Error> {
    AsyncThrowingStream { continuation in
        Task {
            var fullText = ""
            var lastUsage: TokenUsage?
            var lastFinishReason: String?

            do {
                let fullPrompt = try structuredOutputPrompt(prompt: prompt, schema: output.schema)
                for try await chunk in model.stream(fullPrompt, options: options) {
                    if Task.isCancelled {
                        continuation.finish()
                        return
                    }

                    fullText += chunk.text
                    lastUsage = chunk.usage ?? lastUsage
                    lastFinishReason = chunk.finishReason ?? lastFinishReason

                    let partial = partialChunk(
                        textDelta: chunk.text,
                        accumulatedText: fullText,
                        output: output,
                        usage: chunk.usage,
                        finishReason: chunk.finishReason
                    )
                    onPartial?(partial)
                    continuation.yield(partial)
                }

                let data = try cleanedJSONData(fullText)
                try validate(data: data, schema: output.schema)
                let object = try output.decode(data)
                let response = ObjectResponse(object: object, usage: lastUsage, finishReason: lastFinishReason, model: nil)
                let final = ObjectStreamChunk<T>(
                    partialJSON: stripMarkdownFences(fullText),
                    partialObject: object,
                    object: object,
                    usage: lastUsage,
                    finishReason: lastFinishReason
                )
                onFinish?(response)
                continuation.yield(final)
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

public func streamObject<T: Decodable>(
    model: String,
    prompt: String,
    output: Output<T>,
    options: GenerationOptions = GenerationOptions(),
    onPartial: ((ObjectStreamChunk<T>) -> Void)? = nil,
    onFinish: ((ObjectResponse<T>) -> Void)? = nil
) -> AsyncThrowingStream<ObjectStreamChunk<T>, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                let resolved = try await AIRegistry.shared.resolve(model)
                for try await chunk in streamObject(
                    model: resolved,
                    prompt: prompt,
                    output: output,
                    options: options,
                    onPartial: onPartial,
                    onFinish: onFinish
                ) {
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

public func streamObject<T: Decodable>(
    model: String,
    prompt: [AIMessageContent],
    output: Output<T>,
    options: GenerationOptions = GenerationOptions(),
    onPartial: ((ObjectStreamChunk<T>) -> Void)? = nil,
    onFinish: ((ObjectResponse<T>) -> Void)? = nil
) -> AsyncThrowingStream<ObjectStreamChunk<T>, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                let resolved = try await AIRegistry.shared.resolve(model)
                for try await chunk in streamObject(
                    model: resolved,
                    prompt: prompt,
                    output: output,
                    options: options,
                    onPartial: onPartial,
                    onFinish: onFinish
                ) {
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

func structuredOutputPrompt(prompt: String, schema: AISchema) throws -> String {
    return """
    \(prompt)

    \(try structuredOutputInstruction(schema: schema))
    """
}

func structuredOutputPrompt(prompt: [AIMessageContent], schema: AISchema) throws -> [AIMessageContent] {
    var parts = prompt
    parts.append(.text(try structuredOutputInstruction(schema: schema)))
    return parts
}

private func structuredOutputInstruction(schema: AISchema) throws -> String {
    let schemaData = try JSONSerialization.data(withJSONObject: schema.jsonSchema, options: [.sortedKeys])
    let schemaString = String(data: schemaData, encoding: .utf8) ?? "{}"

    return """
    Respond with valid JSON matching this schema:
    \(schemaString)

    Return only the JSON value, no markdown, no explanation.
    """
}

func cleanedJSONData(_ text: String) throws -> Data {
    let cleaned = stripMarkdownFences(text)
    guard !cleaned.isEmpty, let data = cleaned.data(using: .utf8) else {
        throw AIError.decodingError(
            DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Empty response"))
        )
    }
    return data
}

func validate(data: Data, schema: AISchema) throws {
    let value = try JSONSerialization.jsonObject(with: data)
    let issues = schema.validate(value)
    if !issues.isEmpty {
        throw AIError.schemaValidationFailed(issues)
    }
}

func partialChunk<T: Decodable>(
    textDelta: String,
    accumulatedText: String,
    output: Output<T>,
    usage: TokenUsage?,
    finishReason: String?
) -> ObjectStreamChunk<T> {
    let partialJSON = stripMarkdownFences(accumulatedText)
    let partialObject = partialJSON.data(using: .utf8).flatMap { try? output.decode($0) }
    let validationIssues: [AISchemaValidationIssue]
    if let data = partialJSON.data(using: .utf8),
       let value = try? JSONSerialization.jsonObject(with: data) {
        validationIssues = output.schema.validate(value)
    } else {
        validationIssues = []
    }

    return ObjectStreamChunk(
        textDelta: textDelta,
        partialJSON: partialJSON,
        partialObject: partialObject,
        object: nil,
        usage: usage,
        finishReason: finishReason,
        validationIssues: validationIssues
    )
}

func stripMarkdownFences(_ text: String) -> String {
    var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if s.hasPrefix("```") {
        let lines = s.components(separatedBy: "\n")
        s = lines.dropFirst().dropLast().joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return s
}
