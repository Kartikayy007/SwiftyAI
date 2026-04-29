import Foundation
import Observation
import SwiftyAI

enum MultimodalInputKind: String, CaseIterable, Identifiable {
    case imageURL
    case imageBase64
    case imageData
    case pdfURL
    case pdfData
    case audioData
    case videoURL
    case fileData

    var id: String { rawValue }

    var title: String {
        switch self {
        case .imageURL: "Image URL"
        case .imageBase64: "Image base64"
        case .imageData: "Image Data"
        case .pdfURL: "PDF URL"
        case .pdfData: "PDF Data"
        case .audioData: "Audio Data"
        case .videoURL: "Video URL"
        case .fileData: "File Data"
        }
    }
}

@MainActor
@Observable
final class MultimodalExampleViewModel {
    var prompt = "Analyze the attached input and return the key details."
    var systemPrompt = "You are concise and practical."
    var selectedKind: MultimodalInputKind = .imageURL
    var urlText = "https://upload.wikimedia.org/wikipedia/commons/3/3f/Fronalpstock_big.jpg"
    var responseText = ""
    var usage: TokenUsage?
    var finishReason: String?
    var state: ExampleState<Void> = .idle

    func select(_ kind: MultimodalInputKind) {
        selectedKind = kind
        switch kind {
        case .imageURL:
            urlText = "https://upload.wikimedia.org/wikipedia/commons/3/3f/Fronalpstock_big.jpg"
        case .pdfURL:
            urlText = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
        case .videoURL:
            urlText = "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
        default:
            break
        }
    }

    func run(settings: ProviderSettings, apiKey: String) async {
        state = .loading
        responseText = ""
        usage = nil
        finishReason = nil

        do {
            try validateProvider(settings.provider)
            let model = try ModelFactory.makeStreamModel(settings: settings, apiKey: apiKey)
            let response = try await generateText(
                model: model,
                prompt: try parts(),
                options: GenerationOptions(system: systemPrompt, temperature: 0.2, maxTokens: 360)
            )
            responseText = response.text
            usage = response.usage
            finishReason = response.finishReason
            state = .success(())
        } catch {
            state = .failure(error.exampleMessage)
        }
    }

    private func parts() throws -> [AIMessageContent] {
        [
            .text(prompt),
            try selectedContent(),
        ]
    }

    private func selectedContent() throws -> AIMessageContent {
        switch selectedKind {
        case .imageURL:
            return .imageURL(try url(), detail: .high)
        case .imageBase64:
            return .imageBase64(Self.onePixelPNGBase64, mediaType: .png, detail: .low)
        case .imageData:
            return .imageData(Data(base64Encoded: Self.onePixelPNGBase64) ?? Data(), mediaType: .png, detail: .low)
        case .pdfURL:
            return .pdfURL(try url(), filename: "sample.pdf")
        case .pdfData:
            return .pdfData(Self.tinyPDFData, filename: "sample.pdf")
        case .audioData:
            return .audioData(Self.tinyWAVData, mediaType: .wav, filename: "sample.wav")
        case .videoURL:
            return .videoURL(try url())
        case .fileData:
            return .fileData(Data(Self.plainTextAttachment.utf8), mediaType: .plainText, filename: "notes.txt")
        }
    }

    private func validateProvider(_ provider: AIProvider) throws {
        if provider == .anthropic {
            switch selectedKind {
            case .audioData, .videoURL, .fileData:
                throw ExampleError.message("Anthropic supports text, images, and PDFs in this SDK example.")
            default:
                break
            }
        }
    }

    private func url() throws -> URL {
        guard let url = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw ExampleError.message("Enter a valid URL.")
        }
        return url
    }

    private static let onePixelPNGBase64 =
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="

    private static let plainTextAttachment = """
    Release note:
    SwiftyAI now accepts multipart messages with text and media attachments.
    """

    private static let tinyPDFData = Data("""
    %PDF-1.1
    1 0 obj
    << /Type /Catalog /Pages 2 0 R >>
    endobj
    2 0 obj
    << /Type /Pages /Kids [3 0 R] /Count 1 >>
    endobj
    3 0 obj
    << /Type /Page /Parent 2 0 R /MediaBox [0 0 200 200] >>
    endobj
    trailer
    << /Root 1 0 R >>
    %%EOF
    """.utf8)

    private static let tinyWAVData = Data([
        0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00,
        0x57, 0x41, 0x56, 0x45, 0x66, 0x6d, 0x74, 0x20,
        0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00,
        0x40, 0x1f, 0x00, 0x00, 0x80, 0x3e, 0x00, 0x00,
        0x02, 0x00, 0x10, 0x00, 0x64, 0x61, 0x74, 0x61,
        0x00, 0x00, 0x00, 0x00,
    ])
}
