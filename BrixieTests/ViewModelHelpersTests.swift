//
//  ViewModelHelpersTests.swift
//  BrixieTests
//
//  Created by Claude on 07.09.25.
//

import Testing
@testable import Brixie

struct ViewModelHelpersTests {
    
    // Mock repository for testing
    @MainActor
    final class MockLegoSetRepository: LegoSetRepository {
        var markAsFavoriteCallCount = 0
        var removeFromFavoritesCallCount = 0
        var lastSetMarkedAsFavorite: LegoSet?
        var lastSetRemovedFromFavorites: LegoSet?
        var shouldThrowError = false
        
        func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
            []
        }
        
        func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
            []
        }
        
        func getSetDetails(setNum: String) async throws -> LegoSet? {
            nil
        }
        
        func getCachedSets() async -> [LegoSet] {
            []
        }
        
        func markAsFavorite(_ set: LegoSet) async throws {
            if shouldThrowError {
                throw BrixieError.networkError(underlying: NSError(domain: "test", code: 1))
            }
            markAsFavoriteCallCount += 1
            lastSetMarkedAsFavorite = set
        }
        
        func removeFromFavorites(_ set: LegoSet) async throws {
            if shouldThrowError {
                throw BrixieError.networkError(underlying: NSError(domain: "test", code: 1))
            }
            removeFromFavoritesCallCount += 1
            lastSetRemovedFromFavorites = set
        }
        
        func getFavoriteSets() async -> [LegoSet] {
            []
        }
    }
    
    // Mock error handling view model
    @MainActor
    final class MockViewModel: ViewModelErrorHandling {
        var error: BrixieError?
    }
    
    @Test
    @MainActor
    func testToggleFavoriteOnRepository_markAsFavorite() async throws {
        let repository = MockLegoSetRepository()
        let set = LegoSet(setNum: "123", name: "Test Set", year: 2023, themeId: 1, numParts: 100)
        set.isFavorite = false
        
        try await toggleFavoriteOnRepository(set: set, repository: repository)
        
        #expect(repository.markAsFavoriteCallCount == 1)
        #expect(repository.removeFromFavoritesCallCount == 0)
        #expect(repository.lastSetMarkedAsFavorite?.setNum == "123")
    }
    
    @Test
    @MainActor
    func testToggleFavoriteOnRepository_removeFromFavorites() async throws {
        let repository = MockLegoSetRepository()
        let set = LegoSet(setNum: "456", name: "Test Set", year: 2023, themeId: 1, numParts: 100)
        set.isFavorite = true
        
        try await toggleFavoriteOnRepository(set: set, repository: repository)
        
        #expect(repository.markAsFavoriteCallCount == 0)
        #expect(repository.removeFromFavoritesCallCount == 1)
        #expect(repository.lastSetRemovedFromFavorites?.setNum == "456")
    }
    
    @Test
    @MainActor
    func testToggleFavoriteOnRepository_throwsError() async throws {
        let repository = MockLegoSetRepository()
        repository.shouldThrowError = true
        let set = LegoSet(setNum: "789", name: "Test Set", year: 2023, themeId: 1, numParts: 100)
        
        do {
            try await toggleFavoriteOnRepository(set: set, repository: repository)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is BrixieError)
        }
    }
    
    @Test
    @MainActor
    func testViewModelErrorHandling_brixieError() {
        let viewModel = MockViewModel()
        let originalError = BrixieError.apiKeyMissing
        
        viewModel.handleError(originalError)
        
        #expect(viewModel.error == BrixieError.apiKeyMissing)
    }
    
    @Test
    @MainActor
    func testViewModelErrorHandling_wrappedError() {
        let viewModel = MockViewModel()
        let originalError = NSError(domain: "test", code: 123)
        
        viewModel.handleError(originalError)
        
        if case let .networkError(underlying) = viewModel.error {
            #expect((underlying as NSError).code == 123)
        } else {
            #expect(Bool(false), "Should be networkError")
        }
    }
}