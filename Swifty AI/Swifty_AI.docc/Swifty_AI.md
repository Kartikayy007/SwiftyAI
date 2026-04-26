# ``Swifty_AI``

Swifty AI is a small abstraction for text generation across multiple model providers.

The current library surface is intentionally simple:

- Create a provider that conforms to ``AIModel``.
- Call ``generateText(model:prompt:)`` with a prompt.
- Read the returned ``AIResponse`` value.

## Overview

All providers conform to ``AIModel``:

```swift
public protocol AIModel: Sendable {
    func generate(_ prompt: String) async throws -> AIResponse
}
```

For most usage, call the shared helper:

```swift
let response = try await generateText(model: model, prompt: "Explain async/await in Swift.")
print(response.text)
```

The response includes text plus optional metadata:

```swift
public struct AIResponse: Sendable {
    public let text: String
    public let model: String?
    public let usage: TokenUsage?
    public let finishReason: String?
}

public struct TokenUsage: Sendable {
    public let inputTokens: Int
    public let outputTokens: Int
}
```

## Providers

### OpenAI

```swift
let model = AIModel.openAI(
    apiKey: "sk-...",
    model: "gpt-4o"
)
```

### Anthropic

```swift
let model = AIModel.anthropic(
    apiKey: "sk-ant-...",
    model: "claude-3-5-sonnet-latest"
)
```

### Google Gemini

```swift
let model = AIModel.gemini(
    apiKey: "AIza...",
    model: "gemini-2.5-flash"
)
```

### Groq

```swift
let model = AIModel.groq(
    apiKey: "gsk_...",
    model: "llama-3.3-70b-versatile"
)
```

### OpenRouter

```swift
let model = AIModel.openRouter(
    apiKey: "sk-or-...",
    model: "meta-llama/llama-3.3-70b-instruct:free"
)
```

### Mistral

```swift
let model = AIModel.mistral(
    apiKey: "...",
    model: "mistral-large-latest"
)
```

### Cohere

Uses Cohere's OpenAI-compatibility endpoint.

```swift
let model = AIModel.cohere(
    apiKey: "...",
    model: "command-r-plus"
)
```
### Cloudflare Workers AI

Requires your Cloudflare account ID (found in the Workers dashboard).

```swift
let model = AIModel.cloudflare(
    accountID: "abc123...",
    apiKey: "...",
    model: "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
)
```

### Custom OpenAI-compatible backend

Any backend that speaks the OpenAI `/chat/completions` format:

```swift
let model = OpenAICompatibleProvider(
    baseURL: "https://your-backend.com/v1",
    apiKey: "your-key",
    model: "your-model"
)
```

## Generate Text

```swift
do {
    let response = try await generateText(
        model: model,
        prompt: "Write a two-sentence summary of Swift concurrency."
    )
    print(response.text)
    print("Tokens used:", response.usage?.outputTokens ?? 0)
} catch {
    print(error.localizedDescription)
}
```

## Error Handling

Requests throw ``AIError``:

- ``AIError/networkError(_:)`` — HTTP request failed
- ``AIError/invalidResponse`` — response missing expected fields
- ``AIError/encodingError(_:)`` — request encoding failed
- ``AIError/decodingError(_:)`` — response decoding failed
- ``AIError/apiError(statusCode:message:)`` — provider returned non-2xx status

```swift
do {
    let response = try await generateText(model: model, prompt: "Hello")
    print(response.text)
} catch let error as AIError {
    print(error.localizedDescription)
} catch {
    print(error.localizedDescription)
}
```

## Topics

### Core

- ``AIModel``
- ``AIResponse``
- ``TokenUsage``
- ``AIError``

### Generation

- ``generateText(model:prompt:)``

### Providers

- ``OpenAICompatibleProvider``
- ``AnthropicProvider``
- ``GeminiProvider``
- ``GroqProvider``
- ``OpenRouterProvider``
- ``MistralProvider``
- ``CohereProvider``
- ``CloudflareProvider``
