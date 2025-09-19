import SwiftUI

struct LoadingView: View {
    let message: String
    let isError: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if isError {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .accessibilityLabel("Error")
                Text(message)
                    .foregroundColor(.red)
                    .accessibilityIdentifier("errorMessage")
            } else {
                ProgressView(message)
                    .accessibilityIdentifier("progressMessage")
                SkeletonView()
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
    }
}

struct SkeletonView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.15))
            .frame(height: 24)
            .redacted(reason: .placeholder)
            .accessibilityHidden(true)
    }
}

#Preview {
    LoadingView(message: "Loading...", isError: false)
}
