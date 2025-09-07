//
//  BrixieTests.swift
//  BrixieTests
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Testing
import Foundation
@testable import Brixie

struct BrixieTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

// MARK: - Search Debounce Tests

struct SearchViewModelTests {
    
    @Test("Debounced search waits for delay before executing")
    func testDebouncedSearchDelay() async throws {
        let mockRepo = MockLegoSetRepository()
        let mockThemeRepo = MockLegoThemeRepository()
        let viewModel = SearchViewModel(
            legoSetRepository: mockRepo, 
            legoThemeRepository: mockThemeRepo,
            debounceDelay: 0.1 // Short delay for testing
        )
        
        viewModel.searchText = "test"
        viewModel.performDebouncedSearch()
        
        // Should not have searched immediately
        #expect(mockRepo.searchCallCount == 0)
        
        // Wait for debounce delay plus buffer
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        // Should have searched after delay
        #expect(mockRepo.searchCallCount == 1)
    }
    
    @Test("Debounced search cancels previous searches")
    func testDebouncedSearchCancellation() async throws {
        let mockRepo = MockLegoSetRepository()
        let mockThemeRepo = MockLegoThemeRepository()
        let viewModel = SearchViewModel(
            legoSetRepository: mockRepo,
            legoThemeRepository: mockThemeRepo,
            debounceDelay: 0.2 // Longer delay for cancellation testing
        )
        
        // Start first search
        viewModel.searchText = "first"
        viewModel.performDebouncedSearch()
        
        // Wait a bit but not enough for completion
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        
        // Start second search (should cancel first)
        viewModel.searchText = "second"
        viewModel.performDebouncedSearch()
        
        // Wait for second search to complete
        try await Task.sleep(nanoseconds: 250_000_000) // 250ms
        
        // Should only have called search once (for "second")
        #expect(mockRepo.searchCallCount == 1)
        #expect(mockRepo.lastSearchQuery == "second")
    }
    
    @Test("Immediate search bypasses debounce")
    func testImmediateSearchBypassesDebounce() async throws {
        let mockRepo = MockLegoSetRepository()
        let mockThemeRepo = MockLegoThemeRepository()
        let viewModel = SearchViewModel(
            legoSetRepository: mockRepo,
            legoThemeRepository: mockThemeRepo,
            debounceDelay: 1.0 // Long delay to ensure immediate bypass
        )
        
        viewModel.searchText = "immediate"
        await viewModel.performImmediateSearch()
        
        // Should have searched immediately
        #expect(mockRepo.searchCallCount == 1)
        #expect(mockRepo.lastSearchQuery == "immediate")
    }
    
    @Test("Immediate search cancels pending debounced search")
    func testImmediateSearchCancelsPendingDebounced() async throws {
        let mockRepo = MockLegoSetRepository()
        let mockThemeRepo = MockLegoThemeRepository()
        let viewModel = SearchViewModel(
            legoSetRepository: mockRepo,
            legoThemeRepository: mockThemeRepo,
            debounceDelay: 0.2
        )
        
        // Start debounced search
        viewModel.searchText = "debounced"
        viewModel.performDebouncedSearch()
        
        // Immediately perform immediate search
        viewModel.searchText = "immediate"
        await viewModel.performImmediateSearch()
        
        // Wait to ensure debounced search would have completed
        try await Task.sleep(nanoseconds: 250_000_000) // 250ms
        
        // Should only have called search once (immediate)
        #expect(mockRepo.searchCallCount == 1)
        #expect(mockRepo.lastSearchQuery == "immediate")
    }
    
    @Test("Empty search text clears results immediately")
    func testEmptySearchClearsResults() async throws {
        let mockRepo = MockLegoSetRepository()
        let mockThemeRepo = MockLegoThemeRepository()
        let viewModel = SearchViewModel(
            legoSetRepository: mockRepo,
            legoThemeRepository: mockThemeRepo
        )
        
        // Set some search results first
        viewModel.searchText = "test"
        await viewModel.performImmediateSearch()
        #expect(!viewModel.searchResults.isEmpty)
        
        // Clear search text and perform debounced search
        viewModel.searchText = ""
        viewModel.performDebouncedSearch()
        
        // Results should be cleared immediately
        #expect(viewModel.searchResults.isEmpty)
        #expect(!viewModel.showingNoResults)
    }
    
    @Test("Clear methods cancel pending searches")
    func testClearMethodsCancelPendingSearches() async throws {
        let mockRepo = MockLegoSetRepository()
        let mockThemeRepo = MockLegoThemeRepository()
        let viewModel = SearchViewModel(
            legoSetRepository: mockRepo,
            legoThemeRepository: mockThemeRepo,
            debounceDelay: 0.2
        )
        
        // Start debounced search
        viewModel.searchText = "test"
        viewModel.performDebouncedSearch()
        
        // Clear results (should cancel pending search)
        viewModel.clearResults()
        
        // Wait for original search delay
        try await Task.sleep(nanoseconds: 250_000_000) // 250ms
        
        // Should not have performed any search
        #expect(mockRepo.searchCallCount == 0)
    }
}

// MARK: - Mock Repositories

@MainActor
final class MockLegoSetRepository: LegoSetRepository {
    var searchCallCount = 0
    var lastSearchQuery: String?
    
    private let testSets = [
        LegoSet(setNum: "test-1", name: "Test Set 1", year: 2023, themeId: 1, numParts: 100),
        LegoSet(setNum: "test-2", name: "Test Set 2", year: 2023, themeId: 1, numParts: 200)
    ]
    
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        return testSets
    }
    
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
        searchCallCount += 1
        lastSearchQuery = query
        
        return testSets.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        return testSets.first { $0.setNum == setNum }
    }
    
    func getCachedSets() async -> [LegoSet] {
        return testSets
    }
    
    func markAsFavorite(_ set: LegoSet) async throws {
        // Mock implementation
    }
    
    func removeFromFavorites(_ set: LegoSet) async throws {
        // Mock implementation
    }
    
    func getFavoriteSets() async -> [LegoSet] {
        return []
    }
}

@MainActor
final class MockLegoThemeRepository: LegoThemeRepository {
    func fetchThemes(page: Int, pageSize: Int) async throws -> [LegoTheme] {
        return []
    }
    
    func searchThemes(query: String, page: Int, pageSize: Int) async throws -> [LegoTheme] {
        return []
    }
    
    func getThemeDetails(id: Int) async throws -> LegoTheme? {
        return nil
    }
    
    func getCachedThemes() async -> [LegoTheme] {
        return []
    }
}
