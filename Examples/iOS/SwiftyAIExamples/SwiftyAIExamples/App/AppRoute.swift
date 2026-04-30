import Foundation
import SwiftUI

enum AppRoute: String, CaseIterable, Identifiable {
    case generateText
    case streamText
    case multimodal
    case generateObject
    case chat
    case aiChatHook
    case aiCompletionHook
    case embeddings
    case tools
    case options

    var id: String { rawValue }

    var title: String {
        switch self {
        case .generateText: "Generate Text"
        case .streamText: "Stream Text"
        case .multimodal: "Multimodal"
        case .generateObject: "Generate Object"
        case .chat: "Chat"
        case .aiChatHook: "AIChat Hook"
        case .aiCompletionHook: "AICompletion Hook"
        case .embeddings: "Embeddings"
        case .tools: "Tools"
        case .options: "Generation Options"
        }
    }

    var subtitle: String {
        switch self {
        case .generateText: "One-shot text generation"
        case .streamText: "Live token streaming"
        case .multimodal: "Images, PDFs, audio, video, and files"
        case .generateObject: "Schema-shaped Swift values"
        case .chat: "Stateful streaming chat"
        case .aiChatHook: "SwiftUI chat state hook"
        case .aiCompletionHook: "SwiftUI completion state hook"
        case .embeddings: "Vector similarity search"
        case .tools: "Function calling and agent steps"
        case .options: "Temperature, limits, retry, caching"
        }
    }

    var symbolName: String {
        switch self {
        case .generateText: "text.quote"
        case .streamText: "dot.radiowaves.left.and.right"
        case .multimodal: "photo.on.rectangle.angled"
        case .generateObject: "curlybraces.square"
        case .chat: "bubble.left.and.bubble.right"
        case .aiChatHook: "bubble.left.and.bubble.right"
        case .aiCompletionHook: "text.quote"
        case .embeddings: "square.grid.3x3"
        case .tools: "wrench.and.screwdriver"
        case .options: "slider.horizontal.3"
        }
    }
}
