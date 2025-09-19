import SwiftUI

/// Provides haptic feedback for user interactions
struct HapticFeedback {
    private init() {}
    
    /// Provides light impact feedback for subtle interactions
    static func light() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Provides medium impact feedback for moderate interactions  
    static func medium() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Provides heavy impact feedback for significant interactions
    static func heavy() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    /// Provides success feedback
    static func success() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Provides warning feedback
    static func warning() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// Provides error feedback
    static func error() {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    /// Provides selection feedback
    static func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}

/// View modifier that adds haptic feedback to interactions
struct HapticFeedbackModifier: ViewModifier {
    let type: HapticType
    
    enum HapticType {
        case light, medium, heavy, success, warning, error, selection
        
        func trigger() {
            switch self {
            case .light: HapticFeedback.light()
            case .medium: HapticFeedback.medium()
            case .heavy: HapticFeedback.heavy()
            case .success: HapticFeedback.success()
            case .warning: HapticFeedback.warning()
            case .error: HapticFeedback.error()
            case .selection: HapticFeedback.selection()
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                type.trigger()
            }
    }
}

extension View {
    /// Adds haptic feedback to tap gestures
    func hapticFeedback(_ type: HapticFeedbackModifier.HapticType) -> some View {
        self.modifier(HapticFeedbackModifier(type: type))
    }
}