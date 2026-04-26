# ``Swifty_AI``

Provider-agnostic AI SDK for Apple platforms. Zero mandatory dependencies.

## Overview

Pick a provider, call `generateText`, read the response. That's it.

```swift
let model = AIModel.openAI(apiKey: "sk-...", model: "gpt-4o")

let response = try await generateText(model: model, prompt: "Explain async/await in Swift.")
print(response.text)
```

---

## Core Types

### AIModel

The protocol every provider conforms to. You rarely use this directly — use the factory methods instead.

```swift
public protocol AIModel: Sendable {
    func generate(_ prompt: String) async throws -> AIResponse
}
```

You can also conform your own type to `AIModel` for mocking or custom backends:

```swift
struct MyMockModel: AIModel {
    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "mocked", model: nil, usage: nil, finishReason: nil)
    }
}
```

### AIResponse

Returned by every `generateText` call.

```swift
public struct AIResponse: Sendable {
    public let text: String           // the generated text
    public let model: String?         // model ID echoed back by provider
    public let usage: TokenUsage?     // token counts (if provider returns them)
    public let finishReason: String?  // "stop", "length", "end_turn", etc.
}
```

Example — reading all fields:

```swift
let response = try await generateText(model: model, prompt: "Hello")

print(response.text)
print(response.model ?? "unknown model")
print(response.finishReason ?? "no reason")

if let usage = response.usage {
    print("Input tokens:", usage.inputTokens)
    print("Output tokens:", usage.outputTokens)
}
```

### TokenUsage

```swift
public struct TokenUsage: Sendable {
    public let inputTokens: Int
    public let outputTokens: Int
}
```

### AIError

All requests throw `AIError`. Catch it specifically for structured error handling:

```swift
do {
    let response = try await generateText(model: model, prompt: "Hello")
    print(response.text)
} catch AIError.apiError(let statusCode, let message) {
    print("Provider error \(statusCode): \(message)")
} catch AIError.networkError(let error) {
    print("Network failed:", error.localizedDescription)
} catch AIError.invalidResponse {
    print("Provider returned unexpected shape")
} catch AIError.decodingError(let error) {
    print("Could not decode response:", error.localizedDescription)
} catch AIError.encodingError(let error) {
    print("Could not encode request:", error.localizedDescription)
}
```

---

## streamText

Stream tokens as they are generated. Works with any provider conforming to ``AIStreamModel``.

```swift
for try await chunk in streamText(model: model, prompt: "Tell me a story.") {
    print(chunk.text, terminator: "")  // print each delta as it arrives
}
```

Each ``AIStreamChunk`` carries:
- `text` — the delta for this chunk (one or a few tokens)
- `finishReason` — non-nil only on the last chunk (`"stop"`, `"end_turn"`, `"STOP"`, etc.)
- `usage` — non-nil only on the last chunk, where the provider supports it

Accumulate the full response yourself if needed:

```swift
var fullText = ""
for try await chunk in streamText(model: model, prompt: "Explain Swift.") {
    fullText += chunk.text
    if let reason = chunk.finishReason {
        print("\nDone. Finish reason:", reason)
    }
    if let usage = chunk.usage {
        print("Tokens — in:", usage.inputTokens, "out:", usage.outputTokens)
    }
}
```

Cancellation is supported — wrapping in a `Task` and calling `.cancel()` stops the stream cleanly.

---

## generateText

The top-level function. Works with any `AIModel`.

```swift
let response = try await generateText(
    model: model,
    prompt: "Write a two-sentence summary of Swift concurrency."
)
print(response.text)
print("Tokens used:", response.usage?.outputTokens ?? 0)
```

---

## Providers

### OpenAI

Free tier: no. Models: `gpt-4o`, `gpt-4o-mini`, `o1-mini`, etc.

```swift
let model = AIModel.openAI(
    apiKey: "sk-...",
    model: "gpt-4o-mini"
)

let response = try await generateText(model: model, prompt: "What is Swift?")
print(response.text)
```

### Anthropic

Free tier: no. Models: `claude-opus-4-7`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`, etc.

```swift
let model = AIModel.anthropic(
    apiKey: "sk-ant-...",
    model: "claude-sonnet-4-6"
)

let response = try await generateText(model: model, prompt: "Explain optionals in Swift.")
print(response.text)
```

### Google Gemini

Free tier: yes. Models: `gemini-2.5-flash`, `gemini-2.5-pro`, etc.

```swift
let model = AIModel.gemini(
    apiKey: "AIza...",
    model: "gemini-2.5-flash"
)

let response = try await generateText(model: model, prompt: "What is SwiftUI?")
print(response.text)
```

### Groq

Free tier: yes. Models: `llama-3.3-70b-versatile`, `mixtral-8x7b-32768`, etc.

```swift
let model = AIModel.groq(
    apiKey: "gsk_...",
    model: "llama-3.3-70b-versatile"
)

let response = try await generateText(model: model, prompt: "Tell me a joke.")
print(response.text)
```

### OpenRouter

Free tier: yes (`:free` suffix models). Routes to 200+ models from one API key.

```swift
let model = AIModel.openRouter(
    apiKey: "sk-or-...",
    model: "meta-llama/llama-3.3-70b-instruct:free"
)

let response = try await generateText(model: model, prompt: "Summarize the Swift language.")
print(response.text)
```

### Mistral

Free tier: yes (`mistral-small-latest` has a free tier). Models: `mistral-large-latest`, `mistral-small-latest`, etc.

```swift
let model = AIModel.mistral(
    apiKey: "...",
    model: "mistral-small-latest"
)

let response = try await generateText(model: model, prompt: "What are Swift actors?")
print(response.text)
```

### Cohere

Free tier: yes. Models: `command-a-03-2025`, `command-r-plus`, etc.

```swift
let model = AIModel.cohere(
    apiKey: "...",
    model: "command-a-03-2025"
)

let response = try await generateText(model: model, prompt: "Describe Swift concurrency.")
print(response.text)
```

### Cloudflare Workers AI

Free tier: yes. Requires your account ID from the Cloudflare Workers dashboard. Models: `@cf/meta/llama-3.3-70b-instruct-fp8-fast`, etc.

```swift
let model = AIModel.cloudflare(
    accountID: "abc123...",
    apiKey: "...",
    model: "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
)

let response = try await generateText(model: model, prompt: "What is async/await?")
print(response.text)
```

### Ollama (local)

Free. Runs models on your Mac — no API key, no cloud. Requires [Ollama](https://ollama.com) installed and a model pulled (`ollama pull llama3.2`).

```swift
let model = AIModel.ollama(model: "llama3.2")

let response = try await generateText(model: model, prompt: "What is Swift?")
print(response.text)
```

Non-default host or port:

```swift
let model = AIModel.ollama(model: "llama3.2", baseURL: "http://localhost:8080/v1")
```

Popular models: `llama3.2`, `mistral`, `gemma3`, `phi4`, `qwen2.5-coder`. Run `ollama list` to see what's pulled.

### Apple Foundation Models (on-device)

Free. Uses Apple's on-device model via the `FoundationModels` framework. Requires iOS 26+ / macOS 26+, Apple Silicon, and Apple Intelligence enabled in Settings.

```swift
import FoundationModels  // iOS 26+, macOS 26+

// Check availability first
guard AppleFoundationProvider.isAvailable else {
    print("Apple Intelligence not available")
    return
}

if #available(iOS 26, macOS 26, *) {
    let model = AIModel.appleFoundation()
    let response = try await generateText(model: model, prompt: "Summarize Swift concurrency.")
    print(response.text)
}
```

Token limit: 4096 combined input + output. No usage metadata returned (Apple doesn't expose token counts).

### Custom OpenAI-compatible backend

Any backend that speaks the OpenAI `/chat/completions` format — Together AI, LM Studio, vLLM, etc.

```swift
let model = OpenAICompatibleProvider(
    baseURL: "https://your-backend.com/v1",
    apiKey: "your-key",
    model: "your-model"
)

let response = try await generateText(model: model, prompt: "Hello")
print(response.text)
```

---

## Topics

### Core

- ``AIModel``
- ``AIStreamModel``
- ``AIResponse``
- ``AIStreamChunk``
- ``TokenUsage``
- ``AIError``

### Generation

- ``generateText(model:prompt:)``
- ``streamText(model:prompt:)``

### Providers

- ``OpenAICompatibleProvider``
- ``AnthropicProvider``
- ``GeminiProvider``
- ``GroqProvider``
- ``OpenRouterProvider``
- ``MistralProvider``
- ``CohereProvider``
- ``CloudflareProvider``
- ``OllamaProvider``
- ``AppleFoundationProvider``
