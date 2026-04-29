import Foundation

extension OpenAICompatibleProvider {
    public func generateImage(prompt: String, options: ImageGenerationOptions) async throws -> ImageResponse {
        guard let url = URL(string: "\(baseURL)/images/generations") else {
            throw AIError.invalidResponse
        }

        let body = ImageRequest(
            model: model,
            prompt: prompt,
            n: options.count,
            size: options.size?.rawValue,
            quality: options.quality?.rawValue,
            outputFormat: options.format?.rawValue,
            outputCompression: options.compression,
            background: options.background?.rawValue
        )
        let data = try await httpPost(
            url: url,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: body,
            session: session,
            options: options.generationOptions
        )
        let decoded = try decode(ImageResponsePayload.self, from: data)
        let mediaType = options.format?.mediaType ?? .png
        let images = decoded.data.compactMap { item -> GeneratedImage? in
            let rawData = item.b64JSON.flatMap { Data(base64Encoded: $0) }
            let url = item.url.flatMap(URL.init(string:))
            if rawData == nil && url == nil { return nil }
            return GeneratedImage(
                data: rawData,
                base64: item.b64JSON,
                url: url,
                mediaType: mediaType,
                revisedPrompt: item.revisedPrompt
            )
        }
        guard !images.isEmpty else { throw AIError.invalidResponse }
        return ImageResponse(images: images, model: model)
    }

    public func transcribe(_ audio: AIAudioInput, options: TranscriptionOptions) async throws -> TranscriptionResponse {
        guard let url = URL(string: "\(baseURL)/audio/transcriptions") else {
            throw AIError.invalidResponse
        }

        var multipart = MultipartFormData()
        multipart.appendField(name: "model", value: model)
        multipart.appendField(name: "response_format", value: options.responseFormat.rawValue)
        if let language = options.language { multipart.appendField(name: "language", value: language) }
        if let prompt = options.prompt { multipart.appendField(name: "prompt", value: prompt) }
        if let temperature = options.temperature { multipart.appendField(name: "temperature", value: String(temperature)) }
        multipart.appendFile(name: "file", filename: audio.filename, mediaType: audio.mediaType, data: audio.data)

        let data = try await httpPostData(
            url: url,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: multipart.finalize(),
            contentType: multipart.contentType,
            session: session,
            options: options.generationOptions
        )

        switch options.responseFormat {
        case .json, .verboseJSON:
            let decoded = try decode(TranscriptionPayload.self, from: data)
            return TranscriptionResponse(text: decoded.text, language: decoded.language, duration: decoded.duration, model: model)
        case .text, .srt, .vtt:
            guard let text = String(data: data, encoding: .utf8) else { throw AIError.invalidResponse }
            return TranscriptionResponse(text: text, model: model)
        }
    }

    public func generateSpeech(_ text: String, options: SpeechOptions) async throws -> SpeechResponse {
        guard let url = URL(string: "\(baseURL)/audio/speech") else {
            throw AIError.invalidResponse
        }

        let body = SpeechRequest(
            model: model,
            input: text,
            voice: options.voice,
            responseFormat: options.format.rawValue,
            speed: options.speed,
            instructions: options.instructions
        )
        let data = try await httpPost(
            url: url,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: body,
            session: session,
            options: options.generationOptions
        )
        return SpeechResponse(data: data, format: options.format, mediaType: options.format.mediaType, model: model)
    }

    public func generateVideo(prompt: String, options: VideoGenerationOptions) async throws -> VideoResponse {
        guard let createURL = URL(string: "\(baseURL)/videos") else {
            throw AIError.invalidResponse
        }

        let create = VideoCreateRequest(
            model: model,
            prompt: prompt,
            size: options.size?.rawValue,
            seconds: options.seconds
        )
        let createData = try await httpPost(
            url: createURL,
            headers: ["Authorization": "Bearer \(apiKey)"],
            body: create,
            session: session,
            options: options.generationOptions
        )
        var job = try decode(VideoJobPayload.self, from: createData)

        for _ in 0..<options.maxPollAttempts {
            if job.status == "completed" { break }
            if job.status == "failed" {
                throw AIError.apiError(statusCode: 500, message: job.error?.message ?? "Video generation failed")
            }
            if options.pollInterval != .zero {
                try await Task.sleep(for: options.pollInterval)
            }
            guard let statusURL = URL(string: "\(baseURL)/videos/\(job.id)") else {
                throw AIError.invalidResponse
            }
            let statusData = try await httpGetData(
                url: statusURL,
                headers: ["Authorization": "Bearer \(apiKey)"],
                session: session,
                options: options.generationOptions
            )
            job = try decode(VideoJobPayload.self, from: statusData)
        }

        guard job.status == "completed" else {
            throw AIError.apiError(statusCode: 408, message: "Video generation did not complete before maxPollAttempts")
        }
        guard let contentURL = URL(string: "\(baseURL)/videos/\(job.id)/content") else {
            throw AIError.invalidResponse
        }
        let videoData = try await httpGetData(
            url: contentURL,
            headers: ["Authorization": "Bearer \(apiKey)"],
            session: session,
            options: options.generationOptions
        )
        return VideoResponse(id: job.id, data: videoData, model: job.model ?? model, status: job.status)
    }
}

private struct ImageRequest: Encodable {
    let model: String
    let prompt: String
    let n: Int?
    let size: String?
    let quality: String?
    let outputFormat: String?
    let outputCompression: Int?
    let background: String?

    enum CodingKeys: String, CodingKey {
        case model, prompt, n, size, quality, background
        case outputFormat = "output_format"
        case outputCompression = "output_compression"
    }
}

private struct ImageResponsePayload: Decodable {
    let data: [ImageData]

    struct ImageData: Decodable {
        let b64JSON: String?
        let url: String?
        let revisedPrompt: String?

        enum CodingKeys: String, CodingKey {
            case b64JSON = "b64_json"
            case url
            case revisedPrompt = "revised_prompt"
        }
    }
}

private struct TranscriptionPayload: Decodable {
    let text: String
    let language: String?
    let duration: Double?
}

private struct SpeechRequest: Encodable {
    let model: String
    let input: String
    let voice: String
    let responseFormat: String
    let speed: Double?
    let instructions: String?

    enum CodingKeys: String, CodingKey {
        case model, input, voice, speed, instructions
        case responseFormat = "response_format"
    }
}

private struct VideoCreateRequest: Encodable {
    let model: String
    let prompt: String
    let size: String?
    let seconds: Int?
}

private struct VideoJobPayload: Decodable {
    let id: String
    let status: String
    let model: String?
    let progress: Double?
    let error: VideoError?

    struct VideoError: Decodable {
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
