//
//  BrixieBannerView.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import SwiftUI

/// A reusable banner view for displaying error messages with retry functionality
struct BrixieBannerView: View {
    let title: String
    let message: String
    let actionTitle: String
    let onAction: () -> Void
    let onDismiss: (() -> Void)?
    
    init(
        title: String,
        message: String,
        actionTitle: String = NSLocalizedString("Retry", comment: "Retry button title"),
        onAction: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.onAction = onAction
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        BrixieCard {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.brixieWarning)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.brixieSubhead)
                        .foregroundStyle(Color.brixieText)
                    
                    Text(message)
                        .font(.brixieBody)
                        .foregroundStyle(Color.brixieTextSecondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button(actionTitle) {
                        onAction()
                    }
                    .buttonStyle(BrixieButtonStyle(variant: .ghost))
                    
                    if let onDismiss = onDismiss {
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.brixieTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Convenience Initializers

extension BrixieBannerView {
    /// Creates a banner for network errors with default retry messaging
    static func networkError(onRetry: @escaping () -> Void, onDismiss: (() -> Void)? = nil) -> BrixieBannerView {
        BrixieBannerView(
            title: NSLocalizedString("Connection Issue", comment: "Network error banner title"),
            message: NSLocalizedString("Check your internet connection and try again", comment: "Network error banner message"),
            onAction: onRetry,
            onDismiss: onDismiss
        )
    }
    
    /// Creates a banner for API key errors with default messaging
    static func apiKeyError(onRetry: @escaping () -> Void, onDismiss: (() -> Void)? = nil) -> BrixieBannerView {
        BrixieBannerView(
            title: NSLocalizedString("API Key Required", comment: "API key error banner title"),
            message: NSLocalizedString("Please enter a valid API key in settings", comment: "API key error banner message"),
            actionTitle: NSLocalizedString("Settings", comment: "Settings button title"),
            onAction: onRetry,
            onDismiss: onDismiss
        )
    }
    
    /// Creates a banner for general errors with default messaging
    static func generalError(_ error: BrixieError, onRetry: @escaping () -> Void, onDismiss: (() -> Void)? = nil) -> BrixieBannerView {
        BrixieBannerView(
            title: NSLocalizedString("Something Went Wrong", comment: "General error banner title"),
            message: error.recoverySuggestion ?? error.errorDescription ?? NSLocalizedString("Please try again", comment: "Default error message"),
            onAction: onRetry,
            onDismiss: onDismiss
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        BrixieBannerView.networkError {}
        
        BrixieBannerView.apiKeyError {}
        
        BrixieBannerView(
            title: "Custom Error",
            message: "This is a custom error message that might be longer and span multiple lines."
        )            {}
    }
    .padding()
}
