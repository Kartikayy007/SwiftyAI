import SwiftUI

struct PromptEditor: View {
    let title: String
    @Binding var text: String
    var minHeight: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))

            TextEditor(text: $text)
                .frame(minHeight: minHeight)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                }
        }
    }
}
