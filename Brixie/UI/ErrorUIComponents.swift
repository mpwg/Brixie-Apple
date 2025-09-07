//
//  ErrorUIComponents.swift
//  Brixie
//
//  Reusable error banner and toast UI components for unified error handling
//

import SwiftUI

// MARK: - Error Banner

struct BrixieErrorBanner: View {
    let error: BrixieError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    init(error: BrixieError, onDismiss: @escaping () -> Void, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onDismiss = onDismiss
        self.onRetry = onRetry
    }
    
    var body: some View {
        BrixieCard {
            HStack(spacing: 12) {
                Image(systemName: errorIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(errorColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(errorTitle)
                        .font(.brixieSubhead)
                        .foregroundStyle(Color.brixieText)
                    
                    if let description = error.errorDescription {
                        Text(description)
                            .font(.brixieBody)
                            .foregroundStyle(Color.brixieTextSecondary)
                            .lineLimit(3)
                    }
                    
                    if let recovery = error.recoverySuggestion {
                        Text(recovery)
                            .font(.brixieCaption)
                            .foregroundStyle(Color.brixieTextSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    if let onRetry = onRetry, canRetry {
                        Button("Retry") {
                            onRetry()
                        }
                        .buttonStyle(BrixieButtonStyle(variant: .secondary))
                        .controlSize(.mini)
                    }
                    
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .buttonStyle(BrixieButtonStyle(variant: .ghost))
                    .controlSize(.mini)
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }
    
    private var errorIcon: String {
        switch error {
        case .networkError:
            return "wifi.exclamationmark"
        case .apiKeyMissing, .unauthorized:
            return "key.fill"
        case .rateLimitExceeded:
            return "clock.fill"
        case .cacheError:
            return "externaldrive.fill.trianglebadge.exclamationmark"
        case .dataNotFound:
            return "questionmark.circle.fill"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var errorColor: Color {
        switch error {
        case .networkError, .rateLimitExceeded:
            return Color.brixieWarning
        case .apiKeyMissing, .unauthorized:
            return Color.brixieAccent
        default:
            return Color.brixieWarning
        }
    }
    
    private var errorTitle: String {
        switch error {
        case .networkError:
            return "Connection Issue"
        case .apiKeyMissing:
            return "API Key Required"
        case .unauthorized:
            return "Authorization Failed"
        case .rateLimitExceeded:
            return "Rate Limit Reached"
        case .cacheError:
            return "Cache Error"
        case .dataNotFound:
            return "Data Not Found"
        case .parsingError:
            return "Data Processing Error"
        default:
            return "Error"
        }
    }
    
    private var canRetry: Bool {
        switch error {
        case .networkError, .rateLimitExceeded, .cacheError:
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Toast

struct BrixieErrorToast: View {
    let error: BrixieError
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.brixieWarning)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(errorTitle)
                    .font(.brixieSubhead)
                    .foregroundStyle(Color.white)
                
                if let description = error.errorDescription {
                    Text(description)
                        .font(.brixieCaption)
                        .foregroundStyle(Color.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(Color.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.brixieWarning.gradient)
        )
        .padding(.horizontal, 20)
    }
    
    private var errorTitle: String {
        switch error {
        case .networkError:
            return "Connection Error"
        case .apiKeyMissing:
            return "API Key Missing"
        case .unauthorized:
            return "Unauthorized"
        case .rateLimitExceeded:
            return "Too Many Requests"
        default:
            return "Error"
        }
    }
}

// MARK: - Error View Modifier

struct ErrorHandlingViewModifier: ViewModifier {
    let error: BrixieError?
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    let style: ErrorDisplayStyle
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let error = error {
                    switch style {
                    case .banner:
                        BrixieErrorBanner(error: error, onDismiss: onDismiss, onRetry: onRetry)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    case .toast:
                        BrixieErrorToast(error: error, onDismiss: onDismiss)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: error != nil)
    }
}

enum ErrorDisplayStyle {
    case banner
    case toast
}

// MARK: - View Extension

extension View {
    func errorHandling(
        error: BrixieError?,
        onDismiss: @escaping () -> Void,
        onRetry: (() -> Void)? = nil,
        style: ErrorDisplayStyle = .banner
    ) -> some View {
        modifier(ErrorHandlingViewModifier(
            error: error,
            onDismiss: onDismiss,
            onRetry: onRetry,
            style: style
        ))
    }
}
