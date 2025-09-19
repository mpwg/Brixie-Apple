//
//  EmptyStateView.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import SwiftUI

/// Reusable empty state view component following design specifications
struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    
    /// Basic empty state with title, message and icon
    init(
        title: String,
        message: String,
        systemImage: String
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.buttonTitle = nil
        self.buttonAction = nil
    }
    
    /// Empty state with action button
    init(
        title: String,
        message: String,
        systemImage: String,
        buttonTitle: String,
        buttonAction: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }
    
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(buttonTitle) {
                    buttonAction()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Common Empty States

extension EmptyStateView {
    /// Empty collection state
    static func emptyCollection() -> EmptyStateView {
        EmptyStateView(
            title: NSLocalizedString("No sets in your collection", comment: "Empty collection title"),
            message: NSLocalizedString("Mark sets as owned to see them here.", comment: "Empty collection message"),
            systemImage: "heart"
        )
    }
    
    /// Empty wishlist state
    static func emptyWishlist() -> EmptyStateView {
        EmptyStateView(
            title: NSLocalizedString("Your wishlist is empty", comment: "Empty wishlist title"), 
            message: NSLocalizedString("Add sets to your wishlist to track them here.", comment: "Empty wishlist message"),
            systemImage: "star"
        )
    }
    
    /// Empty browse state
    static func emptyBrowse(retryAction: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            title: NSLocalizedString("No LEGO sets found", comment: "Empty browse title"),
            message: NSLocalizedString("Unable to load LEGO sets. Please check your internet connection and try again.", comment: "Empty browse message"),
            systemImage: "cube.box",
            buttonTitle: NSLocalizedString("Try Again", comment: "Retry button"),
            buttonAction: retryAction
        )
    }
    
    /// Search no results state  
    static func searchNoResults(query: String) -> EmptyStateView {
        EmptyStateView(
            title: NSLocalizedString("No results for '\(query)'", comment: "Search no results title"),
            message: NSLocalizedString("Try a different search term or browse by theme.", comment: "Search no results message"),
            systemImage: "magnifyingglass"
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Basic Empty State") {
    EmptyStateView(
        title: "No Items",
        message: "There are no items to display right now.",
        systemImage: "tray"
    )
}

#Preview("Empty State with Button") {
    EmptyStateView(
        title: "No Connection",
        message: "Unable to connect to the server.",
        systemImage: "wifi.slash",
        buttonTitle: "Retry"
    ) {
        // Action
    }
}

#Preview("Empty Collection") {
    EmptyStateView.emptyCollection()
}
#endif