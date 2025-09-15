import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ThemeSelectionViewModel: ObservableObject {
    @Published var themes: [LegoTheme] = []
    @Published var isLoading: Bool = false
    @Published var lastError: BrixieError?

    private let di: DIContainer
    private let pageSize: Int

    init(di: DIContainer, pageSize: Int = 200) {
        self.di = di
        self.pageSize = pageSize
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
