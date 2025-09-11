//
//  RetryFunctionalityTests.swift
//  BrixieTests
//
//  Created by Claude on 06.09.25.
//

import Testing
@testable import Brixie

@MainActor
struct RetryFunctionalityTests {
    @Test("SetsListViewModel retry should call loadSets")
    func setsListViewModelRetryCallsLoadSets() async throws {
        // Mock repository for testing
        let mockRepository = MockLegoSetRepository()
        let viewModel = SetsListViewModel(legoSetRepository: mockRepository)
        
        // Perform initial load that fails
        await viewModel.loadSets()
        #expect(mockRepository.fetchSetsCallCount == 1)
        
        // Clear call count and retry
        mockRepository.fetchSetsCallCount = 0
        await viewModel.retryLoad()
        
        // Verify retry calls loadSets
        #expect(mockRepository.fetchSetsCallCount == 1)
    }
    
    @Test("SearchViewModel retry should call performSearch")
    func searchViewModelRetryCallsPerformSearch() async throws {
        // Mock repositories for testing
        let mockSetRepository = MockLegoSetRepository()
        let mockThemeRepository = MockLegoThemeRepository()
        let viewModel = SearchViewModel(
            legoSetRepository: mockSetRepository,
            legoThemeRepository: mockThemeRepository
        )
        
        // Set search text and perform search that fails
        viewModel.searchText = "test query"
        await viewModel.performSearch()
        #expect(mockSetRepository.searchSetsCallCount == 1)
        
        // Clear call count and retry
        mockSetRepository.searchSetsCallCount = 0
        await viewModel.retrySearch()
        
        // Verify retry calls performSearch
        #expect(mockSetRepository.searchSetsCallCount == 1)
    }
}

// MARK: - Mock Repositories

class MockLegoSetRepository: LegoSetRepository {
    var fetchSetsCallCount = 0
    var searchSetsCallCount = 0
    var shouldThrowError = false
    
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        fetchSetsCallCount += 1
        if shouldThrowError {
            throw BrixieError.networkError(underlying: NSError(domain: "test", code: 1))
        }
        return []
    }
    
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
        searchSetsCallCount += 1
        if shouldThrowError {
            throw BrixieError.networkError(underlying: NSError(domain: "test", code: 1))
        }
        return []
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? { nil }
    func getCachedSets() async -> [LegoSet] { [] }
    func markAsFavorite(_ set: LegoSet) async throws {}
    func removeFromFavorites(_ set: LegoSet) async throws {}
    func getFavoriteSets() async -> [LegoSet] { [] }
}

class MockLegoThemeRepository: LegoThemeRepository {
    func fetchThemes(page: Int, pageSize: Int) async throws -> [LegoTheme] { [] }
    func searchThemes(query: String, page: Int, pageSize: Int) async throws -> [LegoTheme] { [] }
    func getThemeDetails(id: Int) async throws -> LegoTheme? { nil }
    func getCachedThemes() async -> [LegoTheme] { [] }
}
