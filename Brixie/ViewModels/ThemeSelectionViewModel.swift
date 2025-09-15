import Foundation
import SwiftData
import SwiftUI

// MARK: - Supporting Types

/// Represents a theme in the display hierarchy with presentation metadata
struct ThemeDisplayItem: Identifiable {
    let theme: LegoTheme
    let level: Int
    let isExpanded: Bool
    let hasChildren: Bool

    var id: Int { theme.id }
    var indentationWidth: CGFloat { CGFloat(level) * 20 }
}

// MARK: - View Model

@Observable
@MainActor
final class ThemeSelectionViewModel {
    var themes: [LegoTheme] = []
    var isLoading: Bool = false
    var lastError: BrixieError?
    var expanded: Set<Int> = []

    private let di: DIContainer
    private let pageSize: Int
    private let parentId: Int?
    private var isPreviewMode: Bool = false
    // Keep a copy of all fetched themes so callers can determine child relationships
    private var allFetchedThemes: [LegoTheme] = []

    // MARK: - Computed Properties for View State

    var hasError: Bool {
        lastError != nil
    }

    var isEmpty: Bool {
        !isLoading && themes.isEmpty && !hasError
    }

    var shouldShowContent: Bool {
        !isLoading && !hasError && !themes.isEmpty
    }

    init(di: DIContainer, parentId: Int? = nil, pageSize: Int = 1000) {
        self.di = di
        self.parentId = parentId
        self.pageSize = pageSize
    }

    // MARK: - Preview Mode Support

    /// Populate the view model with preview themes (used by SwiftUI previews)
    func setPreviewThemes(_ themes: [LegoTheme]) {
        isPreviewMode = true
        allFetchedThemes = themes
        self.themes = allFetchedThemes.filter { $0.parentId == parentId }
    }

    // MARK: - Theme Hierarchy Management

    /// Returns all themes that should be displayed as a flattened list
    /// This includes expanded children recursively
    func flattenedThemes() -> [ThemeDisplayItem] {
        return buildFlattenedList(from: themes, level: 0)
    }

    private func buildFlattenedList(from themes: [LegoTheme], level: Int) -> [ThemeDisplayItem] {
        var result: [ThemeDisplayItem] = []

        for theme in themes {
            let displayItem = ThemeDisplayItem(
                theme: theme,
                level: level,
                isExpanded: expanded.contains(theme.id),
                hasChildren: hasChildren(themeId: theme.id)
            )
            result.append(displayItem)

            // Add children if expanded
            if expanded.contains(theme.id) {
                let childThemes = children(of: theme.id)
                let childItems = buildFlattenedList(from: childThemes, level: level + 1)
                result.append(contentsOf: childItems)
            }
        }

        return result
    }

    // MARK: - Theme Actions

    /// Toggle the expansion state for a theme
    func toggleExpanded(_ themeId: Int) {
        if expanded.contains(themeId) {
            expanded.remove(themeId)
        } else {
            expanded.insert(themeId)
        }
    }

    // MARK: - Data Loading

    func loadThemesIfNeeded() async {
        guard themes.isEmpty && !isPreviewMode else { return }
        await loadThemes()
    }

    func reloadThemes() async {
        guard !isPreviewMode else { return }
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
            themes = allFetchedThemes.filter { $0.parentId == parentId }
        } catch {
            if let b = error as? BrixieError {
                lastError = b
            } else {
                lastError = .networkError(underlying: error)
            }
        }
        isLoading = false
    }

    // MARK: - Theme Queries

    func hasChildren(themeId: Int) -> Bool {
        return allFetchedThemes.contains { $0.parentId == themeId }
    }

    /// Return child themes for a given parent id.
    func children(of parentId: Int) -> [LegoTheme] {
        return allFetchedThemes.filter { $0.parentId == parentId }
    }
}
