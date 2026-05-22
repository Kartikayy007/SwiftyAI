import Foundation
import XCTest
@testable import Swifty_AI

final class ProviderRegistryTests: XCTestCase {
    func testResolvesEverySupportedModelType() throws {
        let language = RegistryMockModel("language")
        let stream = RegistryMockModel("stream")
        let tool = RegistryMockModel("tool")
        let image = RegistryMockModel("image")
        let transcription = RegistryMockModel("transcription")
        let speech = RegistryMockModel("speech")
        let video = RegistryMockModel("video")

        let registry = createProviderRegistry([
            "mock": customProvider(
                languageModels: ["language": language],
                streamModels: ["stream": stream],
                toolCallingModels: ["tool": tool],
                imageModels: ["image": image],
                transcriptionModels: ["transcription": transcription],
                speechModels: ["speech": speech],
                videoModels: ["video": video]
            )
        ])

        XCTAssertTrue((try registry.model("mock/language") as? RegistryMockModel) === language)
        XCTAssertTrue((try registry.languageModel("mock/language") as? RegistryMockModel) === language)
        XCTAssertTrue((try registry.model("mock/stream") as? RegistryMockModel) === stream)
        XCTAssertTrue((try registry.model("mock/tool") as? RegistryMockModel) === tool)
        XCTAssertTrue((try registry.streamModel("mock/stream") as? RegistryMockModel) === stream)
        XCTAssertTrue((try registry.streamModel("mock/tool") as? RegistryMockModel) === tool)
        XCTAssertTrue((try registry.toolCallingModel("mock/tool") as? RegistryMockModel) === tool)
        XCTAssertTrue((try registry.imageModel("mock/image") as? RegistryMockModel) === image)
        XCTAssertTrue((try registry.transcriptionModel("mock/transcription") as? RegistryMockModel) === transcription)
        XCTAssertTrue((try registry.speechModel("mock/speech") as? RegistryMockModel) === speech)
        XCTAssertTrue((try registry.videoModel("mock/video") as? RegistryMockModel) === video)
    }

    func testRegistryAwareGenerationAPIsResolveCustomModelStrings() async throws {
        let model = RegistryMockModel("custom")
        let registry = createProviderRegistry([
            "mock": customProvider(
                languageModels: ["text": model],
                streamModels: ["stream": model],
                toolCallingModels: ["tool": model],
                imageModels: ["image": model],
                transcriptionModels: ["transcription": model],
                speechModels: ["speech": model],
                videoModels: ["video": model]
            )
        ])

        let text = try await generateText(model: "mock/text", registry: registry, prompt: "Hello")
        XCTAssertEqual(text.text, "custom:Hello")

        var streamedText = ""
        for try await chunk in streamText(model: "mock/stream", registry: registry, prompt: "Hello") {
            streamedText += chunk.text
        }
        XCTAssertEqual(streamedText, "custom:Hello")

        let tools = try await generateWithTools(model: "mock/tool", registry: registry, prompt: "Hello", tools: [])
        XCTAssertEqual(tools.text, "custom:step")

        let image = try await generateImage(model: "mock/image", registry: registry, prompt: "Draw")
        XCTAssertEqual(image.model, "custom")

        let transcript = try await transcribe(
            model: "mock/transcription",
            registry: registry,
            audio: AIAudioInput(data: Data("audio".utf8), filename: "audio.wav", mediaType: .wav)
        )
        XCTAssertEqual(transcript.text, "custom:transcript")

        let speech = try await generateSpeech(model: "mock/speech", registry: registry, text: "Speak")
        XCTAssertEqual(speech.model, "custom")

        let video = try await generateVideo(model: "mock/video", registry: registry, prompt: "Animate")
        XCTAssertEqual(video.id, "custom")
    }

    func testUnknownProviderThrowsProviderNotConfigured() throws {
        let registry = createProviderRegistry([:])

        XCTAssertThrowsError(try registry.model("missing/text")) { error in
            guard case AIError.providerNotConfigured(let provider) = error else {
                return XCTFail("Expected providerNotConfigured, got \(error)")
            }
            XCTAssertEqual(provider, "missing")
        }
    }

    func testUnknownModelThrowsUnsupportedFeature() throws {
        let registry = createProviderRegistry([
            "mock": customProvider(languageModels: ["text": RegistryMockModel("text")])
        ])

        XCTAssertThrowsError(try registry.model("mock/other")) { error in
            guard case AIError.unsupportedFeature(let message) = error else {
                return XCTFail("Expected unsupportedFeature, got \(error)")
            }
            XCTAssertTrue(message.contains("No language model 'other'"))
        }
    }

    func testInvalidModelStringThrows() throws {
        let registry = createProviderRegistry([:])

        XCTAssertThrowsError(try registry.model("missing-slash")) { error in
            guard case AIError.invalidModelString(let modelString) = error else {
                return XCTFail("Expected invalidModelString, got \(error)")
            }
            XCTAssertEqual(modelString, "missing-slash")
        }
    }

    func testProviderIdIsCaseInsensitive() throws {
        let language = RegistryMockModel("language")
        let registry = createProviderRegistry([
            "mock": customProvider(languageModels: ["chat": language])
        ])
        XCTAssertTrue((try registry.model("Mock/chat") as? RegistryMockModel) === language)
        XCTAssertTrue((try registry.model("MOCK/chat") as? RegistryMockModel) === language)
        XCTAssertThrowsError(try registry.model("mock/CHAT"))
    }

    func testWrongModalityThrowsUnsupportedFeature() throws {
        let registry = createProviderRegistry([
            "mock": customProvider(languageModels: ["text": RegistryMockModel("text")])
        ])

        XCTAssertThrowsError(try registry.imageModel("mock/text")) { error in
            guard case AIError.unsupportedFeature(let message) = error else {
                return XCTFail("Expected unsupportedFeature, got \(error)")
            }
            XCTAssertTrue(message.contains("No image model 'text'"))
        }
    }

    func testCustomRegistryDoesNotChangeGlobalStringResolution() async throws {
        let registry = createProviderRegistry([
            "mock": customProvider(languageModels: ["text": RegistryMockModel("local")])
        ])

        let local = try await generateText(model: "mock/text", registry: registry, prompt: "Hello")
        XCTAssertEqual(local.text, "local:Hello")

        do {
            _ = try await generateText(model: "mock/text", prompt: "Hello")
            XCTFail("Expected global resolution to fail")
        } catch AIError.providerNotConfigured(let provider) {
            XCTAssertEqual(provider, "mock")
        }
    }
}

private final class RegistryMockModel: AIToolCallingModel, AIImageModel, AITranscriptionModel, AISpeechModel, AIVideoModel, @unchecked Sendable {
    private let id: String

    init(_ id: String) {
        self.id = id
    }

    func generate(_ prompt: String) async throws -> AIResponse {
        AIResponse(text: "\(id):\(prompt)", model: id)
    }

    func stream(_ prompt: String) -> AsyncThrowingStream<AIStreamChunk, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(AIStreamChunk(text: "\(id):\(prompt)", finishReason: "stop"))
            continuation.finish()
        }
    }

    func generateStep(
        messages: [AIAgentMessage],
        tools: [AITool],
        options: GenerationOptions
    ) async throws -> AIToolStepResponse {
        AIToolStepResponse(text: "\(id):step", finishReason: "stop", model: id)
    }

    func generateImage(prompt: String, options: ImageGenerationOptions) async throws -> ImageResponse {
        ImageResponse(
            images: [GeneratedImage(data: Data(id.utf8), base64: nil, url: nil)],
            model: id
        )
    }

    func transcribe(_ audio: AIAudioInput, options: TranscriptionOptions) async throws -> TranscriptionResponse {
        TranscriptionResponse(text: "\(id):transcript", model: id)
    }

    func generateSpeech(_ text: String, options: SpeechOptions) async throws -> SpeechResponse {
        SpeechResponse(data: Data(id.utf8), format: options.format, mediaType: options.format.mediaType, model: id)
    }

    func generateVideo(prompt: String, options: VideoGenerationOptions) async throws -> VideoResponse {
        VideoResponse(id: id, data: Data(id.utf8), model: id)
    }
}
