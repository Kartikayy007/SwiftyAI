import Foundation
import XCTest
import SwiftyAI

final class MediaPackageTests: XCTestCase {
    func testGenerateImagePublicAPIAndMiddleware() async throws {
        let model = CapturingImageModel()
        let wrapped = wrapImageModel(
            model,
            middleware: [
                ImageModelMiddleware { request, next in
                    var request = request
                    request.prompt += ", product photo"
                    return try await next(request)
                }
            ]
        )

        let response = try await generateImage(
            model: wrapped,
            prompt: "A desk lamp",
            options: ImageGenerationOptions(size: .square1024, quality: .high, format: .png)
        )

        XCTAssertEqual(model.capturedPrompt, "A desk lamp, product photo")
        XCTAssertEqual(response.images.first?.mediaType, .png)
    }

    func testSpeechAndTranscriptionPublicAPI() async throws {
        let model = CapturingAudioModel()
        let audio = AIAudioInput(data: Data("audio".utf8), filename: "clip.wav", mediaType: .wav)

        let transcript = try await transcribe(model: model, audio: audio)
        let speech = try await generateSpeech(model: model, text: "Hello", options: SpeechOptions(format: .wav))

        XCTAssertEqual(transcript.text, "transcript")
        XCTAssertEqual(speech.format, .wav)
    }

    func testVideoPublicAPI() async throws {
        let model = CapturingVideoModel()
        let response = try await generateVideo(
            model: model,
            prompt: "A logo animation",
            options: VideoGenerationOptions(size: "1280x720", seconds: 8, pollInterval: .zero)
        )

        XCTAssertEqual(model.capturedPrompt, "A logo animation")
        XCTAssertEqual(response.data, Data("video".utf8))
    }
}

private final class CapturingImageModel: AIImageModel, @unchecked Sendable {
    private(set) var capturedPrompt: String?

    func generateImage(prompt: String, options: ImageGenerationOptions) async throws -> ImageResponse {
        capturedPrompt = prompt
        return ImageResponse(images: [GeneratedImage(data: Data("image".utf8), base64: nil, url: nil, mediaType: options.format?.mediaType ?? .png)])
    }
}

private final class CapturingAudioModel: AITranscriptionModel, AISpeechModel, @unchecked Sendable {
    func transcribe(_ audio: AIAudioInput, options: TranscriptionOptions) async throws -> TranscriptionResponse {
        TranscriptionResponse(text: "transcript")
    }

    func generateSpeech(_ text: String, options: SpeechOptions) async throws -> SpeechResponse {
        SpeechResponse(data: Data("speech".utf8), format: options.format, mediaType: options.format.mediaType)
    }
}

private final class CapturingVideoModel: AIVideoModel, @unchecked Sendable {
    private(set) var capturedPrompt: String?

    func generateVideo(prompt: String, options: VideoGenerationOptions) async throws -> VideoResponse {
        capturedPrompt = prompt
        return VideoResponse(id: "video_1", data: Data("video".utf8))
    }
}
