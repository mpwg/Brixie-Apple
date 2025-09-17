//
//  ThemeSelectionView.swift
//  Brixie
//
//  Created by automated refactor on 15.09.25.
//

import Foundation
import SwiftData
import SwiftUI

struct ThemeSelectionView: View {
    @Environment(\.diContainer) private var di: DIContainer
    /// NOTE: In iOS 17+, using @State for Observable view models is correct and replaces @StateObject.
    /// This pattern change allows SwiftUI to manage the observable's lifecycle automatically.
    /// See: https://developer.apple.com/documentation/swiftui/state for details.
    @State private var viewModel: ThemeSelectionViewModel

    /// - Parameters:
    ///   - previewThemes: supply for SwiftUI previews
    ///   - parentid: optional parent id to show child themes
    ///   - di: optional DI container (injected via environment by callers)
    init(previewThemes: [LegoTheme]? = nil, parentid: Int? = nil, di: DIContainer? = nil) {
        let container = di ?? MainActor.assumeIsolated { DIContainer.shared }
        let repository = container.makeLegoThemeRepository()
        _viewModel = State(
            initialValue: ThemeSelectionViewModel(repository: repository, parentid: parentid))

        // Set preview themes if provided
        if let previewThemes = previewThemes {
            _viewModel.wrappedValue.setPreviewThemes(previewThemes)
        }
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading themes…")
                }
            } else if viewModel.isEmpty {
                EmptyStateView(message: "No themes available")
            } else if viewModel.shouldShowContent {
                ForEach(viewModel.flattenedThemes()) { displayItem in
                    ThemeRowView(
                        displayItem: displayItem,
                        onToggleExpanded: { themeId in
                            viewModel.toggleExpanded(themeId)
                        },
                        di: di
                    )
                }
            }
        }
        .navigationTitle("Themes")
        .task {
            await viewModel.loadThemesIfNeeded()
        }
        // Unified error handling overlay
        .errorHandling(
            error: viewModel.lastError,
            onDismiss: { viewModel.lastError = nil },
            onRetry: { Task { await viewModel.reloadThemes() } },
            style: .banner
        )
    }
}

private struct EmptyStateView: View {
    let message: String

    var body: some View {
        Text(message)
            .foregroundStyle(.secondary)
    }
}
