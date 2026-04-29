# ``Swifty_AI``

A provider-agnostic AI SDK for Apple platforms, with zero mandatory dependencies.

## Overview

Configure once and use it everywhere, with no API key needed at every call site.

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

You can also pass a provider directly. Both styles work:

```swift
let response = try await generateText(
    model: .openAI(apiKey: "sk-...", model: "gpt-4o-mini"),
    prompt: "Explain async/await in Swift."
)
```

---

## AI.configure (Registry)

Set API keys once at startup, then use model strings (`"provider/model"`) everywhere. You do not need to pass keys at each call site.

```swift
// In AppDelegate, @main, or your app initializer
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

### Registry error handling

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

The protocol that every provider conforms to. You rarely need to use this directly; use the factory methods instead.

```swift
public protocol AIModel: Sendable {
    func generate(_ prompt: String) async throws -> AIResponse
}
```

You can also make your own type conform to `AIModel` for mocks or custom backends:

```swift
struct MyMockModel: AIModel {
    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "mocked", model: nil, usage: nil, finishReason: nil)
    }
}
```

### AIResponse

Returned by every `generateText` call:

```swift
public struct AIResponse: Sendable {
    public let text: String           // the generated text
    public let model: String?         // model ID echoed back by provider
    public let usage: TokenUsage?     // token counts (if provider returns them)
    public let finishReason: String?  // "stop", "length", "end_turn", etc.
}
```

Example of reading all fields:

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

Request failures throw `AIError`. Catch it specifically for structured error handling:

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

Stream tokens as they are generated. This works with any provider that conforms to ``AIStreamModel``.

```swift
for try await chunk in streamText(model: model, prompt: "Tell me a story.") {
    print(chunk.text, terminator: "")  // print each delta as it arrives
}
```

Each ``AIStreamChunk`` includes:
- `text` — the delta for this chunk (one or a few tokens)
- `finishReason` — non-nil only on the last chunk (`"stop"`, `"end_turn"`, `"STOP"`, etc.)
- `usage` — non-nil only on the last chunk, where the provider supports it

Accumulate the full response yourself when needed:

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

Cancellation is supported. Wrap the stream in a `Task` and call `.cancel()` to stop it cleanly.

---

## SwiftyChat

`SwiftyChat` is an `@Observable` class that manages a full multi-turn chat session. It handles message history, streaming, and state so your SwiftUI view can stay simple.

With the registry (configure once at startup):

```swift
@State private var chat = SwiftyChat(
    model: "groq/llama-3.3-70b-versatile",
    systemPrompt: "You are a helpful assistant."
)
```

With a direct provider:

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

Every `send()` call does the following:
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

History is managed automatically. Every `send()` call passes the full `messages` array to the provider, so the model sees the entire conversation.

```swift
try await chat.send("My name is Kartikay")
try await chat.send("What's my name?")  // model answers: "Kartikay"
```

### System prompt

Set the system prompt once during initialization. It is injected as the first message on every request:

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

The oldest messages are trimmed first. The system prompt, if set, is always included regardless of the limit.

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

Works with any `AIModel`, including a direct provider or a registry string.

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

All generation functions accept optional `GenerationOptions` to control model behavior. Every field is optional; unset fields are omitted from the request.

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
    stopSequences: ["END"],
    headers: ["X-Request-ID": "abc123"],
    retryPolicy: RetryPolicy(maxAttempts: 3),
    promptCaching: PromptCachingOptions(cacheKey: "user-123")
)

// generateText
let response = try await generateText(model: "openai/gpt-4o-mini", prompt: "Hi", options: options)

// streamText with optional callbacks
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

## generateWithTools

Run a multi-step tool loop. The model can request one or more tools, SwiftyAI executes them, and the tool results are sent back to the model until the loop finishes or reaches `maxSteps`.

```swift
let weather = AITool(
    name: "weather",
    description: "Gets the current weather for a city.",
    parameters: [
        "type": "object",
        "properties": ["city": ["type": "string"]],
        "required": ["city"]
    ]
) { args in
    "Sunny in \(args["city"] as? String ?? "unknown city")"
}

let result = try await generateWithTools(
    model: "openai/gpt-4o-mini",
    prompt: "What is the weather in Delhi?",
    tools: [weather],
    maxSteps: 5,
    stopWhen: [isLoopFinished()],
    onStepFinish: { step in
        print("Finished step", step.index)
    }
)

print(result.text)
```

Built-in stop conditions:

- `isLoopFinished()` stops when the model returns final text with no tool calls.
- `stepCountIs(_:)` stops on a specific step.
- `hasToolCall(_:)` stops when any tool call, or a named tool call, appears.

`streamWithTools` exposes the same loop as an `AsyncThrowingStream<AIAgentChunk, Error>` and supports `onChunk`, `onStepFinish`, and `onFinish` callbacks.

### Typed and dynamic tools

Use `tool()` when your tool has typed Codable input and output:

```swift
struct TipInput: Decodable {
    let bill: Double
    let percent: Double
}

struct TipOutput: Encodable {
    let tip: Double
    let total: Double
}

let tip = tool(
    name: "calculate_tip",
    description: "Calculates a restaurant tip.",
    inputSchema: .object(properties: [
        "bill": .number(minimum: 0),
        "percent": .number(minimum: 0)
    ]),
    outputSchema: .object(properties: [
        "tip": .number(),
        "total": .number()
    ])
) { (input: TipInput) in
    let tip = input.bill * input.percent / 100
    return TipOutput(tip: tip, total: input.bill + tip)
}
```

Use `dynamicTool()` when the tool needs raw JSON-like arguments:

```swift
let lookup = dynamicTool(
    name: "lookup_order",
    description: "Looks up an order.",
    inputSchema: .object(properties: ["orderID": .string()])
) { args in
    "Order \(args["orderID"] as? String ?? "") is out for delivery."
}
```

### Approval, interception, telemetry, and parallel calls

`ToolExecutionOptions` controls the tool loop without changing provider code:

```swift
let result = try await generateWithTools(
    model: "openai/gpt-4o-mini",
    prompt: "Check order A100 and calculate a tip.",
    tools: [lookup, tip],
    toolOptions: ToolExecutionOptions(
        approval: { call in
            call.name == "lookup_order" ? .execute : .reject(reason: "Needs approval")
        },
        onToolCall: { call in
            call.name == "lookup_order"
                ? .replaceArguments(#"{"orderID":"B200"}"#)
                : .execute
        },
        onTelemetry: { event in print(event) },
        parallelToolCalls: true
    )
)
```

By default, tool errors are returned to the model as `AIToolResult(isError: true)`. Set `errorPolicy: .failFast` to throw immediately.

Tool calling uses native request fields for OpenAI-compatible providers, including OpenAI, Groq, OpenRouter, Mistral, Cohere, Cloudflare Workers AI, and Ollama. Anthropic, Gemini, and Apple Foundation Models use a provider-neutral JSON prompt fallback until their native tool formats are mapped.

---

## generateObject

Returns a decoded Swift struct. No manual JSON parsing is required.

Define a type that conforms to `JSONSchemaConvertible`:

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

Note: Version 1 appends the schema to the prompt and decodes the model response. Markdown fences (` ```json ``` `) are stripped automatically. Extra keys returned by the LLM are ignored by `JSONDecoder`.

### Output.object, Output.array, and Output.enum

For new code, prefer `Output` with `AISchemaConvertible`:

```swift
struct Movie: Codable, AISchemaConvertible {
    let title: String
    let year: Int

    static var aiSchema: AISchema {
        .object(
            properties: [
                "title": .string(description: "Movie title", minLength: 1),
                "year": .integer(minimum: 1888)
            ],
            required: ["title", "year"]
        )
    }
}

let movie = try await generateObject(
    model: "openai/gpt-4o-mini",
    prompt: "Suggest a sci-fi movie",
    output: .object(Movie.self)
).object
```

Arrays:

```swift
let movies = try await generateObject(
    model: "openai/gpt-4o-mini",
    prompt: "Suggest three sci-fi movies",
    output: Output<[Movie]>.array(Movie.self)
).object
```

Enums:

```swift
enum Priority: String, Codable, CaseIterable {
    case low, medium, high
}

let priority = try await generateObject(
    model: "openai/gpt-4o-mini",
    prompt: "Classify this as low, medium, or high priority.",
    output: Output<Priority>.enumeration(Priority.self)
).object
```

### streamObject

`streamObject` streams raw JSON text as it arrives and attempts best-effort partial decoding. Final output is strictly validated before finishing.

```swift
for try await chunk in streamObject(
    model: "openai/gpt-4o-mini",
    prompt: "Suggest a sci-fi movie",
    output: Output<Movie>.object(Movie.self)
) {
    print(chunk.textDelta, terminator: "")
    if let partial = chunk.partialObject {
        print("Partial:", partial)
    }
    if let object = chunk.object {
        print("Final:", object)
    }
}
```

If final JSON does not match the schema, SwiftyAI throws:

```swift
catch AIError.schemaValidationFailed(let issues) {
    for issue in issues {
        print(issue.path, issue.message)
    }
}
```

### @Guide constraints

`@Guide` can keep field constraints near your model type. In this version it is metadata for your own schema declarations, not automatic schema synthesis:

```swift
struct Recipe: Codable, AISchemaConvertible {
    @Guide("Short recipe title", minLength: 1)
    var title: String

    static var aiSchema: AISchema {
        .object(properties: ["title": .string(description: "Short recipe title", minLength: 1)])
    }
}
```

---

## Providers

### OpenAI

Free tier: no. Models include `gpt-4o`, `gpt-4o-mini`, `o1-mini`, and others.

```swift
let model = AIModel.openAI(
    apiKey: "sk-...",
    model: "gpt-4o-mini"
)

let response = try await generateText(model: model, prompt: "What is Swift?")
print(response.text)
```

### Anthropic

Free tier: no. Models include `claude-opus-4-7`, `claude-sonnet-4-6`, `claude-haiku-4-5-20251001`, and others.

```swift
let model = AIModel.anthropic(
    apiKey: "sk-ant-...",
    model: "claude-sonnet-4-6"
)

let response = try await generateText(model: model, prompt: "Explain optionals in Swift.")
print(response.text)
```

### Google Gemini

Free tier: yes. Models include `gemini-2.5-flash`, `gemini-2.5-pro`, and others.

```swift
let model = AIModel.gemini(
    apiKey: "AIza...",
    model: "gemini-2.5-flash"
)

let response = try await generateText(model: model, prompt: "What is SwiftUI?")
print(response.text)
```

### Groq

Free tier: yes. Models include `llama-3.3-70b-versatile`, `mixtral-8x7b-32768`, and others.

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

Free tier: yes (`mistral-small-latest` has a free tier). Models include `mistral-large-latest`, `mistral-small-latest`, and others.

```swift
let model = AIModel.mistral(
    apiKey: "...",
    model: "mistral-small-latest"
)

let response = try await generateText(model: model, prompt: "What are Swift actors?")
print(response.text)
```

### Cohere

Free tier: yes. Models include `command-a-03-2025`, `command-r-plus`, and others.

```swift
let model = AIModel.cohere(
    apiKey: "...",
    model: "command-a-03-2025"
)

let response = try await generateText(model: model, prompt: "Describe Swift concurrency.")
print(response.text)
```

### Cloudflare Workers AI

Free tier: yes. Requires your account ID from the Cloudflare Workers dashboard. Models include `@cf/meta/llama-3.3-70b-instruct-fp8-fast` and others.

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

Free. Runs models on your Mac with no API key and no cloud dependency. Requires [Ollama](https://ollama.com) and a pulled model, such as `ollama pull llama3.2`.

```swift
let model = AIModel.ollama(model: "llama3.2")

let response = try await generateText(model: model, prompt: "What is Swift?")
print(response.text)
```

Non-default host or port:

```swift
let model = AIModel.ollama(model: "llama3.2", baseURL: "http://localhost:8080/v1")
```

Popular models include `llama3.2`, `mistral`, `gemma3`, `phi4`, and `qwen2.5-coder`. Run `ollama list` to see what is installed.

### Apple Foundation Models (on-device)

Free. Uses Apple's on-device model through the `FoundationModels` framework. Requires iOS 26+ or macOS 26+, Apple Silicon, and Apple Intelligence enabled in Settings.

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

Token limit: 4096 combined input and output tokens. No usage metadata is returned because Apple does not expose token counts.

### Custom OpenAI-compatible backend

Any backend that supports the OpenAI `/chat/completions` format, such as Together AI, LM Studio, or vLLM.

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
- ``generateWithTools(model:prompt:tools:options:maxSteps:stopWhen:onStepFinish:toolOptions:)``
- ``streamWithTools(model:prompt:tools:options:maxSteps:stopWhen:onChunk:onStepFinish:onFinish:toolOptions:)``
- ``generateObject(model:prompt:as:options:)``
- ``streamObject(model:prompt:output:options:onPartial:onFinish:)``
- ``GenerationOptions``
- ``ObjectResponse``
- ``ObjectStreamChunk``
- ``Output``
- ``AISchema``
- ``AISchemaConvertible``
- ``AISchemaValidationIssue``
- ``Guide``
- ``JSONSchemaConvertible``
- ``AITool``
- ``tool(name:description:inputSchema:outputSchema:execute:)``
- ``dynamicTool(name:description:inputSchema:outputSchema:execute:)``
- ``ToolExecutionOptions``
- ``AIStepResult``
- ``AIStopCondition``

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
