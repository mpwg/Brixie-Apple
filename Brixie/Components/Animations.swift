import SwiftUI

/// Animation constants and presets for consistent app-wide animations
struct AnimationPresets {
    // MARK: - Duration Constants
    static let quick = 0.2
    static let normal = 0.3
    static let slow = 0.5
    
    // MARK: - Spring Animations
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)
    static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0)
    static let gentle = Animation.spring(response: 0.8, dampingFraction: 1.0, blendDuration: 0)
    
    // MARK: - Easing Animations
    static let easeIn = Animation.easeIn(duration: normal)
    static let easeOut = Animation.easeOut(duration: normal)
    static let easeInOut = Animation.easeInOut(duration: normal)
    
    // MARK: - List Animations
    static let listInsert = Animation.easeOut(duration: 0.4)
    static let listRemove = Animation.easeIn(duration: 0.3)
    
    // MARK: - Sheet Animations
    static let sheetPresent = Animation.easeOut(duration: 0.4)
    static let sheetDismiss = Animation.easeIn(duration: 0.3)
}

/// Custom view transitions for different presentation contexts
struct ViewTransitions {
    // MARK: - Standard Transitions
    static let slide = AnyTransition.slide
    static let opacity = AnyTransition.opacity
    static let scale = AnyTransition.scale
    
    // MARK: - Custom Transitions
    static let slideAndFade = AnyTransition.asymmetric(
        insertion: .slide.combined(with: .opacity),
        removal: .opacity.combined(with: .scale)
    )
    
    static let cardPresentation = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity)
    )
    
    static let detailView = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
    )
    
    static let modalSheet = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom),
        removal: .move(edge: .bottom)
    )
}

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
            .scaleEffect(isAnimating ? 1.2 : 0.8)
            .opacity(isAnimating ? 0.3 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
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
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
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