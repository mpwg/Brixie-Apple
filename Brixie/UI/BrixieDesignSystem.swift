//
//  BrixieDesignSystem.swift
//  Brixie
//
//  Created by Claude on 05.09.25.
//

import SwiftUI

// MARK: Pure SwiftUI Colors (No UIKit/AppKit Dependencies)
extension Color {
    // Light Theme Colors
    static let brixieBackgroundLight = Color(red: 0.97, green: 0.97, blue: 0.99)
    static let brixieCardLight = Color(red: 1.0, green: 1.0, blue: 1.0)
    static let brixieTextLight = Color(red: 0.1, green: 0.1, blue: 0.15)
    static let brixieTextSecondaryLight = Color(red: 0.4, green: 0.4, blue: 0.5)
    static let brixieSecondaryLight = Color(red: 0.85, green: 0.85, blue: 0.9)
    
    // Dark Theme Colors
    static let brixieBackgroundDark = Color(red: 0.02, green: 0.02, blue: 0.06)
    static let brixieCardDark = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let brixieTextDark = Color.white
    static let brixieTextSecondaryDark = Color(red: 0.7, green: 0.7, blue: 0.8)
    static let brixieSecondaryDark = Color(red: 0.25, green: 0.25, blue: 0.35)
    
    // Shared Colors (same in both themes)
    static let brixieAccent = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let brixieSuccess = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let brixieWarning = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let brixieGradientStart = Color(red: 0.0, green: 0.35, blue: 0.8)
    static let brixieGradientEnd = Color(red: 0.2, green: 0.6, blue: 1.0)
}

// Helper functions to get adaptive colors based on ColorScheme
extension Color {
    static func brixieBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .brixieBackgroundDark : .brixieBackgroundLight
    }
    
    static func brixieCard(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .brixieCardDark : .brixieCardLight
    }
    
    static func brixieText(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .brixieTextDark : .brixieTextLight
    }
    
    static func brixieTextSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .brixieTextSecondaryDark : .brixieTextSecondaryLight
    }
    
    static func brixieSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .brixieSecondaryDark : .brixieSecondaryLight
    }
    
    static func brixieShadow(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.1)
    }
    
    // Convenience static properties that work with @Environment - fallback to dark theme
    static let brixieBackground = brixieBackgroundDark
    static let brixieCard = brixieCardDark  
    static let brixieText = brixieTextDark
    static let brixieTextSecondary = brixieTextSecondaryDark
    static let brixieSecondary = brixieSecondaryDark
}

// MARK: Gradients
extension LinearGradient {
    @MainActor static var brixiePrimary: LinearGradient {
        LinearGradient(
            colors: [.brixieGradientStart, .brixieGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    @MainActor static var brixieCard: LinearGradient {
        LinearGradient(
            colors: [Color.brixieCardDark, Color.brixieCardDark.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: Typography
extension Font {
    // Dynamic Type fonts that scale with user's accessibility settings
    static let brixieTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let brixieHeadline = Font.system(.title2, design: .rounded, weight: .semibold)
    static let brixieSubhead = Font.system(.headline, design: .rounded, weight: .medium)
    static let brixieBody = Font.system(.body, design: .default, weight: .regular)
    static let brixieCaption = Font.system(.caption, design: .default, weight: .medium)
}

// MARK: Shadows
extension View {
    func brixieCardShadow() -> some View {
        self.modifier(BrixieCardShadowModifier())
    }
}

// ViewModifier for adaptive card shadow
struct BrixieCardShadowModifier: ViewModifier {
    @Environment(\.colorScheme) 
    private var colorScheme
    
    func body(content: Content) -> some View {
        content.shadow(color: Color.brixieShadow(for: colorScheme), radius: BrixieScaledMetrics.shadowRadius, x: 0, y: 6)
    }
}

// ViewModifier for glow effect
struct BrixieGlowModifier: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content.shadow(color: color.opacity(0.6), radius: 8, x: 0, y: 0)
    }
}

// Extension to add glow effect
extension View {
    func brixieGlow(color: Color = .brixieAccent) -> some View {
        self.modifier(BrixieGlowModifier(color: color))
    }
}

// MARK: Card Styles
struct BrixieCard<Content: View>: View {
    let content: Content
    let gradient: Bool
    @Environment(\.colorScheme) 
    private var colorScheme
    
    init(gradient: Bool = false, @ViewBuilder content: () -> Content) {
        self.gradient = gradient
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: BrixieScaledMetrics.cornerRadius)
                    .fill(cardGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: BrixieScaledMetrics.cornerRadius)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .brixieCardShadow()
    }
    
    private var cardGradient: LinearGradient {
        if gradient {
            return LinearGradient.brixieCard
        } else {
            return LinearGradient(colors: [Color.brixieCard(for: colorScheme)], startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: Button Styles
struct BrixieButtonStyle: ButtonStyle {
    let variant: Variant
    @Environment(\.colorScheme) 
    private var colorScheme
    
    enum Variant: Sendable {
        case primary, secondary, ghost
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.brixieSubhead)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, BrixieScaledMetrics.buttonPadding)
            .padding(.vertical, BrixieScaledMetrics.buttonPadding / 2)
            .background(
                RoundedRectangle(cornerRadius: BrixieScaledMetrics.cornerRadius * 0.75)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: BrixieScaledMetrics.cornerRadius * 0.75)
                            .stroke(strokeColor, lineWidth: variant == .ghost ? 1 : 0)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .brixieGlow(color: variant == .primary ? Color.brixieAccent : .clear)
    }
    
    private var backgroundColor: LinearGradient {
        switch variant {
        case .primary:
            return .brixiePrimary
        case .secondary:
            return LinearGradient(colors: [Color.brixieCard(for: colorScheme)], startPoint: .top, endPoint: .bottom)
        case .ghost:
            return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary, .secondary:
            return Color.brixieText(for: colorScheme)
        case .ghost:
            return .brixieAccent
        }
    }
    
    private var strokeColor: Color {
        switch variant {
        case .ghost:
            return .brixieAccent.opacity(0.5)
        default:
            return .clear
        }
    }
}

// MARK: Loading Animation
struct BrixieLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.brixieAccent.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.brixieAccent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnimating)
            }
            .brixieAccessibility(
                label: NSLocalizedString("Loading", comment: "Loading indicator accessibility"),
                traits: .updatesFrequently
            )
            
            Text("Loading...")
                .font(.brixieBody)
                .foregroundStyle(Color.brixieTextSecondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: Hero Section
struct BrixieHeroSection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let content: Content
    
    init(title: String, subtitle: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(Color.brixieAccent)
                    .brixieGlow()
                    .brixieImageAccessibility(label: NSLocalizedString("Section icon", comment: "Hero section icon accessibility"), isDecorative: true)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.brixieTitle)
                        .foregroundStyle(Color.brixieText)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.brixieBody)
                        .foregroundStyle(Color.brixieTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            content
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: Animated Counter
struct AnimatedCounter: View {
    let value: Int
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Accessibility & Dynamic Type Support
extension View {
    /// Adds consistent accessibility support to interactive elements
    func brixieAccessibility(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }

    /// Adds image accessibility support
    func brixieImageAccessibility(label: String, isDecorative: Bool = false) -> some View {
        if isDecorative {
            return self.accessibilityHidden(true)
        } else {
            return self
                .accessibilityLabel(label)
                .accessibilityAddTraits(.isImage)
        }
    }
}

// MARK: - Scaled Metrics for Dynamic Type
struct BrixieScaledMetrics {
    @ScaledMetric static var cardPadding: CGFloat = 20
    @ScaledMetric static var buttonPadding: CGFloat = 24
    @ScaledMetric static var iconSize: CGFloat = 20
    @ScaledMetric static var cornerRadius: CGFloat = 16
    @ScaledMetric static var shadowRadius: CGFloat = 12
}
