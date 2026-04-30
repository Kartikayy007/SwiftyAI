import SwiftUI

struct ResponsePanel: View {
    let title: String
    let text: String
    var placeholder: String = "Run the example to see output."

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button {
                    ClipboardSupport.copy(text)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .disabled(text.isEmpty)
                .accessibilityLabel("Copy response")
            }

            Text(text.isEmpty ? placeholder : text)
                .font(.body.monospaced())
                .foregroundStyle(text.isEmpty ? .secondary : .primary)
                .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
                .padding(12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: Theme.controlRadius, style: .continuous))
                .textSelection(.enabled)
        }
    }
}
