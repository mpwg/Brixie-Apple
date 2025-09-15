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
    @StateObject private var viewModel: ThemeSelectionViewModel

    /// - Parameters:
    ///   - previewThemes: supply for SwiftUI previews
    ///   - parentId: optional parent id to show child themes
    ///   - di: optional DI container (injected via environment by callers)
    init(previewThemes: [LegoTheme]? = nil, parentId: Int? = nil, di: DIContainer? = nil) {
        let container = di ?? MainActor.assumeIsolated { DIContainer.shared }
        _viewModel = StateObject(
            wrappedValue: ThemeSelectionViewModel(
                di: container,
                parentId: parentId
            )
        )

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
            } else if viewModel.hasError {
                ErrorView(
                    title: "Failed to load themes",
                    error: viewModel.lastError,
                    retryAction: {
                        Task { await viewModel.reloadThemes() }
                    }
                )
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
    }
}

// MARK: - Supporting Views

private struct ErrorView: View {
    let title: String
    let error: BrixieError?
    let retryAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            if let error = error {
                Text(error.errorDescription ?? "Unknown error")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button("Retry", action: retryAction)
        }
        .padding(.vertical, 8)
    }
}

private struct EmptyStateView: View {
    let message: String

    var body: some View {
        Text(message)
            .foregroundStyle(.secondary)
    }
}
