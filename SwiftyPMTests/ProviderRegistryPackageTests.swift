import Foundation
import XCTest
import SwiftyAI

final class ProviderRegistryPackageTests: XCTestCase {
    func testProviderRegistryPublicAPI() async throws {
        let model = PackageRegistryModel("package")
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

        XCTAssertNoThrow(try registry.model("mock/text"))
        XCTAssertNoThrow(try registry.languageModel("mock/text"))
        XCTAssertNoThrow(try registry.streamModel("mock/stream"))
        XCTAssertNoThrow(try registry.toolCallingModel("mock/tool"))
        XCTAssertNoThrow(try registry.imageModel("mock/image"))
        XCTAssertNoThrow(try registry.transcriptionModel("mock/transcription"))
        XCTAssertNoThrow(try registry.speechModel("mock/speech"))
        XCTAssertNoThrow(try registry.videoModel("mock/video"))

        let text = try await generateText(model: "mock/text", registry: registry, prompt: "Hello")
        XCTAssertEqual(text.text, "package:Hello")

        var streamed = ""
        for try await chunk in streamText(model: "mock/stream", registry: registry, prompt: "Hello") {
            streamed += chunk.text
        }
        XCTAssertEqual(streamed, "package:Hello")

        let image = try await generateImage(model: "mock/image", registry: registry, prompt: "Draw")
        XCTAssertEqual(image.model, "package")

        let transcript = try await transcribe(
            model: "mock/transcription",
            registry: registry,
            audio: AIAudioInput(data: Data("audio".utf8), filename: "audio.wav", mediaType: .wav)
        )
        XCTAssertEqual(transcript.text, "package:transcript")

        let speech = try await generateSpeech(model: "mock/speech", registry: registry, text: "Speak")
        XCTAssertEqual(speech.model, "package")

        let video = try await generateVideo(model: "mock/video", registry: registry, prompt: "Animate")
        XCTAssertEqual(video.id, "package")
    }
}

private final class PackageRegistryModel: AIToolCallingModel, AIImageModel, AITranscriptionModel, AISpeechModel, AIVideoModel, @unchecked Sendable {
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
        ImageResponse(images: [GeneratedImage(data: Data(id.utf8), base64: nil, url: nil)], model: id)
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
