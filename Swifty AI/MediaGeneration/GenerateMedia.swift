import Foundation

public func generateImage(
    model: some AIImageModel,
    prompt: String,
    options: ImageGenerationOptions = ImageGenerationOptions()
) async throws -> ImageResponse {
    try await model.generateImage(prompt: prompt, options: options)
}

public func generateImage(
    model: String,
    prompt: String,
    options: ImageGenerationOptions = ImageGenerationOptions()
) async throws -> ImageResponse {
    let resolved = try await AIRegistry.shared.resolveImageModel(model)
    return try await generateImage(model: resolved, prompt: prompt, options: options)
}

public func transcribe(
    model: some AITranscriptionModel,
    audio: AIAudioInput,
    options: TranscriptionOptions = TranscriptionOptions()
) async throws -> TranscriptionResponse {
    try await model.transcribe(audio, options: options)
}

public func transcribe(
    model: String,
    audio: AIAudioInput,
    options: TranscriptionOptions = TranscriptionOptions()
) async throws -> TranscriptionResponse {
    let resolved = try await AIRegistry.shared.resolveTranscriptionModel(model)
    return try await transcribe(model: resolved, audio: audio, options: options)
}

public func generateSpeech(
    model: some AISpeechModel,
    text: String,
    options: SpeechOptions = SpeechOptions()
) async throws -> SpeechResponse {
    try await model.generateSpeech(text, options: options)
}

public func generateSpeech(
    model: String,
    text: String,
    options: SpeechOptions = SpeechOptions()
) async throws -> SpeechResponse {
    let resolved = try await AIRegistry.shared.resolveSpeechModel(model)
    return try await generateSpeech(model: resolved, text: text, options: options)
}

public func generateVideo(
    model: some AIVideoModel,
    prompt: String,
    options: VideoGenerationOptions = VideoGenerationOptions()
) async throws -> VideoResponse {
    try await model.generateVideo(prompt: prompt, options: options)
}

public func generateVideo(
    model: String,
    prompt: String,
    options: VideoGenerationOptions = VideoGenerationOptions()
) async throws -> VideoResponse {
    let resolved = try await AIRegistry.shared.resolveVideoModel(model)
    return try await generateVideo(model: resolved, prompt: prompt, options: options)
}
