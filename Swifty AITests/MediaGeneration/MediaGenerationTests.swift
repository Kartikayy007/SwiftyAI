import Foundation
import XCTest

@testable import Swifty_AI

final class MediaGenerationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.handler = nil
    }

    func testOpenAIImageGenerationEncodesOptionsAndDecodesBase64() async throws {
        var body: [String: Any]?
        MockURLProtocol.handler = { request in
            body = try Self.jsonBody(from: request)
            return try mockResponse(
                statusCode: 200,
                json: ["data": [["b64_json": Data("image".utf8).base64EncodedString(), "revised_prompt": "better"]]]
            )
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-image-1", session: .mock)
        let response = try await generateImage(
            model: provider,
            prompt: "Robot on a skateboard",
            options: ImageGenerationOptions(
                count: 2,
                size: .square1024,
                quality: .high,
                format: .webp,
                background: .opaque,
                compression: 80
            )
        )

        XCTAssertEqual(body?["model"] as? String, "gpt-image-1")
        XCTAssertEqual(body?["prompt"] as? String, "Robot on a skateboard")
        XCTAssertEqual(body?["n"] as? Int, 2)
        XCTAssertEqual(body?["size"] as? String, "1024x1024")
        XCTAssertEqual(body?["quality"] as? String, "high")
        XCTAssertEqual(body?["output_format"] as? String, "webp")
        XCTAssertEqual(body?["output_compression"] as? Int, 80)
        XCTAssertEqual(response.images.first?.data, Data("image".utf8))
        XCTAssertEqual(response.images.first?.mediaType, .webp)
        XCTAssertEqual(response.images.first?.revisedPrompt, "better")
    }

    func testImageModelMiddlewareCanRewritePrompt() async throws {
        let model = CapturingImageModel()
        let wrapped = wrapImageModel(
            model,
            middleware: [
                ImageModelMiddleware { request, next in
                    var request = request
                    request.prompt += ", cinematic lighting"
                    return try await next(request)
                }
            ]
        )

        _ = try await generateImage(model: wrapped, prompt: "A fox")

        XCTAssertEqual(model.capturedPrompt, "A fox, cinematic lighting")
    }

    func testOpenAITranscriptionUsesMultipartFormData() async throws {
        var multipartBody = ""
        MockURLProtocol.handler = { request in
            multipartBody = String(data: try XCTUnwrap(request.httpBody), encoding: .utf8) ?? ""
            XCTAssertTrue(request.value(forHTTPHeaderField: "Content-Type")?.contains("multipart/form-data") == true)
            return try mockResponse(statusCode: 200, json: ["text": "hello world", "language": "en", "duration": 1.2])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-transcribe", session: .mock)
        let result = try await transcribe(
            model: provider,
            audio: AIAudioInput(data: Data("audio".utf8), filename: "clip.wav", mediaType: .wav),
            options: TranscriptionOptions(language: "en", prompt: "Clean transcript")
        )

        XCTAssertTrue(multipartBody.contains("name=\"model\""))
        XCTAssertTrue(multipartBody.contains("gpt-4o-transcribe"))
        XCTAssertTrue(multipartBody.contains("name=\"file\"; filename=\"clip.wav\""))
        XCTAssertTrue(multipartBody.contains("Content-Type: audio/wav"))
        XCTAssertEqual(result.text, "hello world")
        XCTAssertEqual(result.language, "en")
        XCTAssertEqual(result.duration, 1.2)
    }

    func testOpenAISpeechReturnsBinaryAudio() async throws {
        var body: [String: Any]?
        MockURLProtocol.handler = { request in
            body = try Self.jsonBody(from: request)
            return Self.dataResponse(statusCode: 200, data: Data("mp3".utf8), contentType: "audio/mpeg")
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini-tts", session: .mock)
        let response = try await generateSpeech(
            model: provider,
            text: "Hello",
            options: SpeechOptions(voice: "alloy", format: .mp3, speed: 1.1, instructions: "Warm")
        )

        XCTAssertEqual(body?["model"] as? String, "gpt-4o-mini-tts")
        XCTAssertEqual(body?["input"] as? String, "Hello")
        XCTAssertEqual(body?["voice"] as? String, "alloy")
        XCTAssertEqual(body?["response_format"] as? String, "mp3")
        XCTAssertEqual(body?["instructions"] as? String, "Warm")
        XCTAssertEqual(response.data, Data("mp3".utf8))
        XCTAssertEqual(response.format, .mp3)
    }

    func testOpenAIVideoCreatesPollsAndDownloads() async throws {
        var requestedURLs: [String] = []
        MockURLProtocol.handler = { request in
            requestedURLs.append(request.url?.absoluteString ?? "")
            switch requestedURLs.count {
            case 1:
                return try mockResponse(statusCode: 200, json: ["id": "video_1", "status": "queued", "model": "sora-2"])
            case 2:
                return try mockResponse(statusCode: 200, json: ["id": "video_1", "status": "completed", "model": "sora-2"])
            default:
                return Self.dataResponse(statusCode: 200, data: Data("mp4".utf8), contentType: "video/mp4")
            }
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "sora-2", session: .mock)
        let response = try await generateVideo(
            model: provider,
            prompt: "A logo animation",
            options: VideoGenerationOptions(size: "1280x720", seconds: 8, pollInterval: .zero, maxPollAttempts: 2)
        )

        XCTAssertEqual(requestedURLs, [
            "https://api.openai.com/v1/videos",
            "https://api.openai.com/v1/videos/video_1",
            "https://api.openai.com/v1/videos/video_1/content",
        ])
        XCTAssertEqual(response.data, Data("mp4".utf8))
        XCTAssertEqual(response.id, "video_1")
    }

    func testOpenAIImageGenerationThrowsInvalidResponseForEmptyImages() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["data": [["revised_prompt": "better"]]])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-image-1", session: .mock)

        do {
            _ = try await generateImage(model: provider, prompt: "Robot")
            XCTFail("Expected invalid response")
        } catch AIError.invalidResponse {}
    }

    func testOpenAITranscriptionThrowsOnInvalidJSONResponse() async throws {
        MockURLProtocol.handler = { _ in
            Self.dataResponse(statusCode: 200, data: Data("not json".utf8), contentType: "application/json")
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-transcribe", session: .mock)

        do {
            _ = try await transcribe(model: provider, audio: AIAudioInput(data: Data("audio".utf8), filename: "clip.wav", mediaType: .wav))
            XCTFail("Expected decoding error")
        } catch AIError.decodingError {}
    }

    func testOpenAISpeechThrowsAPIError() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 500, json: ["error": ["message": "speech failed"]])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "gpt-4o-mini-tts", session: .mock)

        do {
            _ = try await generateSpeech(model: provider, text: "Hello")
            XCTFail("Expected API error")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 500)
            XCTAssertEqual(message, "speech failed")
        }
    }

    func testOpenAIVideoThrowsWhenJobFails() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["id": "video_1", "status": "failed", "error": ["message": "render failed"]])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "sora-2", session: .mock)

        do {
            _ = try await generateVideo(model: provider, prompt: "Logo", options: VideoGenerationOptions(pollInterval: .zero, maxPollAttempts: 1))
            XCTFail("Expected failed video job")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 500)
            XCTAssertEqual(message, "render failed")
        }
    }

    func testOpenAIVideoThrowsWhenPollingTimesOut() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["id": "video_1", "status": "queued"])
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: "test", model: "sora-2", session: .mock)

        do {
            _ = try await generateVideo(model: provider, prompt: "Logo", options: VideoGenerationOptions(pollInterval: .zero, maxPollAttempts: 1))
            XCTFail("Expected timeout")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 408)
            XCTAssertTrue(message.contains("did not complete"))
        }
    }

    func testGeminiImageGenerationEncodesImagenParameters() async throws {
        var body: [String: Any]?
        MockURLProtocol.handler = { request in
            body = try Self.jsonBody(from: request)
            return try mockResponse(
                statusCode: 200,
                json: [
                    "predictions": [
                        ["bytesBase64Encoded": Data("png".utf8).base64EncodedString(), "mimeType": "image/png"]
                    ]
                ]
            )
        }

        let provider = GeminiProvider(apiKey: "test", model: "imagen-4.0-generate-001", session: .mock)
        let response = try await generateImage(
            model: provider,
            prompt: "Robot",
            options: ImageGenerationOptions(count: 1, size: "1K", aspectRatio: "16:9", personGeneration: "dont_allow")
        )

        let instances = try XCTUnwrap(body?["instances"] as? [[String: Any]])
        let parameters = try XCTUnwrap(body?["parameters"] as? [String: Any])
        XCTAssertEqual(instances.first?["prompt"] as? String, "Robot")
        XCTAssertEqual(parameters["sampleCount"] as? Int, 1)
        XCTAssertEqual(parameters["imageSize"] as? String, "1K")
        XCTAssertEqual(parameters["aspectRatio"] as? String, "16:9")
        XCTAssertEqual(response.images.first?.data, Data("png".utf8))
    }

    func testGeminiSpeechEncodesAudioModalityAndVoice() async throws {
        var body: [String: Any]?
        MockURLProtocol.handler = { request in
            body = try Self.jsonBody(from: request)
            return try mockResponse(
                statusCode: 200,
                json: [
                    "candidates": [
                        [
                            "content": [
                                "parts": [
                                    ["inlineData": ["mimeType": "audio/pcm", "data": Data("pcm".utf8).base64EncodedString()]]
                                ]
                            ]
                        ]
                    ]
                ]
            )
        }

        let provider = GeminiProvider(apiKey: "test", model: "gemini-3.1-flash-tts-preview", session: .mock)
        let response = try await generateSpeech(model: provider, text: "Hello", options: SpeechOptions(voice: "Kore", format: .pcm))

        let generationConfig = try XCTUnwrap(body?["generationConfig"] as? [String: Any])
        XCTAssertEqual(generationConfig["responseModalities"] as? [String], ["AUDIO"])
        XCTAssertEqual(response.data, Data("pcm".utf8))
        XCTAssertEqual(response.format, .pcm)
    }

    func testGeminiVideoCreatesOperationPollsAndDownloads() async throws {
        var requestedURLs: [String] = []
        MockURLProtocol.handler = { request in
            requestedURLs.append(request.url?.absoluteString ?? "")
            switch requestedURLs.count {
            case 1:
                return try mockResponse(statusCode: 200, json: ["name": "operations/video_1", "done": false])
            case 2:
                return try mockResponse(
                    statusCode: 200,
                    json: [
                        "name": "operations/video_1",
                        "done": true,
                        "response": [
                            "generateVideoResponse": [
                                "generatedSamples": [
                                    ["video": ["uri": "https://files.example.com/video.mp4"]]
                                ]
                            ]
                        ],
                    ]
                )
            default:
                return Self.dataResponse(statusCode: 200, data: Data("mp4".utf8), contentType: "video/mp4")
            }
        }

        let provider = GeminiProvider(apiKey: "test", model: "veo-3.1-generate-preview", session: .mock)
        let response = try await generateVideo(
            model: provider,
            prompt: "A cinematic lion",
            options: VideoGenerationOptions(aspectRatio: "16:9", negativePrompt: "cartoon", pollInterval: .zero, maxPollAttempts: 2)
        )

        XCTAssertEqual(requestedURLs, [
            "https://generativelanguage.googleapis.com/v1beta/models/veo-3.1-generate-preview:predictLongRunning",
            "https://generativelanguage.googleapis.com/v1beta/operations/video_1",
            "https://files.example.com/video.mp4",
        ])
        XCTAssertEqual(response.data, Data("mp4".utf8))
    }

    func testGeminiImageGenerationThrowsForEmptyPredictions() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["predictions": []])
        }

        let provider = GeminiProvider(apiKey: "test", model: "imagen-4.0-generate-001", session: .mock)

        do {
            _ = try await generateImage(model: provider, prompt: "Robot")
            XCTFail("Expected invalid response")
        } catch AIError.invalidResponse {}
    }

    func testGeminiImageGenerationThrowsForInvalidBase64() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["predictions": [["bytesBase64Encoded": "not-base64", "mimeType": "image/png"]]])
        }

        let provider = GeminiProvider(apiKey: "test", model: "imagen-4.0-generate-001", session: .mock)

        do {
            _ = try await generateImage(model: provider, prompt: "Robot")
            XCTFail("Expected invalid response")
        } catch AIError.invalidResponse {}
    }

    func testGeminiSpeechThrowsWhenInlineDataIsMissing() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["candidates": [["content": ["parts": [["text": "no audio"]]]]]])
        }

        let provider = GeminiProvider(apiKey: "test", model: "gemini-3.1-flash-tts-preview", session: .mock)

        do {
            _ = try await generateSpeech(model: provider, text: "Hello")
            XCTFail("Expected invalid response")
        } catch AIError.invalidResponse {}
    }

    func testGeminiVideoThrowsOperationError() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["name": "operations/video_1", "done": true, "error": ["code": 400, "message": "bad prompt"]])
        }

        let provider = GeminiProvider(apiKey: "test", model: "veo-3.1-generate-preview", session: .mock)

        do {
            _ = try await generateVideo(model: provider, prompt: "bad", options: VideoGenerationOptions(pollInterval: .zero, maxPollAttempts: 1))
            XCTFail("Expected operation error")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 400)
            XCTAssertEqual(message, "bad prompt")
        }
    }

    func testGeminiVideoThrowsWhenPollingTimesOut() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["name": "operations/video_1", "done": false])
        }

        let provider = GeminiProvider(apiKey: "test", model: "veo-3.1-generate-preview", session: .mock)

        do {
            _ = try await generateVideo(model: provider, prompt: "Logo", options: VideoGenerationOptions(pollInterval: .zero, maxPollAttempts: 1))
            XCTFail("Expected timeout")
        } catch AIError.apiError(let statusCode, let message) {
            XCTAssertEqual(statusCode, 408)
            XCTAssertTrue(message.contains("did not complete"))
        }
    }

    func testGeminiVideoThrowsWhenCompletedOperationHasNoURI() async throws {
        MockURLProtocol.handler = { _ in
            try mockResponse(statusCode: 200, json: ["name": "operations/video_1", "done": true, "response": ["generatedVideos": []]])
        }

        let provider = GeminiProvider(apiKey: "test", model: "veo-3.1-generate-preview", session: .mock)

        do {
            _ = try await generateVideo(model: provider, prompt: "Logo", options: VideoGenerationOptions(pollInterval: .zero, maxPollAttempts: 1))
            XCTFail("Expected invalid response")
        } catch AIError.invalidResponse {}
    }

    func testLiveOpenAIImageGeneration() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let apiKey = env["OPENAI_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set OPENAI_API_KEY to run live OpenAI image generation test.")
        }
        guard let modelName = env["OPENAI_IMAGE_MODEL"], !modelName.isEmpty else {
            throw XCTSkip("Set OPENAI_IMAGE_MODEL to run live OpenAI image generation test.")
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: apiKey, model: modelName)

        do {
            let response = try await generateImage(
                model: provider,
                prompt: "A tiny blue square icon.",
                options: ImageGenerationOptions(count: 1, size: .square1024, format: .png)
            )
            XCTAssertFalse(response.images.isEmpty)
        } catch {
            try skipLiveProviderError(error, provider: "OpenAI image")
        }
    }

    func testLiveOpenAISpeechGeneration() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let apiKey = env["OPENAI_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set OPENAI_API_KEY to run live OpenAI speech test.")
        }
        guard let modelName = env["OPENAI_SPEECH_MODEL"], !modelName.isEmpty else {
            throw XCTSkip("Set OPENAI_SPEECH_MODEL to run live OpenAI speech test.")
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: apiKey, model: modelName)

        do {
            let response = try await generateSpeech(model: provider, text: "Hello from SwiftyAI tests.", options: SpeechOptions(format: .mp3))
            XCTAssertFalse(response.data.isEmpty)
        } catch {
            try skipLiveProviderError(error, provider: "OpenAI speech")
        }
    }

    func testLiveOpenAITranscription() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let apiKey = env["OPENAI_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set OPENAI_API_KEY to run live OpenAI transcription test.")
        }
        guard let modelName = env["OPENAI_TRANSCRIPTION_MODEL"], !modelName.isEmpty else {
            throw XCTSkip("Set OPENAI_TRANSCRIPTION_MODEL to run live OpenAI transcription test.")
        }
        guard let samplePath = env["OPENAI_TRANSCRIPTION_SAMPLE_PATH"], !samplePath.isEmpty else {
            throw XCTSkip("Set OPENAI_TRANSCRIPTION_SAMPLE_PATH to a local audio file for live OpenAI transcription test.")
        }

        let audioURL = URL(fileURLWithPath: samplePath)
        let audioData = try Data(contentsOf: audioURL)
        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: apiKey, model: modelName)

        do {
            let response = try await transcribe(
                model: provider,
                audio: AIAudioInput(data: audioData, filename: audioURL.lastPathComponent, mediaType: .wav)
            )
            XCTAssertFalse(response.text.isEmpty)
        } catch {
            try skipLiveProviderError(error, provider: "OpenAI transcription")
        }
    }

    func testLiveOpenAIVideoGeneration() async throws {
        let env = ProcessInfo.processInfo.environment
        guard env["RUN_EXPENSIVE_LIVE_MEDIA_TESTS"] == "1" else {
            throw XCTSkip("Set RUN_EXPENSIVE_LIVE_MEDIA_TESTS=1 to run live video generation tests.")
        }
        guard let apiKey = env["OPENAI_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set OPENAI_API_KEY to run live OpenAI video test.")
        }
        guard let modelName = env["OPENAI_VIDEO_MODEL"], !modelName.isEmpty else {
            throw XCTSkip("Set OPENAI_VIDEO_MODEL to run live OpenAI video test.")
        }

        let provider = OpenAICompatibleProvider(baseURL: "https://api.openai.com/v1", apiKey: apiKey, model: modelName)

        do {
            let response = try await generateVideo(
                model: provider,
                prompt: "A simple animated blue square.",
                options: VideoGenerationOptions(seconds: 4, pollInterval: .seconds(5), maxPollAttempts: 60)
            )
            XCTAssertFalse(response.data.isEmpty)
        } catch {
            try skipLiveProviderError(error, provider: "OpenAI video")
        }
    }

    func testLiveGeminiImageGeneration() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let apiKey = env["GEMINI_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set GEMINI_API_KEY to run live Gemini image test.")
        }
        guard let modelName = env["GEMINI_IMAGE_MODEL"], !modelName.isEmpty else {
            throw XCTSkip("Set GEMINI_IMAGE_MODEL to run live Gemini image test.")
        }

        let provider = GeminiProvider(apiKey: apiKey, model: modelName)

        do {
            let response = try await generateImage(model: provider, prompt: "A tiny blue square icon.", options: ImageGenerationOptions(count: 1))
            XCTAssertFalse(response.images.isEmpty)
        } catch {
            try skipLiveProviderError(error, provider: "Gemini image")
        }
    }

    func testLiveGeminiSpeechGeneration() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let apiKey = env["GEMINI_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set GEMINI_API_KEY to run live Gemini speech test.")
        }
        guard let modelName = env["GEMINI_SPEECH_MODEL"], !modelName.isEmpty else {
            throw XCTSkip("Set GEMINI_SPEECH_MODEL to run live Gemini speech test.")
        }

        let provider = GeminiProvider(apiKey: apiKey, model: modelName)

        do {
            let response = try await generateSpeech(model: provider, text: "Hello from SwiftyAI tests.", options: SpeechOptions(voice: "Kore", format: .pcm))
            XCTAssertFalse(response.data.isEmpty)
        } catch {
            try skipLiveProviderError(error, provider: "Gemini speech")
        }
    }

    func testLiveGeminiVideoGeneration() async throws {
        let env = ProcessInfo.processInfo.environment
        guard env["RUN_EXPENSIVE_LIVE_MEDIA_TESTS"] == "1" else {
            throw XCTSkip("Set RUN_EXPENSIVE_LIVE_MEDIA_TESTS=1 to run live video generation tests.")
        }
        guard let apiKey = env["GEMINI_API_KEY"], !apiKey.isEmpty else {
            throw XCTSkip("Set GEMINI_API_KEY to run live Gemini video test.")
        }
        guard let modelName = env["GEMINI_VIDEO_MODEL"], !modelName.isEmpty else {
            throw XCTSkip("Set GEMINI_VIDEO_MODEL to run live Gemini video test.")
        }

        let provider = GeminiProvider(apiKey: apiKey, model: modelName)

        do {
            let response = try await generateVideo(
                model: provider,
                prompt: "A simple animated blue square.",
                options: VideoGenerationOptions(aspectRatio: "16:9", pollInterval: .seconds(5), maxPollAttempts: 60)
            )
            XCTAssertFalse(response.data.isEmpty)
        } catch {
            try skipLiveProviderError(error, provider: "Gemini video")
        }
    }

    private static func jsonBody(from request: URLRequest) throws -> [String: Any] {
        let data = try XCTUnwrap(request.httpBody)
        let value = try JSONSerialization.jsonObject(with: data)
        return try XCTUnwrap(value as? [String: Any])
    }

    private static func dataResponse(statusCode: Int, data: Data, contentType: String) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: URL(string: "https://mock")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": contentType]
        )!
        return (response, data)
    }
}

private final class CapturingImageModel: AIImageModel, @unchecked Sendable {
    private(set) var capturedPrompt: String?

    func generateImage(prompt: String, options: ImageGenerationOptions) async throws -> ImageResponse {
        capturedPrompt = prompt
        return ImageResponse(images: [GeneratedImage(data: Data(), base64: nil, url: nil)])
    }
}
