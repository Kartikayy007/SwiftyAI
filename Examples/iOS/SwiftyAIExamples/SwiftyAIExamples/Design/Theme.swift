import SwiftUI

enum Theme {
    static let contentWidth: CGFloat = 860
    static let controlRadius: CGFloat = 8
    static let panelBackground = Color(.secondarySystemGroupedBackground)
    static let mutedBackground = Color(.tertiarySystemGroupedBackground)
}

extension View {
    func examplePage() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                self
            }
            .frame(maxWidth: Theme.contentWidth, alignment: .leading)
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
    }
}
