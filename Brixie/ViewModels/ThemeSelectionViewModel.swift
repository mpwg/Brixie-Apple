import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ThemeSelectionViewModel: ObservableObject {
    @Published var themes: [LegoTheme] = []
    @Published var isLoading: Bool = false
    @Published var lastError: BrixieError?
    @Published var expanded: Set<Int> = []

    private let di: DIContainer
    private let pageSize: Int
    private let parentId: Int?
    // Keep a copy of all fetched themes so callers can determine child existence
    private var allFetchedThemes: [LegoTheme] = []

    init(di: DIContainer, parentId: Int? = nil, pageSize: Int = 1000) {
        self.di = di
        self.parentId = parentId
        self.pageSize = pageSize
    }

    /// Populate the view model with preview themes (used by SwiftUI previews)
    func setPreviewThemes(_ themes: [LegoTheme]) {
        allFetchedThemes = themes
        self.themes = allFetchedThemes.filter { $0.parentid == parentId }
    }

    func loadThemesIfNeeded() async {
        guard themes.isEmpty else { return }
        await loadThemes()
    }

    func reloadThemes() async {
        await loadThemes()
    }

    private func loadThemes() async {
        isLoading = true
        lastError = nil
        do {
            let repo = di.makeLegoThemeRepository()
            let fetched = try await repo.fetchThemes(page: 1, pageSize: pageSize)
            // Preserve the full list so we can determine child relationships
            allFetchedThemes = fetched
            // Show only themes matching this view model's parentId
            themes = allFetchedThemes.filter { $0.parentid == parentId }
        } catch {
            if let b = error as? BrixieError {
                lastError = b
            } else {
                lastError = .networkError(underlying: error)
            }
        }
        isLoading = false
    }

    func hasChildren(themeId: Int) -> Bool {
        return allFetchedThemes.contains { $0.parentid == themeId }
    }

    /// Toggle the expansion state for a theme
    func toggleExpanded(_ themeId: Int) {
        if expanded.contains(themeId) {
            expanded.remove(themeId)
        } else {
            expanded.insert(themeId)
        }
    }

    /// Return child themes for a given parent id.
    func children(of parentId: Int) -> [LegoTheme] {
        return allFetchedThemes.filter { $0.parentid == parentId }
    }
}
