//
//  BrixieDesignSystem.swift
//  Brixie
//
//  Created by Claude on 05.09.25.
//

import SwiftUI

// MARK: - Colors
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
    
    // Adaptive Colors
    static let brixieBackground = Color(light: .brixieBackgroundLight, dark: .brixieBackgroundDark)
    static let brixieCard = Color(light: .brixieCardLight, dark: .brixieCardDark)
    static let brixieText = Color(light: .brixieTextLight, dark: .brixieTextDark)
    static let brixieTextSecondary = Color(light: .brixieTextSecondaryLight, dark: .brixieTextSecondaryDark)
    static let brixieSecondary = Color(light: .brixieSecondaryLight, dark: .brixieSecondaryDark)
}

// Helper extension for adaptive colors
extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let brixiePrimary = LinearGradient(
        colors: [.brixieGradientStart, .brixieGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let brixieCard = LinearGradient(
        colors: [.brixieCard, Color.brixieCard.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
extension Font {
    static let brixieTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let brixieHeadline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let brixieSubhead = Font.system(size: 16, weight: .medium, design: .rounded)
    static let brixieBody = Font.system(size: 14, weight: .regular, design: .default)
    static let brixieCaption = Font.system(size: 12, weight: .medium, design: .default)
}

// MARK: - Shadows
extension View {
    func brixieCardShadow() -> some View {
        self.shadow(color: Color(light: .black.opacity(0.1), dark: .black.opacity(0.3)), radius: 12, x: 0, y: 6)
    }
    
    func brixieGlow(color: Color = .brixieAccent) -> some View {
        self.shadow(color: color.opacity(0.6), radius: 8, x: 0, y: 0)
    }
}

// MARK: - Card Styles
struct BrixieCard<Content: View>: View {
    let content: Content
    let gradient: Bool
    
    init(gradient: Bool = false, @ViewBuilder content: () -> Content) {
        self.gradient = gradient
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(gradient ? LinearGradient.brixieCard : LinearGradient(colors: [.brixieCard], startPoint: .top, endPoint: .bottom))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .brixieCardShadow()
    }
}

// MARK: - Button Styles
struct BrixieButtonStyle: ButtonStyle {
    let variant: Variant
    
    enum Variant {
        case primary, secondary, ghost
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.brixieSubhead)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(strokeColor, lineWidth: variant == .ghost ? 1 : 0)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .brixieGlow(color: variant == .primary ? .brixieAccent : .clear)
    }
    
    private var backgroundColor: LinearGradient {
        switch variant {
        case .primary:
            return .brixiePrimary
        case .secondary:
            return LinearGradient(colors: [.brixieCard], startPoint: .top, endPoint: .bottom)
        case .ghost:
            return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary, .secondary:
            return .brixieText
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

// MARK: - Loading Animation
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
            
            Text("Loading...")
                .font(.brixieBody)
                .foregroundStyle(Color.brixieTextSecondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Hero Section
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

// MARK: - Animated Counter
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