import Foundation
import SwiftUI

enum AppRoute: String, CaseIterable, Identifiable {
    case generateText
    case streamText
    case generateObject
    case chat
    case tools
    case options

    var id: String { rawValue }

    var title: String {
        switch self {
        case .generateText: "Generate Text"
        case .streamText: "Stream Text"
        case .generateObject: "Generate Object"
        case .chat: "Chat"
        case .tools: "Tools"
        case .options: "Generation Options"
        }
    }

    var subtitle: String {
        switch self {
        case .generateText: "One-shot text generation"
        case .streamText: "Live token streaming"
        case .generateObject: "Schema-shaped Swift values"
        case .chat: "Stateful streaming chat"
        case .tools: "Function calling and agent steps"
        case .options: "Temperature, limits, retry, caching"
        }
    }

    var symbolName: String {
        switch self {
        case .generateText: "text.quote"
        case .streamText: "dot.radiowaves.left.and.right"
        case .generateObject: "curlybraces.square"
        case .chat: "bubble.left.and.bubble.right"
        case .tools: "wrench.and.screwdriver"
        case .options: "slider.horizontal.3"
        }
    }
}
