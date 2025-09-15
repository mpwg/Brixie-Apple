//
//  ThemeSelectionView.swift
//  Brixie
//
//  Created by automated refactor on 15.09.25.
//

import Foundation
import SwiftData
import SwiftUI

// Types from local project files

struct ThemeSelectionView: View {
    @Environment(\.diContainer) private var di: DIContainer
    @StateObject private var viewModel: ThemeSelectionViewModel
    private let previewMode: Bool
    // Expansion state is now managed by the view model

    /// - Parameters:
    ///   - previewThemes: supply for SwiftUI previews
    ///   - parentId: optional parent id to show child themes
    ///   - di: optional DI container (injected via environment by callers)
    init(previewThemes: [LegoTheme]? = nil, parentId: Int? = nil, di: DIContainer? = nil) {
        let container: DIContainer? = di
        if let previewThemes = previewThemes {
            _viewModel = StateObject(
                wrappedValue: ThemeSelectionViewModel(
                    di: container ?? MainActor.assumeIsolated { DIContainer.shared },
                    parentId: parentId))
            _viewModel.wrappedValue.setPreviewThemes(previewThemes)
            previewMode = true
        } else {
            _viewModel = StateObject(
                wrappedValue: ThemeSelectionViewModel(
                    di: container ?? MainActor.assumeIsolated { DIContainer.shared },
                    parentId: parentId))
            previewMode = false
        }
    }

    var body: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    ProgressView()
                    Text("Loading themes…")
                }
            } else if let error = viewModel.lastError {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Failed to load themes")
                        .font(.headline)
                    Text(error.errorDescription ?? "Unknown error")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Retry") {
                        Task { await viewModel.reloadThemes() }
                    }
                }
                .padding(.vertical, 8)
            } else if viewModel.themes.isEmpty {
                Text("No themes available")
                    .foregroundStyle(.secondary)
            } else {
                // Render a hierarchical list inline. Top-level themes are
                // those the view model populated for this parentId.
                ForEach(viewModel.themes, id: \.id) { theme in
                    themeRow(theme, level: 0)
                }
            }
        }
        .navigationTitle("Themes")
        .task {
            if !previewMode {
                await viewModel.loadThemesIfNeeded()
            }
            // For preview mode, ensure preview themes are applied to the VM
            if previewMode {
                // viewModel already created with parentId, but wire preview data
                // if the initializer supplied them.
                // (The preview code below calls ThemeSelectionView(previewThemes:))
            }
        }
    }

    private func themeRow(_ theme: LegoTheme, level: Int) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Indentation
                    Spacer().frame(width: CGFloat(level) * 14)

                    if viewModel.hasChildren(themeId: theme.id) {
                        Button(action: {
                            viewModel.toggleExpanded(theme.id)
                        }) {
                            Image(
                                systemName: viewModel.expanded.contains(theme.id)
                                    ? "chevron.down" : "chevron.right"
                            )
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    } else {
                        // to align with rows that have a chevron
                        Spacer().frame(width: 20)
                    }

                    if viewModel.hasChildren(themeId: theme.id) {
                        // non-leaf; show label that just expands/collapses
                        HStack {
                            Text(theme.name)
                            Text("ID: \(theme.id)")
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    } else {
                        // leaf: navigate to SetListView
                        NavigationLink {
                            SetListView(theme: theme, di: di)
                        } label: {
                            HStack {
                                Text(theme.name)
                                Text("ID: \(theme.id)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Children
                if viewModel.expanded.contains(theme.id) {
                    ForEach(viewModel.children(of: theme.id), id: \.id) { child in
                        themeRow(child, level: level + 1)
                    }
                }
            }
        )
    }
}
