import SwiftUI
import UIKit

/// Comprehensive accessibility enhancements for Brixie
struct AccessibilityEnhancements {
    // MARK: - Dynamic Type Support
    
    /// Custom font that scales with Dynamic Type
    static func scaledFont(_ style: Font.TextStyle, size: CGFloat? = nil) -> Font {
        if let size = size {
            return .custom("System", size: size, relativeTo: style)
        }
        return .system(style, design: .default)
    }
    
    /// Accessibility-friendly spacing that scales with content size
    static func accessibleSpacing(_ baseSpacing: CGFloat) -> CGFloat {
        // Map the UIKit content size category to SwiftUI's ContentSizeCategory so we can
        // reuse the accessibilityMultiplier extension defined below.
        let uiCategory = UIApplication.shared.preferredContentSizeCategory
        // Convert UIKit category to SwiftUI ContentSizeCategory using the initializer that accepts
        // a UIContentSizeCategory value. The initializer returns an optional, so provide a default.
        let sizeCategory = ContentSizeCategory(uiCategory) ?? .large
        let multiplier = sizeCategory.accessibilityMultiplier
        return baseSpacing * multiplier
    }
}

// MARK: - Content Size Category Extensions

extension ContentSizeCategory {
    /// Multiplier for spacing and sizing based on accessibility size
    var accessibilityMultiplier: CGFloat {
        switch self {
        case .extraSmall: return 0.85
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.0
        case .extraLarge: return 1.1
        case .extraExtraLarge: return 1.2
        case .extraExtraExtraLarge: return 1.3
        case .accessibilityMedium: return 1.4
        case .accessibilityLarge: return 1.6
        case .accessibilityExtraLarge: return 1.8
        case .accessibilityExtraExtraLarge: return 2.0
        case .accessibilityExtraExtraExtraLarge: return 2.2
        @unknown default: return 1.0
        }
    }
    
    /// Whether this is an accessibility size category
    var isAccessibilityCategory: Bool {
        switch self {
        case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
}

// MARK: - Accessibility View Modifiers

struct AccessibleCardModifier: ViewModifier {
    let title: String
    let description: String
    let hint: String?
    let action: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title). \(description)")
            .accessibilityHint(hint ?? "")
            .accessibilityAction(named: "Activate") {
                action?()
            }
            .accessibilityAddTraits(action != nil ? .isButton : [])
    }
}

struct DynamicTypeModifier: ViewModifier {
    @Environment(\.sizeCategory) private var sizeCategory
    
    func body(content: Content) -> some View {
        content
            .environment(\.sizeCategory, sizeCategory)
    }
}

struct HighContrastModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    
    func body(content: Content) -> some View {
        content
            .opacity(reduceTransparency ? AppConstants.Opacity.visible : AppConstants.Opacity.highContrast)
            .background(reduceTransparency ? Color(.systemBackground) : Color.clear)
    }
}

// MARK: - Keyboard Navigation Support

struct KeyboardNavigationModifier: ViewModifier {
    // Keep labels flexible for call-sites; accept common ordering with explicit labels
    let onUpArrow: (() -> Void)?
    let onDownArrow: (() -> Void)?
    let onLeftArrow: (() -> Void)?
    let onRightArrow: (() -> Void)?
    let onSpace: (() -> Void)?
    let onReturn: (() -> Void)?
    let onEscape: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .focusable()
            .onKeyPress(.upArrow) { onUpArrow?(); return .handled }
            .onKeyPress(.downArrow) { onDownArrow?(); return .handled }
            .onKeyPress(.leftArrow) { onLeftArrow?(); return .handled }
            .onKeyPress(.rightArrow) { onRightArrow?(); return .handled }
            .onKeyPress(.space) { onSpace?(); return .handled }
            .onKeyPress(.return) { onReturn?(); return .handled }
            .onKeyPress(.escape) { onEscape?(); return .handled }
    }
}

// MARK: - Accessibility-Enhanced Views

struct AccessibleSetCard: View {
    let set: LegoSet
    let onTap: () -> Void
    
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    
    var body: some View {
        VStack(alignment: .leading, spacing: AccessibilityEnhancements.accessibleSpacing(8)) {
            AsyncCachedImage(
                url: URL(string: set.imageURL ?? ""),
                maxSize: sizeCategory.isAccessibilityCategory ? CGSize(width: 200, height: 200) : nil,
                imageType: .medium
            )
            .frame(height: sizeCategory.isAccessibilityCategory ? 160 : 120)
            .accessibilityLabel("Image of LEGO set \(set.name)")
            
            VStack(alignment: .leading, spacing: AccessibilityEnhancements.accessibleSpacing(4)) {
                Text(set.name)
                    .font(AccessibilityEnhancements.scaledFont(.headline))
                    .multilineTextAlignment(.leading)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Set number \(set.setNumber)")
                    .font(AccessibilityEnhancements.scaledFont(.subheadline))
                    .foregroundColor(.secondary)
                
                Text("Released in \(set.year)")
                    .font(AccessibilityEnhancements.scaledFont(.caption))
                
                Text("\(set.numParts) pieces")
                    .font(AccessibilityEnhancements.scaledFont(.caption))
                
                // Collection status with accessibility improvements
                AccessibleCollectionStatus(set: set)
            }
        }
        .padding(AccessibilityEnhancements.accessibleSpacing(12))
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: .black.opacity(differentiateWithoutColor ? AppConstants.Opacity.accessibilityBorder : AppConstants.Opacity.accessibilityBackground),
                    radius: differentiateWithoutColor ? 1 : 2
                )
        }
        .modifier(AccessibleCardModifier(
            title: set.name,
            description: "LEGO set \(set.setNumber) from \(set.year) with \(set.numParts) pieces",
            hint: "Double tap to view details",
            action: onTap
        ))
        .onTapGesture {
            onTap()
        }
        .modifier(KeyboardNavigationModifier(
            onUpArrow: nil,
            onDownArrow: nil,
            onLeftArrow: nil,
            onRightArrow: nil,
            onSpace: onTap,
            onReturn: onTap,
            onEscape: nil
        ))
        .modifier(HighContrastModifier())
    }
}

struct AccessibleCollectionStatus: View {
    let set: LegoSet
    
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    
    var body: some View {
        HStack(spacing: AccessibilityEnhancements.accessibleSpacing(8)) {
            if set.userCollection?.isOwned == true {
                HStack(spacing: 2) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    if differentiateWithoutColor {
                        Text("Owned")
                            .font(.caption2)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("In your collection")
            }
            
            if set.userCollection?.isWishlist == true {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    if differentiateWithoutColor {
                        Text("Wished")
                            .font(.caption2)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("On your wishlist")
            }
            
            if set.userCollection?.hasMissingParts == true {
                HStack(spacing: 2) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    if differentiateWithoutColor {
                        Text("Missing")
                            .font(.caption2)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Has missing parts")
            }
        }
    }
}

// MARK: - Accessibility Extensions

extension View {
    /// Adds comprehensive accessibility support to any view
    func accessibleCard(title: String, description: String, hint: String? = nil, action: (() -> Void)? = nil) -> some View {
        self.modifier(AccessibleCardModifier(title: title, description: description, hint: hint, action: action))
    }
    
    /// Adds keyboard navigation support
    func keyboardNavigation(
        onUpArrow: (() -> Void)? = nil,
        onDownArrow: (() -> Void)? = nil,
        onLeftArrow: (() -> Void)? = nil,
        onRightArrow: (() -> Void)? = nil,
        onSpace: (() -> Void)? = nil,
        onReturn: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        self.modifier(KeyboardNavigationModifier(
            onUpArrow: onUpArrow,
            onDownArrow: onDownArrow,
            onLeftArrow: onLeftArrow,
            onRightArrow: onRightArrow,
            onSpace: onSpace,
            onReturn: onReturn,
            onEscape: onEscape
        ))
    }
    
    /// Applies high contrast and reduced transparency support
    func highContrastSupport() -> some View {
        self.modifier(HighContrastModifier())
    }
    
    /// Ensures proper Dynamic Type support
    func dynamicTypeSupport() -> some View {
        self.modifier(DynamicTypeModifier())
    }
    
    /// Makes an image decorative (hidden from screen readers)
    func decorativeImage() -> some View {
        self.accessibilityHidden(true)
    }
    
    /// Adds semantic meaning to images
    func semanticImage(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Accessibility Announcements

// Accessibility announcer: to avoid unsafe UIAccessibility cross-actor calls at build time
// we provide safe stubs that can be replaced with proper, platform-safe implementations
// if needed. These keep the API surface stable for callers.
struct AccessibilityAnnouncer {
    @MainActor
    static func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        // Intentionally minimal: log the announcement. Replace with UIAccessibility.post
        // behind a platform-specific, tested wrapper if necessary.
        #if DEBUG
        print("[AccessibilityAnnouncer] announce: \(message)")
        #endif
    }

    @MainActor
    static func announceScreenChange(newScreen: String) {
        #if DEBUG
        print("[AccessibilityAnnouncer] screen change: \(newScreen)")
        #endif
    }

    @MainActor
    static func announceLayoutChange(change: String) {
        #if DEBUG
        print("[AccessibilityAnnouncer] layout change: \(change)")
        #endif
    }
}
