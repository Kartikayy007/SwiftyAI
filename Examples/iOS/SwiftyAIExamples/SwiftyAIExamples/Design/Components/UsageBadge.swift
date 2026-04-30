import SwiftUI
import SwiftyAI

struct UsageBadge: View {
    let usage: TokenUsage?
    let finishReason: String?

    var body: some View {
        HStack(spacing: 8) {
            if let usage {
                Label(usage.summary, systemImage: "number")
            }
            if let finishReason, !finishReason.isEmpty {
                Label(finishReason, systemImage: "flag.checkered")
            }
            if usage == nil && (finishReason == nil || finishReason?.isEmpty == true) {
                Text("No usage metadata yet")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Theme.mutedBackground)
        .clipShape(Capsule())
    }
}
