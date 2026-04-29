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
- `generateObject`: schema-guided decoding into `RecipeSummary`.
- `SwiftyChat`: stateful streaming chat.
- `generateWithTools`: local Swift function calling with step timeline.
- `streamWithTools`: live agent events for text, tool calls, and tool results.
- `GenerationOptions`: temperature, token limit, retry, stop sequences, and prompt caching.

## Notes

The app creates provider instances directly from settings. `SwiftyAIConfigurator` is included to show how those same settings map to the SDK registry API, but the screens use direct models to avoid timing issues from async registry configuration.
