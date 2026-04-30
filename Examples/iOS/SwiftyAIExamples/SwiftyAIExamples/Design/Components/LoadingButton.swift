import SwiftUI

struct LoadingButton: View {
    let title: String
    let systemImage: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: isLoading ? "hourglass" : systemImage)
                .frame(minWidth: 120)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
    }
}
