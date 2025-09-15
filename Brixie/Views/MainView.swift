//
//  MainView.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 15.09.25.
//

import Foundation
import SwiftData
import SwiftUI

struct MainView: View {
    @Environment(\.diContainer) private var di: DIContainer

    @State private var themes: [LegoTheme]
    @State private var isLoading: Bool = false
    @State private var lastError: BrixieError?

    private let previewMode: Bool

    init(previewThemes: [LegoTheme]? = nil) {
        if let previewThemes = previewThemes {
            _themes = State(initialValue: previewThemes)
            previewMode = true
        } else {
            _themes = State(initialValue: [])
            previewMode = false
        }
    }

    var body: some View {
        NavigationSplitView {
            List {
                if isLoading {
                    HStack {
                        ProgressView()
                        Text("Loading themes…")
                    }
                } else if let error = lastError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Failed to load themes")
                            .font(.headline)
                        Text(error.errorDescription ?? "Unknown error")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            Task { await loadThemes() }
                        }
                    }
                    .padding(.vertical, 8)
                } else if themes.isEmpty {
                    Text("No themes available")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(themes, id: \.id) { theme in
                        NavigationLink {
                            // Simple destination for now: show theme name and id
                            VStack(alignment: .leading) {
                                Text(theme.name)
                                    .font(.title)
                                Text("ID: \(theme.id)")
                                    .foregroundStyle(.secondary)

                            }
                            .padding()
                        } label: {
                            Text(theme.name)
                        }
                    }
                }
            }
            .navigationTitle("Themes")
            .task {
                if !previewMode && themes.isEmpty {
                    await loadThemes()
                }
            }
        } content: {
            VStack(alignment: .leading) {
                Text("Select a theme from the sidebar to view its sets")
                    .padding()
            }
        } detail: {
            VStack(alignment: .leading) {
                Text("Select a theme to see details")
            }
            .padding()
        }
    }

    @MainActor
    private func loadThemes() async {
        isLoading = true
        lastError = nil
        do {
            let repo = di.makeLegoThemeRepository()
            let fetched = try await repo.fetchThemes(page: 1, pageSize: 200)
            themes = fetched
        } catch {
            if let b = error as? BrixieError {
                lastError = b
            } else {
                lastError = .networkError(underlying: error)
            }
        }
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    let previewThemes: [LegoTheme] = [
        LegoTheme(id: 1, name: "Classic", parentId: nil, setCount: 120),
        LegoTheme(id: 2, name: "City", parentId: nil, setCount: 540),
        LegoTheme(id: 3, name: "Star Wars", parentId: nil, setCount: 320),
    ]

    MainView(previewThemes: previewThemes)
}
