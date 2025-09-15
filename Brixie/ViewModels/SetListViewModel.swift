import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class SetListViewModel: ObservableObject {
    @Published var sets: [LegoSet] = []
    @Published var isLoading: Bool = false
    @Published var error: BrixieError?

    private let repository: LegoSetRepository
    static let pageSizeDefault: Int = 100
    private var themeId: Int
    private var currentPage: Int = 1
    private let pageSize: Int
    private var isLastPage: Bool = false

    init(repository: LegoSetRepository, themeId: Int, pageSize: Int = pageSizeDefault) {
        self.repository = repository
        self.themeId = themeId
        self.pageSize = pageSize
    }

    // Update the view model to show sets for a new theme id. This resets
    // pagination and reloads the first page of sets for the new theme.
    func updateForTheme(_ newThemeId: Int) async {
        guard newThemeId != themeId else { return }
        themeId = newThemeId
        currentPage = 1
        isLastPage = false
        sets = []
        await loadPage()
    }

    func loadInitial() async {
        guard sets.isEmpty else { return }
        currentPage = 1
        isLastPage = false
        await loadPage()
    }

    func loadMoreIfNeeded(currentItem: LegoSet?) async {
        guard !isLoading, !isLastPage else { return }
        guard let currentItem = currentItem else {
            await loadPage()
            return
        }

        // Trigger load when the current item is among the last 5
        if let index = sets.firstIndex(where: { $0.setNum == currentItem.setNum }),
            index >= sets.count - 5
        {
            await loadPage()
        }
    }

    private func loadPage() async {
        isLoading = true
        error = nil
        do {
            let fetched = try await repository.getSetsForTheme(
                themeId: themeId, page: currentPage, pageSize: pageSize)

            if currentPage == 1 {
                sets = fetched
            } else {
                sets.append(contentsOf: fetched)
            }

            if fetched.count < pageSize {
                isLastPage = true
            } else {
                currentPage += 1
            }
        } catch {
            if let b = error as? BrixieError {
                self.error = b
            } else {
                self.error = .networkError(underlying: error)
            }
        }
        isLoading = false
    }
}
