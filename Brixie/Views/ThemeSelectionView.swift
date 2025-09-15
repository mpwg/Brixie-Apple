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
    private let previewMode: Bool

    init(previewThemes: [LegoTheme]? = nil, di: DIContainer? = nil) {
        let container: DIContainer? = di
        if let previewThemes = previewThemes {
            _viewModel = StateObject(
                wrappedValue: ThemeSelectionViewModel(
                    di: container ?? MainActor.assumeIsolated { DIContainer.shared }))
            _viewModel.wrappedValue.themes = previewThemes
            previewMode = true
        } else {
            _viewModel = StateObject(
                wrappedValue: ThemeSelectionViewModel(
                    di: container ?? MainActor.assumeIsolated { DIContainer.shared }))
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
                ForEach(viewModel.themes, id: \.id) { theme in
                    NavigationLink {
                        ThemeDetailView(theme: theme, di: di)
                    } label: {
                        Text(theme.name)
                    }
                }
            }
        }
        .navigationTitle("Themes")
        .task {
            if !previewMode {
                await viewModel.loadThemesIfNeeded()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let previewThemes: [LegoTheme] = [
        LegoTheme(id: 1, name: "Classic", parentId: nil, setCount: 120),
        LegoTheme(id: 2, name: "City", parentId: nil, setCount: 540),
        LegoTheme(id: 3, name: "Star Wars", parentId: nil, setCount: 320),
    ]

    NavigationStack {
        ThemeSelectionView(previewThemes: previewThemes)
    }
}
