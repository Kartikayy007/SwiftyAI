import Foundation

public enum AIMediaType: String, Sendable, Codable {
    case png = "image/png"
    case jpeg = "image/jpeg"
    case gif = "image/gif"
    case webp = "image/webp"
    case pdf = "application/pdf"
    case wav = "audio/wav"
    case mp3 = "audio/mpeg"
    case mp4Audio = "audio/mp4"
    case mp4Video = "video/mp4"
    case mov = "video/quicktime"
    case plainText = "text/plain"
    case octetStream = "application/octet-stream"

    public var audioFormat: String {
        switch self {
        case .wav: return "wav"
        case .mp3: return "mp3"
        case .mp4Audio: return "mp4"
        default: return rawValue
        }
    }

    public static func infer(from url: URL) -> AIMediaType? {
        switch url.pathExtension.lowercased() {
        case "png": return .png
        case "jpg", "jpeg": return .jpeg
        case "gif": return .gif
        case "webp": return .webp
        case "pdf": return .pdf
        case "wav": return .wav
        case "mp3": return .mp3
        case "mp4": return .mp4Video
        case "mov": return .mov
        case "txt", "text": return .plainText
        default: return nil
        }
    }
}

public enum ImageDetail: String, Sendable, Codable {
    case auto
    case low
    case high
}

public enum AIMessageContent: Sendable {
    case text(String)
    case imageURL(URL, detail: ImageDetail? = nil)
    case imageBase64(String, mediaType: AIMediaType, detail: ImageDetail? = nil)
    case imageData(Data, mediaType: AIMediaType, detail: ImageDetail? = nil)
    case pdfURL(URL, filename: String? = nil)
    case pdfBase64(String, filename: String)
    case pdfData(Data, filename: String)
    case audioBase64(String, mediaType: AIMediaType, filename: String? = nil)
    case audioData(Data, mediaType: AIMediaType, filename: String? = nil)
    case videoURL(URL)
    case videoBase64(String, mediaType: AIMediaType, filename: String? = nil)
    case videoData(Data, mediaType: AIMediaType, filename: String? = nil)
    case fileURL(URL, mediaType: AIMediaType, filename: String? = nil)
    case fileBase64(String, mediaType: AIMediaType, filename: String)
    case fileData(Data, mediaType: AIMediaType, filename: String)

    public var textValue: String? {
        if case .text(let text) = self { return text }
        return nil
    }

    public var filename: String? {
        switch self {
        case .pdfURL(let url, let filename):
            return filename ?? url.lastPathComponent
        case .pdfBase64(_, let filename), .pdfData(_, let filename):
            return filename
        case .audioBase64(_, _, let filename), .audioData(_, _, let filename):
            return filename
        case .videoBase64(_, _, let filename), .videoData(_, _, let filename):
            return filename
        case .fileURL(let url, _, let filename):
            return filename ?? url.lastPathComponent
        case .fileBase64(_, _, let filename), .fileData(_, _, let filename):
            return filename
        default:
            return nil
        }
    }
}

extension AIMessageContent {
    var dataURL: String? {
        switch self {
        case .imageBase64(let base64, let mediaType, _),
             .audioBase64(let base64, let mediaType, _),
             .videoBase64(let base64, let mediaType, _),
             .fileBase64(let base64, let mediaType, _):
            return "data:\(mediaType.rawValue);base64,\(base64)"
        case .imageData(let data, let mediaType, _),
             .audioData(let data, let mediaType, _),
             .videoData(let data, let mediaType, _),
             .fileData(let data, let mediaType, _):
            return "data:\(mediaType.rawValue);base64,\(data.base64EncodedString())"
        case .pdfBase64(let base64, _):
            return "data:\(AIMediaType.pdf.rawValue);base64,\(base64)"
        case .pdfData(let data, _):
            return "data:\(AIMediaType.pdf.rawValue);base64,\(data.base64EncodedString())"
        default:
            return nil
        }
    }

    var rawBase64: String? {
        switch self {
        case .imageBase64(let base64, _, _),
             .audioBase64(let base64, _, _),
             .videoBase64(let base64, _, _),
             .fileBase64(let base64, _, _),
             .pdfBase64(let base64, _):
            return base64
        case .imageData(let data, _, _),
             .audioData(let data, _, _),
             .videoData(let data, _, _),
             .fileData(let data, _, _),
             .pdfData(let data, _):
            return data.base64EncodedString()
        default:
            return nil
        }
    }

    var mediaType: AIMediaType? {
        switch self {
        case .imageURL(let url, _):
            return AIMediaType.infer(from: url)
        case .imageBase64(_, let mediaType, _), .imageData(_, let mediaType, _):
            return mediaType
        case .pdfURL, .pdfBase64, .pdfData:
            return .pdf
        case .audioBase64(_, let mediaType, _), .audioData(_, let mediaType, _):
            return mediaType
        case .videoURL(let url):
            return AIMediaType.infer(from: url) ?? .mp4Video
        case .videoBase64(_, let mediaType, _), .videoData(_, let mediaType, _):
            return mediaType
        case .fileURL(_, let mediaType, _), .fileBase64(_, let mediaType, _), .fileData(_, let mediaType, _):
            return mediaType
        default:
            return nil
        }
    }
}

extension Array where Element == AIMessageContent {
    var textContent: String {
        compactMap(\.textValue).joined(separator: "\n")
    }
}
