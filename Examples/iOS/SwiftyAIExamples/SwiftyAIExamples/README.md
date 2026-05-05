# SwiftyAI iOS Examples

This app is a runnable gallery of SwiftyAI capabilities, similar in spirit to the Vercel AI SDK examples.

## Run

1. Open `SwiftyAIExamples.xcodeproj` in Xcode.
2. Select the `SwiftyAIExamples` scheme and an iOS 17+ simulator.
3. Open Settings in the app.
4. Choose a provider and model.
5. Enter credentials locally. Secrets are stored in the device Keychain.
6. Run the examples from the sidebar.

## Examples

- `generateText`: one-shot text generation with `AIResponse` metadata.
- `streamText`: live `AIStreamChunk` rendering from `AsyncThrowingStream`.
- `generateObject`: schema-guided decoding with `Output.object`, `Output.array`, and `Output.enum`.
- `streamObject`: partial JSON, best-effort partial objects, validation issues, and final decoded values.
- `SwiftyChat`: stateful streaming chat.
- `AIChat Hook`: SwiftUI hook state for chat input, messages, loading, errors, and cancellation.
- `AICompletion Hook`: SwiftUI hook state for prompt, output, loading, errors, and cancellation.
- `generateWithTools`: typed and dynamic Swift tools with step timeline.
- `streamWithTools`: live agent events for text, tool calls, tool results, telemetry, interception, approval hooks, and parallel calls.
- `GenerationOptions`: temperature, token limit, retry, stop sequences, and prompt caching.

## Notes

The app creates provider instances directly from settings. `SwiftyAIConfigurator` is included to show how those same settings map to the SDK registry API, but the screens use direct models to avoid timing issues from async registry configuration.
