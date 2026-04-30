import Foundation

extension GeminiProvider {
    public func generateImage(prompt: String, options: ImageGenerationOptions) async throws -> ImageResponse {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):predict"
        guard let url = URL(string: urlString) else {
            throw AIError.invalidResponse
        }

        let body = GeminiImageRequest(
            instances: [.init(prompt: prompt)],
            parameters: .init(
                sampleCount: options.count,
                aspectRatio: options.aspectRatio,
                imageSize: options.size?.rawValue,
                personGeneration: options.personGeneration
            )
        )
        let data = try await httpPost(
            url: url,
            headers: ["x-goog-api-key": apiKey],
            body: body,
            session: session,
            options: options.generationOptions
        )
        let decoded = try decode(GeminiImageResponsePayload.self, from: data)
        let images = decoded.predictions.compactMap { prediction -> GeneratedImage? in
            guard let base64 = prediction.bytesBase64Encoded,
                  let rawData = Data(base64Encoded: base64) else {
                return nil
            }
            let mediaType = AIMediaType(rawValue: prediction.mimeType ?? "") ?? .png
            return GeneratedImage(data: rawData, base64: base64, url: nil, mediaType: mediaType)
        }
        guard !images.isEmpty else { throw AIError.invalidResponse }
        return ImageResponse(images: images, model: model)
    }

    public func transcribe(_ audio: AIAudioInput, options: TranscriptionOptions) async throws -> TranscriptionResponse {
        let instruction = options.prompt ?? "Transcribe the attached audio. Return only the transcript."
        let response = try await generate(
            [
                .text(instruction),
                .audioData(audio.data, mediaType: audio.mediaType, filename: audio.filename),
            ],
            options: options.generationOptions
        )
        return TranscriptionResponse(text: response.text, model: response.model ?? model)
    }

    public func generateSpeech(_ text: String, options: SpeechOptions) async throws -> SpeechResponse {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        guard let url = URL(string: urlString) else {
            throw AIError.invalidResponse
        }

        let voice = options.voice == "alloy" ? "Kore" : options.voice
        let body = GeminiSpeechRequest(
            contents: [.init(parts: [.init(text: text)])],
            generationConfig: .init(
                responseModalities: ["AUDIO"],
                speechConfig: .init(voiceConfig: .init(prebuiltVoiceConfig: .init(voiceName: voice)))
            ),
            model: model
        )
        let data = try await httpPost(
            url: url,
            headers: ["x-goog-api-key": apiKey],
            body: body,
            session: session,
            options: options.generationOptions
        )
        let decoded = try decode(GeminiSpeechResponsePayload.self, from: data)
        guard let inline = decoded.candidates.first?.content.parts.first?.inlineData,
              let rawData = Data(base64Encoded: inline.data) else {
            throw AIError.invalidResponse
        }
        let mediaType = AIMediaType(rawValue: inline.mimeType) ?? .pcm
        return SpeechResponse(data: rawData, format: .pcm, mediaType: mediaType, model: model)
    }

    public func generateVideo(prompt: String, options: VideoGenerationOptions) async throws -> VideoResponse {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):predictLongRunning"
        guard let startURL = URL(string: urlString) else {
            throw AIError.invalidResponse
        }

        let body = GeminiVideoStartRequest(
            instances: [.init(prompt: prompt)],
            parameters: .init(
                aspectRatio: options.aspectRatio,
                negativePrompt: options.negativePrompt,
                seed: options.seed
            )
        )
        let startData = try await httpPost(
            url: startURL,
            headers: ["x-goog-api-key": apiKey],
            body: body,
            session: session,
            options: options.generationOptions
        )
        var operation = try decode(GeminiVideoOperation.self, from: startData)

        for _ in 0..<options.maxPollAttempts {
            if operation.done == true { break }
            if options.pollInterval != .zero {
                try await Task.sleep(for: options.pollInterval)
            }
            guard let operationURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/\(operation.name)") else {
                throw AIError.invalidResponse
            }
            let operationData = try await httpGetData(
                url: operationURL,
                headers: ["x-goog-api-key": apiKey],
                session: session,
                options: options.generationOptions
            )
            operation = try decode(GeminiVideoOperation.self, from: operationData)
        }

        guard operation.done == true else {
            throw AIError.apiError(statusCode: 408, message: "Video generation did not complete before maxPollAttempts")
        }
        if let error = operation.error {
            throw AIError.apiError(statusCode: error.code ?? 500, message: error.message ?? "Video generation failed")
        }
        guard let uri = operation.videoURI, let downloadURL = URL(string: uri) else {
            throw AIError.invalidResponse
        }
        let videoData = try await httpGetData(
            url: downloadURL,
            headers: ["x-goog-api-key": apiKey],
            session: session,
            options: options.generationOptions
        )
        return VideoResponse(id: operation.name, data: videoData, model: model, status: "completed")
    }
}

private struct GeminiImageRequest: Encodable {
    let instances: [Instance]
    let parameters: Parameters

    struct Instance: Encodable {
        let prompt: String
    }

    struct Parameters: Encodable {
        let sampleCount: Int?
        let aspectRatio: String?
        let imageSize: String?
        let personGeneration: String?
    }
}

private struct GeminiImageResponsePayload: Decodable {
    let predictions: [Prediction]

    struct Prediction: Decodable {
        let bytesBase64Encoded: String?
        let mimeType: String?
    }
}

private struct GeminiSpeechRequest: Encodable {
    let contents: [Content]
    let generationConfig: GenerationConfig
    let model: String

    struct Content: Encodable {
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String
    }

    struct GenerationConfig: Encodable {
        let responseModalities: [String]
        let speechConfig: SpeechConfig
    }

    struct SpeechConfig: Encodable {
        let voiceConfig: VoiceConfig
    }

    struct VoiceConfig: Encodable {
        let prebuiltVoiceConfig: PrebuiltVoiceConfig
    }

    struct PrebuiltVoiceConfig: Encodable {
        let voiceName: String
    }
}

private struct GeminiSpeechResponsePayload: Decodable {
    let candidates: [Candidate]

    struct Candidate: Decodable {
        let content: Content
    }

    struct Content: Decodable {
        let parts: [Part]
    }

    struct Part: Decodable {
        let inlineData: InlineData?

        enum CodingKeys: String, CodingKey {
            case inlineData = "inlineData"
        }
    }

    struct InlineData: Decodable {
        let mimeType: String
        let data: String
    }
}

private struct GeminiVideoStartRequest: Encodable {
    let instances: [Instance]
    let parameters: Parameters

    struct Instance: Encodable {
        let prompt: String
    }

    struct Parameters: Encodable {
        let aspectRatio: String?
        let negativePrompt: String?
        let seed: Int?
    }
}

private struct GeminiVideoOperation: Decodable {
    let name: String
    let done: Bool?
    let response: Response?
    let error: OperationError?

    var videoURI: String? {
        response?.generateVideoResponse?.generatedSamples.first?.video.uri
            ?? response?.generatedVideos.first?.video.uri
    }

    struct Response: Decodable {
        let generateVideoResponse: GenerateVideoResponse?
        let generatedVideos: [GeneratedVideo]

        enum CodingKeys: String, CodingKey {
            case generateVideoResponse
            case generatedVideos
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.generateVideoResponse = try container.decodeIfPresent(GenerateVideoResponse.self, forKey: .generateVideoResponse)
            self.generatedVideos = try container.decodeIfPresent([GeneratedVideo].self, forKey: .generatedVideos) ?? []
        }
    }

    struct GenerateVideoResponse: Decodable {
        let generatedSamples: [GeneratedVideo]
    }

    struct GeneratedVideo: Decodable {
        let video: Video
    }

    struct Video: Decodable {
        let uri: String
    }

    struct OperationError: Decodable {
        let code: Int?
        let message: String?
    }
}

private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    do {
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        throw AIError.decodingError(error)
    }
}
