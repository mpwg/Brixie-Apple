import SwiftUI

struct LoadingView: View {
    let message: String
    let isError: Bool
    
    @State private var animationPhase = 0.0
    
    var body: some View {
        VStack(spacing: AppConstants.UI.standardSpacing) {
            if isError {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.largeTitle)
                    .accessibilityLabel("Error")
                    .scaleEffect(1.0 + sin(animationPhase) * AppConstants.Animation.loadingScaleEffect)
                    .animation(
                        Animation.easeInOut(duration: AppConstants.Animation.long).repeatForever(autoreverses: true),
                        value: animationPhase
                    )
                Text(message)
                    .foregroundColor(.red)
                    .accessibilityIdentifier("errorMessage")
            } else {
                ProgressView()
                    .scaleEffect(AppConstants.Animation.pressedScale)
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
                animationPhase = AppConstants.Animation.long
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
        RoundedRectangle(cornerRadius: AppConstants.UI.smallCornerRadius)
            .fill(Color.gray.opacity(AppConstants.UI.skeletonOpacity))
            .frame(height: AppConstants.UI.skeletonHeight)
            .redacted(reason: .placeholder)
            .accessibilityHidden(true)
    }
}

#Preview {
    LoadingView(message: "Loading...", isError: false)
}
