# ``Swifty_AI``

Provider-agnostic AI SDK for Apple platforms. Zero mandatory dependencies.

## Overview

Configure once, use everywhere — no API key at every call site.

```swift
// AppDelegate / @main — once
AI.configure {
    $0.openAI(apiKey: "sk-...")
    $0.anthropic(apiKey: "sk-ant-...")
}

// Anywhere in your app
let response = try await generateText(model: "openai/gpt-4o-mini", prompt: "Explain async/await in Swift.")
print(response.text)
```

Or pass a provider directly — both styles work:

```swift
let response = try await generateText(
    model: .openAI(apiKey: "sk-...", model: "gpt-4o-mini"),
    prompt: "Explain async/await in Swift."
)
```

---

## AI.configure (Registry)

Set API keys once at startup. Then use model strings (`"provider/model"`) everywhere — no key at call sites.

```swift
// In AppDelegate, @main body, or app init
AI.configure {
    $0.openAI(apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!)
    $0.anthropic(apiKey: "sk-ant-...")
    $0.gemini(apiKey: "AIza...")
    $0.groq(apiKey: "gsk_...")
    $0.openRouter(apiKey: "sk-or-...")
    $0.mistral(apiKey: "...")
    $0.cohere(apiKey: "...")
    $0.cloudflare(accountID: "abc123", apiKey: "...")
    $0.ollama()  // no key — local
}
```

Supported model string format: `"provider/model-name"`

| String prefix | Provider |
|---|---|
| `"openai/..."` | OpenAI |
| `"anthropic/..."` | Anthropic |
| `"gemini/..."` | Google Gemini |
| `"groq/..."` | Groq |
| `"openrouter/..."` | OpenRouter |
| `"mistral/..."` | Mistral |
| `"cohere/..."` | Cohere |
| `"cloudflare/..."` | Cloudflare Workers AI |
| `"ollama/..."` | Ollama (local, no key needed) |

```swift
// generateText
let response = try await generateText(model: "openai/gpt-4o-mini", prompt: "Hello")

// streamText
for try await chunk in streamText(model: "anthropic/claude-sonnet-4-6", prompt: "Tell me a story.") {
    print(chunk.text, terminator: "")
}

// generateObject
let movie: Movie = try await generateObject(model: "gemini/gemini-2.5-flash", prompt: "Sci-fi movie", as: Movie.self).object

// SwiftyChat
let chat = SwiftyChat(model: "groq/llama-3.3-70b-versatile", systemPrompt: "Be helpful.")
```

### Error handling for registry

```swift
do {
    let response = try await generateText(model: "openai/gpt-4o-mini", prompt: "Hello")
} catch AIError.providerNotConfigured(let provider) {
    print("Call AI.configure { $0.\(provider)(apiKey:) } at startup")
} catch AIError.invalidModelString(let s) {
    print("Bad model string '\(s)' — use 'provider/model' format")
}
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
} catch AIError.providerNotConfigured(let provider) {
    print("'\(provider)' not configured — call AI.configure at startup")
} catch AIError.invalidModelString(let s) {
    print("Bad model string '\(s)' — use 'provider/model' format")
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

## SwiftyChat

`SwiftyChat` is an `@Observable` class that manages a full multi-turn chat session. It handles message history, streaming, and state — so your SwiftUI view stays simple.

With the registry (configure once at startup):

```swift
@State private var chat = SwiftyChat(
    model: "groq/llama-3.3-70b-versatile",
    systemPrompt: "You are a helpful assistant."
)
```

Or with a direct provider:

```swift
@State private var chat = SwiftyChat(
    model: .groq(apiKey: "gsk_...", model: "llama-3.3-70b-versatile"),
    systemPrompt: "You are a helpful assistant."
)
```

### Sending messages

```swift
try await chat.send("What is Swift?")
```

Every `send()` call:
1. Appends the user message to `chat.messages`
2. Streams the assistant reply token-by-token into a new assistant message
3. Sets `isStreaming = false` when done

### Reading state

```swift
chat.messages      // [ChatMessage] — full history, auto-updates during streaming
chat.isStreaming   // Bool — true while tokens are arriving
chat.error         // Error? — set if the stream throws
```

### SwiftUI example

```swift
struct ChatView: View {
    @State private var chat = SwiftyChat(
        model: .openAI(apiKey: "sk-...", model: "gpt-4o-mini")
    )
    @State private var input = ""

    var body: some View {
        VStack {
            ScrollView {
                ForEach(chat.messages) { message in
                    HStack {
                        if message.role == .user { Spacer() }
                        Text(message.content)
                            .padding(10)
                            .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundStyle(message.role == .user ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        if message.role == .assistant { Spacer() }
                    }
                    .padding(.horizontal)
                }
            }

            HStack {
                TextField("Message...", text: $input)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    let text = input
                    input = ""
                    Task { try? await chat.send(text) }
                }
                .disabled(chat.isStreaming || input.isEmpty)
            }
            .padding()
        }
    }
}
```

### Multi-turn conversation

History is managed automatically. Every `send()` passes the full `messages` array to the provider — the model sees the entire conversation.

```swift
try await chat.send("My name is Kartikay")
try await chat.send("What's my name?")  // model answers: "Kartikay"
```

### System prompt

Set once at init, injected as the first message on every request:

```swift
let chat = SwiftyChat(
    model: .anthropic(apiKey: "...", model: "claude-haiku-4-5-20251001"),
    systemPrompt: "Reply only in haiku form."
)
```

### Limiting history (context window)

Use `maxMessages` to cap how many messages are sent per request:

```swift
let chat = SwiftyChat(model: .openAI(apiKey: "...", model: "gpt-4o"), maxMessages: 20)
```

Oldest messages are trimmed first. System prompt (if set) is always included regardless of the limit.

### Stop and clear

```swift
chat.stop()   // cancel in-flight stream, keep partial message in history
chat.clear()  // wipe all messages and reset state
```

### ChatMessage

Each message in `chat.messages` is a `ChatMessage`:

```swift
public struct ChatMessage: Sendable, Identifiable {
    public let id: String
    public let role: ChatRole       // .user, .assistant, .system
    public var content: String
    public let createdAt: Date
}
```

---

## generateText

Works with any `AIModel` — direct provider or registry string.

```swift
let response = try await generateText(
    model: "openai/gpt-4o-mini",
    prompt: "Write a two-sentence summary of Swift concurrency."
)
print(response.text)
print("Tokens used:", response.usage?.outputTokens ?? 0)
```

---

## GenerationOptions

All generation functions accept an optional `GenerationOptions` to control model behaviour. Every field is optional — unset fields are omitted from the request.

```swift
let options = GenerationOptions(
    system: "You are a concise assistant.",
    temperature: 0.7,
    topP: 0.9,
    topK: 40,          // Anthropic + Gemini only
    maxTokens: 512,
    seed: 42,          // OpenAI + Gemini
    presencePenalty: 0.1,   // OpenAI-compatible only
    frequencyPenalty: 0.1,  // OpenAI-compatible only
    stopSequences: ["END"]
)

// generateText
let response = try await generateText(model: "openai/gpt-4o-mini", prompt: "Hi", options: options)

// streamText — with optional callbacks
for try await chunk in streamText(
    model: "anthropic/claude-sonnet-4-6",
    prompt: "Tell me a story.",
    options: GenerationOptions(temperature: 0.9, maxTokens: 1000),
    onChunk: { print($0.text, terminator: "") },
    onFinish: { print("\nDone. Tokens:", $0.usage?.outputTokens ?? 0) }
) {}

// generateObject
let result = try await generateObject(
    model: "gemini/gemini-2.5-flash",
    prompt: "Suggest a sci-fi movie",
    as: Movie.self,
    options: GenerationOptions(temperature: 0.5)
)
```

---

## generateObject

Returns a decoded Swift struct. No manual JSON parsing.

Define your type conforming to `JSONSchemaConvertible`:

```swift
struct Movie: Codable, JSONSchemaConvertible, Sendable {
    let title: String
    let year: Int
    let genre: String

    static var schemaName: String { "movie" }
    static var jsonSchema: [String: Any] {
        ["type": "object",
         "properties": [
             "title": ["type": "string"],
             "year":  ["type": "integer"],
             "genre": ["type": "string"]
         ],
         "required": ["title", "year", "genre"]]
    }
}
```

Call `generateObject`:

```swift
let result = try await generateObject(
    model: "openai/gpt-4o-mini",
    prompt: "Suggest a classic sci-fi movie"
)
print(result.object.title)           // "2001: A Space Odyssey"
print(result.usage?.outputTokens ?? 0)
```

`ObjectResponse<T>` wraps the decoded object and preserves provider metadata:

```swift
public struct ObjectResponse<T: Decodable & Sendable>: Sendable {
    public let object: T
    public let usage: TokenUsage?
    public let finishReason: String?
    public let model: String?
}
```

Note: V1 uses prompt injection — the schema is appended to the prompt and the response is decoded. Markdown fences (` ```json ``` `) are stripped automatically. Extra keys returned by the LLM are silently ignored by `JSONDecoder`.

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

### Registry

- ``AI``
- ``AIConfiguration``

### Core

- ``AIModel``
- ``AIStreamModel``
- ``AIResponse``
- ``AIStreamChunk``
- ``TokenUsage``
- ``AIError``

### Chat

- ``SwiftyChat``
- ``ChatMessage``
- ``ChatRole``

### Generation

- ``generateText(model:prompt:options:)``
- ``streamText(model:prompt:options:onChunk:onFinish:)``
- ``generateObject(model:prompt:as:options:)``
- ``GenerationOptions``
- ``ObjectResponse``
- ``JSONSchemaConvertible``

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
