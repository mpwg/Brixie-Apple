import SwiftUI

/// Animation constants and presets for consistent app-wide animations
@MainActor
struct AnimationPresets {
    // MARK: - Duration Constants
    static let quick = AppConstants.Animation.quick
    static let normal = AppConstants.Animation.normal
    static let slow = AppConstants.Animation.slow
    
    // MARK: - Spring Animations
    static let spring = AppConstants.CommonAnimations.springDefault
    static let bouncy = Animation.spring(response: AppConstants.Animation.bouncySpringResponse, dampingFraction: AppConstants.Animation.bouncySpringDamping, blendDuration: AppConstants.Numbers.zeroValue)
    static let gentle = Animation.spring(response: AppConstants.Animation.gentleSpringResponse, dampingFraction: AppConstants.Animation.gentleSpringDamping, blendDuration: AppConstants.Numbers.zeroValue)
    
    // MARK: - Easing Animations
    static let easeIn = Animation.easeIn(duration: AppConstants.Animation.normal)
    static let easeOut = Animation.easeOut(duration: AppConstants.Animation.normal)
    static let easeInOut = Animation.easeInOut(duration: AppConstants.Animation.normal)
    
    // MARK: - List Animations
    static let listInsert = Animation.easeOut(duration: AppConstants.Animation.listInsertDuration)
    static let listRemove = Animation.easeIn(duration: AppConstants.Animation.listRemoveDuration)
    
    // MARK: - Sheet Animations
    static let sheetPresent = Animation.easeOut(duration: AppConstants.Animation.sheetDuration)
    static let sheetDismiss = Animation.easeIn(duration: AppConstants.Animation.listRemoveDuration)
}

/// Custom view transitions for different presentation contexts
// ViewTransitions has been removed to avoid cross-actor AnyTransition initialization issues.
// Callers should use inline AnyTransition definitions (e.g. .asymmetric(insertion: .slide.combined(with: .opacity), removal: .opacity.combined(with: .scale))).

/// Animated view modifier for smooth state changes
struct AnimatedStateModifier<T: Equatable>: ViewModifier {
    let value: T
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .animation(animation, value: value)
    }
}

extension View {
    /// Applies animated state changes with specified animation
    func animatedState<T: Equatable>(_ value: T, animation: Animation = AnimationPresets.spring) -> some View {
        self.modifier(AnimatedStateModifier(value: value, animation: animation))
    }
    
    /// Applies gentle spring animation for UI state changes
    func gentleAnimation<T: Equatable>(_ value: T) -> some View {
        self.animation(AnimationPresets.gentle, value: value)
    }
    
    /// Applies bouncy animation for interactive elements
    func bouncyAnimation<T: Equatable>(_ value: T) -> some View {
        self.animation(AnimationPresets.bouncy, value: value)
    }
    
    /// Applies quick animation for rapid state changes
    func quickAnimation<T: Equatable>(_ value: T) -> some View {
        self.animation(.easeInOut(duration: AnimationPresets.quick), value: value)
    }
    
    /// Detects press events for custom interaction handling
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressEventModifier(onPress: onPress, onRelease: onRelease))
    }
}

/// Custom modifier to detect press and release events
struct PressEventModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                // No-op, just for gesture recognition
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress()
                    }
                    .onEnded { _ in
                        onRelease()
                    }
            )
    }
}

/// Loading animation with pulsing effect
struct PulseLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.accentColor)
            .frame(width: 20, height: 20)
            .scaleEffect(isAnimating ? AppConstants.Scale.pressed : AppConstants.Scale.small)
            .opacity(isAnimating ? AppConstants.Opacity.light : AppConstants.Opacity.visible)
            .animation(
                Animation.easeInOut(duration: AppConstants.Animation.longDuration).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

/// Shimmer loading effect for placeholder content
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .animation(
                    Animation.linear(duration: AppConstants.Animation.rotationDuration).repeatForever(autoreverses: false),
                    value: phase
                )
            )
            .onAppear {
                phase = 200
            }
    }
}

extension View {
    /// Adds shimmer loading effect to any view
    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }
}