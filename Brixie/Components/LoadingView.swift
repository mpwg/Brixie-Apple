import SwiftUI

struct LoadingView: View {
    let message: String
    let isError: Bool
    
    @State private var animationPhase = 0.0
    
    var body: some View {
        VStack(spacing: 16) {
            if isError {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .accessibilityLabel("Error")
                    .scaleEffect(1.0 + sin(animationPhase) * 0.1)
                    .animation(
                        Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: animationPhase
                    )
                Text(message)
                    .foregroundColor(.red)
                    .accessibilityIdentifier("errorMessage")
            } else {
                ProgressView()
                    .scaleEffect(1.2)
                    .accessibilityHidden(true)
                Text(message)
                    .accessibilityIdentifier("progressMessage")
                SkeletonView()
            }
        }
        .padding()
        .transition(.opacity.combined(with: .scale))
        .accessibilityElement(children: .contain)
        .onAppear {
            if isError {
                animationPhase = 1.0
                #if canImport(UIKit)
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.error)
                #endif
            }
        }
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
