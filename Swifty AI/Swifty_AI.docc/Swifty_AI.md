# ``SwiftyAI``

SwiftyAI is a provider-neutral Swift package for text generation, streaming,
structured output, tool loops, multimodal prompts, media calls, SwiftUI state,
middleware, telemetry, and MCP tool adapters.

The package exposes plain Swift protocols and functions. You can pass concrete
provider values directly, resolve built-in providers through `AI.configure`, or
create a local `ProviderRegistry` for custom models and tests.

## Direct Providers

The most explicit setup is to construct a provider value and pass it to the API
you want to use.

```swift
import SwiftyAI

let model = OpenAICompatibleProvider(
    baseURL: "https://api.openai.com/v1",
    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!,
    model: "gpt-4o-mini"
)

let response = try await generateText(
    model: model,
    prompt: "Explain Swift actors in three practical bullets."
)

print(response.text)
```

Direct provider values are best for examples, tests, previews, dependency
injection, and any code path that configures and calls a model immediately.

## Built-In Model Strings

For app-wide setup, configure provider credentials once and use
`"provider/model"` strings at call sites.

```swift
AI.configure { ai in
    ai.openAI(apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!)
    ai.anthropic(apiKey: ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]!)
    ai.gemini(apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"]!)
    ai.ollama()
}

let response = try await generateText(
    model: "openai/gpt-4o-mini",
    prompt: "Write a one-line release note."
)
```

Call `AI.configure` during app startup before user-driven model calls begin. If
you need immediate resolution in the same code path, use a direct provider or a
local `ProviderRegistry`.

Supported built-in prefixes are:

- `openai`
- `anthropic`
- `gemini`
- `groq`
- `openrouter`
- `mistral`
- `cohere`
- `cloudflare`
- `ollama`

## Provider Registry

`ProviderRegistry` is a local resolver for custom model strings. It is separate
from the shared `AI.configure` registry.

```swift
struct EchoModel: AIModel {
    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "Echo: \(prompt)", model: "echo")
    }
}

let registry = createProviderRegistry([
    "local": customProvider(
        languageModels: ["echo": EchoModel()]
    )
])

let response = try await generateText(
    model: "local/echo",
    registry: registry,
    prompt: "Hello"
)
```

Register models by capability when you need streaming, tools, image generation,
transcription, speech, or video.

## Text Generation

Use `generateText` for a complete response.

```swift
let response = try await generateText(
    model: model,
    prompt: "Summarize this incident report.",
    options: GenerationOptions(
        system: "Be concise.",
        temperature: 0.2,
        maxTokens: 300
    )
)

print(response.text)
print(response.usage?.totalTokens ?? 0)
print(response.finishReason ?? "unknown")
```

`AIResponse` contains generated `text`, optional provider `model`, optional
`usage`, and optional `finishReason`.

## Streaming

Use `streamText` when a UI should update as text arrives.

```swift
var fullText = ""

for try await chunk in streamText(
    model: model,
    prompt: "Write a short haiku about Swift concurrency."
) {
    fullText += chunk.text
    print(chunk.text, terminator: "")
}
```

`AIStreamChunk` contains the text delta plus optional final usage and finish
reason metadata when the provider sends it.

## Multimodal Prompts

Use `[AIMessageContent]` for prompts with text plus images, PDFs, files, audio,
or video.

```swift
let response = try await generateText(
    model: model,
    prompt: [
        .text("Describe the important details in this image."),
        .imageData(imageData, mediaType: .png, detail: .high)
    ]
)
```

Available media constructors include:

- Images: `.imageURL`, `.imageData`, `.imageBase64`
- PDFs: `.pdfURL`, `.pdfData`, `.pdfBase64`
- Audio: `.audioData`, `.audioBase64`
- Video: `.videoURL`, `.videoData`, `.videoBase64`
- Generic files: `.fileURL`, `.fileData`, `.fileBase64`

Provider and model capability still decide whether a specific media type is
accepted by the remote API.

## Structured Output

`generateObject` asks the model for JSON, strips common Markdown fences,
validates against an `AISchema`, and decodes the result.

```swift
struct Movie: Codable, JSONSchemaConvertible {
    let title: String
    let year: Int

    static var schemaName: String { "movie" }
    static var jsonSchema: [String: Any] {
        [
            "type": "object",
            "properties": [
                "title": ["type": "string"],
                "year": ["type": "integer"]
            ],
            "required": ["title", "year"]
        ]
    }
}

let movie = try await generateObject(
    model: model,
    prompt: "Suggest a classic sci-fi movie.",
    as: Movie.self
).object
```

For new schema declarations, `AISchemaConvertible` and `Output` keep the schema
close to the decoded type.

```swift
struct RecipeSummary: Codable, AISchemaConvertible {
    let title: String
    let servings: Int

    static var aiSchema: AISchema {
        .object(properties: [
            "title": .string(description: "Short recipe title", minLength: 1),
            "servings": .integer(description: "Number of servings", minimum: 1)
        ])
    }
}

let result = try await generateObject(
    model: model,
    prompt: "Turn tomato soup into a recipe summary.",
    output: .object(RecipeSummary.self)
)
```

`streamObject` streams raw JSON text and attempts best-effort partial decoding
before yielding a final validated object.

## Tool Calling

`generateWithTools` runs a model-tool loop. The model can request one or more
tools, SwiftyAI executes them, and the results are sent back until the loop
finishes or reaches `maxSteps`.

```swift
struct WeatherInput: Decodable {
    let city: String
}

let weather = tool(
    name: "get_weather",
    description: "Get the current weather for a city.",
    inputSchema: .object(properties: [
        "city": .string(description: "City name")
    ])
) { (input: WeatherInput) async throws in
    "It is 21C and clear in \(input.city)."
}

let result = try await generateWithTools(
    model: model,
    prompt: "Should I bring an umbrella in London today?",
    tools: [weather],
    maxSteps: 4,
    stopWhen: [isLoopFinished()]
)

print(result.text)
```

Use `streamWithTools` for `AIAgentChunk` streams and `createAgentUIStream` for
higher-level `AgentEvent` values.

`ToolExecutionOptions` supports approval hooks, interception, tool-result
callbacks, telemetry callbacks, parallel tool execution, and fail-fast error
handling.

## Middleware

Middleware wraps model calls without changing provider implementations.

```swift
let wrapped = wrapLanguageModel(
    model,
    middleware: [
        defaultSettingsMiddleware(
            system: "Answer with concise Swift examples.",
            temperature: 0.2
        ),
        extractReasoningMiddleware(),
        extractJsonMiddleware(onFailure: .leaveUnchanged)
    ]
)

let response = try await generateText(
    model: wrapped,
    prompt: "Return a JSON object with a title and summary."
)
```

Streaming middleware can set defaults for streaming requests or simulate a
stream from a non-streaming model.

```swift
let streaming = wrapLanguageModel(
    model,
    streamMiddleware: [
        simulateStreamingMiddleware(chunkSize: 24, delay: .milliseconds(30))
    ]
)
```

## Media

SwiftyAI includes provider-neutral APIs for image generation, transcription,
speech generation, and video generation.

```swift
let image = try await generateImage(
    model: OpenAICompatibleProvider(
        baseURL: "https://api.openai.com/v1",
        apiKey: openAIKey,
        model: "gpt-image-1"
    ),
    prompt: "A clean app icon for a Swift package named SwiftyAI.",
    options: ImageGenerationOptions(size: .square1024, quality: .high)
)
```

```swift
let transcript = try await transcribe(
    model: transcriptionModel,
    audio: AIAudioInput(data: audioData, filename: "meeting.wav", mediaType: .wav)
)

let speech = try await generateSpeech(
    model: speechModel,
    text: "Your export is ready."
)

let video = try await generateVideo(
    model: videoModel,
    prompt: "A calm onboarding animation for a task app."
)
```

Built-in media string resolution currently routes through OpenAI-compatible and
Gemini providers. Provider model capability still matters.

## SwiftUI State Helpers

`AIChat` and `AICompletion` are `@MainActor` and `@Observable` state helpers.
They manage async task state while you build the view.

```swift
@State private var chat = AIChat(
    model: "openai/gpt-4o-mini",
    systemPrompt: "Be concise."
)

chat.input = "Explain Swift actors."
chat.send()
```

```swift
@State private var completion = AICompletion(model: "openai/gpt-4o-mini")

completion.prompt = "Write a tooltip for archiving a project."
completion.send()
```

`SwiftyChat` is another observable chat helper with an async `send(_:)` method.
For cancellation-aware SwiftUI views, prefer `AIChat` or cancel the task that is
awaiting `SwiftyChat.send(_:)`.

## MCP

`MCPClient` connects SwiftyAI to Model Context Protocol servers through an
app-provided `MCPTransport`.

```swift
let client = MCPClient(transport: transport)

try await client.initialize()
let mcpTools = try await client.listTools()
let tools = mcpTools.asAITools(client: client)

let result = try await generateWithTools(
    model: model,
    prompt: "Use the available tools to answer.",
    tools: tools
)
```

The SDK supplies the client primitives and adapter. It does not ship a concrete
HTTP, stdio, WebSocket, or server-process transport.

## Topics

### Core

- ``AIModel``
- ``AIStreamModel``
- ``AIResponse``
- ``AIStreamChunk``
- ``GenerationOptions``
- ``AIError``

### Providers

- ``OpenAICompatibleProvider``
- ``AnthropicProvider``
- ``GeminiProvider``
- ``AppleFoundationProvider``
- ``ProviderRegistry``
- ``AI``

### Generation

- ``generateText(model:prompt:options:)``
- ``streamText(model:prompt:options:onChunk:onFinish:)``
- ``generateObject(model:prompt:as:options:)``
- ``streamObject(model:prompt:output:options:onPartial:onFinish:)``

### Tools And Agents

- ``AITool``
- ``tool(name:description:inputSchema:outputSchema:execute:)``
- ``dynamicTool(name:description:inputSchema:outputSchema:execute:)``
- ``generateWithTools(model:prompt:tools:options:maxSteps:stopWhen:onStepFinish:toolOptions:)``
- ``streamWithTools(model:prompt:tools:options:maxSteps:stopWhen:onChunk:onStepFinish:onFinish:toolOptions:)``
- ``createAgentUIStream(model:prompt:tools:options:maxSteps:stopWhen:onEvent:onStepFinish:onFinish:toolOptions:)``

### Media

- ``generateImage(model:prompt:options:)``
- ``transcribe(model:audio:options:)``
- ``generateSpeech(model:text:options:)``
- ``generateVideo(model:prompt:options:)``

### SwiftUI And Utilities

- ``AIChat``
- ``AICompletion``
- ``SwiftyChat``
- ``ChatMessage``
- ``AIMessageContent``
- ``ContextWindow``
- ``simulateReadableStream(_:chunkSize:delay:)``
- ``smoothStream(_:charactersPerChunk:interval:)``
