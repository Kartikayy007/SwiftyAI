# ``Swifty_AI``

Swifty AI is a small abstraction for text generation across multiple model providers.

The current library surface is intentionally simple:

- Create a provider that conforms to ``AIModel``.
- Call ``generateText(model:prompt:)`` with a prompt.
- Read the returned ``AIResponse/text`` value.

At the moment, the package supports:

- OpenAI via ``OpenAIProvider``
- Anthropic via ``AnthropicProvider``
- Gemini via ``GeminiProvider``

It does not currently expose streaming, structured output, tool calling, or agent workflows.

## Overview

All providers conform to ``AIModel``:

```swift
public protocol AIModel: Sendable {
    func generate(_ prompt: String) async throws -> AIResponse
}
```

For most usage, you do not call `generate(_:)` directly. Instead, use the shared helper:

```swift
let response = try await generateText(model: model, prompt: "Explain async/await in Swift.")
print(response.text)
```

## Create a Model

Use the static factory helpers on ``AIModel`` to construct a provider:

```swift
let openAIModel = AIModel.openAI(
    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!,
    model: "gpt-4o-mini"
)

let anthropicModel = AIModel.anthropic(
    apiKey: ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]!,
    model: "claude-3-5-sonnet-latest"
)

let geminiModel = AIModel.gemini(
    apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"]!,
    model: "gemini-1.5-flash"
)
```

Each provider requires:

- an API key for that vendor
- a model name string accepted by that vendor's API

## Generate Text

Once you have a model, generate text with ``generateText(model:prompt:)``:

```swift
import Foundation

func runExample() async {
    let model = AIModel.openAI(
        apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"]!,
        model: "gpt-4o-mini"
    )

    do {
        let response = try await generateText(
            model: model,
            prompt: "Write a two-sentence summary of Swift concurrency."
        )

        print(response.text)
    } catch {
        print(error.localizedDescription)
    }
}
```

The response type is:

```swift
public struct AIResponse: Sendable {
    public let text: String
}
```

## Error Handling

Requests can throw ``AIError``:

- ``AIError/networkError(_:)`` when the HTTP request fails
- ``AIError/invalidResponse`` when the provider response is missing expected fields
- ``AIError/encodingError(_:)`` when request encoding fails
- ``AIError/decodingError(_:)`` when response decoding fails
- ``AIError/apiError(statusCode:message:)`` when the provider returns a non-2xx status

Example:

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
