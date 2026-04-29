import Foundation

public struct ImageSize: RawRepresentable, Sendable, Codable, Equatable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public static let auto = ImageSize(rawValue: "auto")
    public static let square1024 = ImageSize(rawValue: "1024x1024")
    public static let landscape1536x1024 = ImageSize(rawValue: "1536x1024")
    public static let portrait1024x1536 = ImageSize(rawValue: "1024x1536")
}

public struct ImageQuality: RawRepresentable, Sendable, Codable, Equatable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public static let auto = ImageQuality(rawValue: "auto")
    public static let low = ImageQuality(rawValue: "low")
    public static let medium = ImageQuality(rawValue: "medium")
    public static let high = ImageQuality(rawValue: "high")
    public static let standard = ImageQuality(rawValue: "standard")
    public static let hd = ImageQuality(rawValue: "hd")
}

public enum ImageOutputFormat: String, Sendable, Codable {
    case png
    case jpeg
    case webp

    public var mediaType: AIMediaType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .webp: return .webp
        }
    }
}

public enum ImageBackground: String, Sendable, Codable {
    case auto
    case transparent
    case opaque
}

public struct ImageGenerationOptions: Sendable {
    public var count: Int?
    public var size: ImageSize?
    public var quality: ImageQuality?
    public var format: ImageOutputFormat?
    public var background: ImageBackground?
    public var compression: Int?
    public var aspectRatio: String?
    public var personGeneration: String?
    public var headers: [String: String]
    public var retryPolicy: RetryPolicy

    public init(
        count: Int? = nil,
        size: ImageSize? = nil,
        quality: ImageQuality? = nil,
        format: ImageOutputFormat? = nil,
        background: ImageBackground? = nil,
        compression: Int? = nil,
        aspectRatio: String? = nil,
        personGeneration: String? = nil,
        headers: [String: String] = [:],
        retryPolicy: RetryPolicy = .none
    ) {
        self.count = count
        self.size = size
        self.quality = quality
        self.format = format
        self.background = background
        self.compression = compression
        self.aspectRatio = aspectRatio
        self.personGeneration = personGeneration
        self.headers = headers
        self.retryPolicy = retryPolicy
    }

    var generationOptions: GenerationOptions {
        GenerationOptions(headers: headers, retryPolicy: retryPolicy)
    }
}

public struct GeneratedImage: Sendable {
    public let data: Data?
    public let base64: String?
    public let url: URL?
    public let mediaType: AIMediaType
    public let revisedPrompt: String?

    public init(
        data: Data?,
        base64: String?,
        url: URL?,
        mediaType: AIMediaType = .png,
        revisedPrompt: String? = nil
    ) {
        self.data = data
        self.base64 = base64
        self.url = url
        self.mediaType = mediaType
        self.revisedPrompt = revisedPrompt
    }
}

public struct ImageResponse: Sendable {
    public let images: [GeneratedImage]
    public let model: String?

    public init(images: [GeneratedImage], model: String? = nil) {
        self.images = images
        self.model = model
    }
}

public enum AudioFormat: String, Sendable, Codable {
    case mp3
    case opus
    case aac
    case flac
    case wav
    case pcm

    public var mediaType: AIMediaType {
        switch self {
        case .mp3: return .mp3
        case .opus: return .opus
        case .aac: return .aac
        case .flac: return .flac
        case .wav: return .wav
        case .pcm: return .pcm
        }
    }
}

public struct AIAudioInput: Sendable {
    public let data: Data
    public let filename: String
    public let mediaType: AIMediaType

    public init(data: Data, filename: String, mediaType: AIMediaType) {
        self.data = data
        self.filename = filename
        self.mediaType = mediaType
    }

    public init(base64: String, filename: String, mediaType: AIMediaType) throws {
        guard let data = Data(base64Encoded: base64) else {
            throw AIError.invalidResponse
        }
        self.init(data: data, filename: filename, mediaType: mediaType)
    }
}

public enum TranscriptionResponseFormat: String, Sendable, Codable {
    case json
    case text
    case srt
    case verboseJSON = "verbose_json"
    case vtt
}

public struct TranscriptionOptions: Sendable {
    public var language: String?
    public var prompt: String?
    public var responseFormat: TranscriptionResponseFormat
    public var temperature: Double?
    public var headers: [String: String]
    public var retryPolicy: RetryPolicy

    public init(
        language: String? = nil,
        prompt: String? = nil,
        responseFormat: TranscriptionResponseFormat = .json,
        temperature: Double? = nil,
        headers: [String: String] = [:],
        retryPolicy: RetryPolicy = .none
    ) {
        self.language = language
        self.prompt = prompt
        self.responseFormat = responseFormat
        self.temperature = temperature
        self.headers = headers
        self.retryPolicy = retryPolicy
    }

    var generationOptions: GenerationOptions {
        GenerationOptions(headers: headers, retryPolicy: retryPolicy)
    }
}

public struct TranscriptionResponse: Sendable {
    public let text: String
    public let language: String?
    public let duration: Double?
    public let model: String?

    public init(text: String, language: String? = nil, duration: Double? = nil, model: String? = nil) {
        self.text = text
        self.language = language
        self.duration = duration
        self.model = model
    }
}

public struct SpeechOptions: Sendable {
    public var voice: String
    public var format: AudioFormat
    public var speed: Double?
    public var instructions: String?
    public var headers: [String: String]
    public var retryPolicy: RetryPolicy

    public init(
        voice: String = "alloy",
        format: AudioFormat = .mp3,
        speed: Double? = nil,
        instructions: String? = nil,
        headers: [String: String] = [:],
        retryPolicy: RetryPolicy = .none
    ) {
        self.voice = voice
        self.format = format
        self.speed = speed
        self.instructions = instructions
        self.headers = headers
        self.retryPolicy = retryPolicy
    }

    var generationOptions: GenerationOptions {
        GenerationOptions(headers: headers, retryPolicy: retryPolicy)
    }
}

public struct SpeechResponse: Sendable {
    public let data: Data
    public let format: AudioFormat
    public let mediaType: AIMediaType
    public let model: String?

    public init(data: Data, format: AudioFormat, mediaType: AIMediaType, model: String? = nil) {
        self.data = data
        self.format = format
        self.mediaType = mediaType
        self.model = model
    }
}

public struct VideoGenerationOptions: Sendable {
    public var size: ImageSize?
    public var seconds: Int?
    public var aspectRatio: String?
    public var negativePrompt: String?
    public var seed: Int?
    public var pollInterval: Duration
    public var maxPollAttempts: Int
    public var headers: [String: String]
    public var retryPolicy: RetryPolicy

    public init(
        size: ImageSize? = nil,
        seconds: Int? = nil,
        aspectRatio: String? = nil,
        negativePrompt: String? = nil,
        seed: Int? = nil,
        pollInterval: Duration = .seconds(10),
        maxPollAttempts: Int = 60,
        headers: [String: String] = [:],
        retryPolicy: RetryPolicy = .none
    ) {
        self.size = size
        self.seconds = seconds
        self.aspectRatio = aspectRatio
        self.negativePrompt = negativePrompt
        self.seed = seed
        self.pollInterval = pollInterval
        self.maxPollAttempts = max(1, maxPollAttempts)
        self.headers = headers
        self.retryPolicy = retryPolicy
    }

    var generationOptions: GenerationOptions {
        GenerationOptions(headers: headers, retryPolicy: retryPolicy)
    }
}

public struct VideoResponse: Sendable {
    public let id: String?
    public let data: Data
    public let mediaType: AIMediaType
    public let model: String?
    public let status: String?

    public init(id: String?, data: Data, mediaType: AIMediaType = .mp4Video, model: String? = nil, status: String? = nil) {
        self.id = id
        self.data = data
        self.mediaType = mediaType
        self.model = model
        self.status = status
    }
}
