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

struct RecentSearchesStorageTests {
    
    @Test("RecentSearchesStorage saves and loads searches correctly")
    @MainActor
    func testSaveAndLoadSearches() async throws {
        // Create a test instance with a unique key to avoid conflicts
        let testStorage = TestRecentSearchesStorage()
        
        // Test initial state
        let initialSearches = testStorage.loadRecentSearches()
        #expect(initialSearches.isEmpty)
        
        // Add some searches
        let testSearches = ["Star Wars", "Creator", "Technic", "City", "Friends"]
        for search in testSearches {
            testStorage.addSearch(search)
        }
        
        // Verify searches are saved and loaded correctly
        let loadedSearches = testStorage.loadRecentSearches()
        #expect(loadedSearches.count == 5)
        #expect(loadedSearches[0] == "Friends") // Most recent first
        #expect(loadedSearches[4] == "Star Wars") // Oldest last
    }
    
    @Test("RecentSearchesStorage limits to 5 searches maximum")
    @MainActor
    func testMaximumSearchLimit() async throws {
        let testStorage = TestRecentSearchesStorage()
        
        // Add more than 5 searches
        let testSearches = ["Search1", "Search2", "Search3", "Search4", "Search5", "Search6", "Search7"]
        for search in testSearches {
            testStorage.addSearch(search)
        }
        
        // Verify only 5 searches are kept
        let loadedSearches = testStorage.loadRecentSearches()
        #expect(loadedSearches.count == 5)
        #expect(loadedSearches[0] == "Search7") // Most recent
        #expect(loadedSearches[4] == "Search3") // 5th most recent
    }
    
    @Test("RecentSearchesStorage avoids duplicates and moves existing to top")
    @MainActor
    func testDuplicateHandling() async throws {
        let testStorage = TestRecentSearchesStorage()
        
        // Add some searches
        testStorage.addSearch("Search1")
        testStorage.addSearch("Search2")
        testStorage.addSearch("Search3")
        
        // Add a duplicate - should move to top, not create duplicate
        testStorage.addSearch("Search1")
        
        let loadedSearches = testStorage.loadRecentSearches()
        #expect(loadedSearches.count == 3)
        #expect(loadedSearches[0] == "Search1") // Moved to top
        #expect(loadedSearches[1] == "Search3")
        #expect(loadedSearches[2] == "Search2")
    }
    
    @Test("RecentSearchesStorage handles corrupted data gracefully")
    @MainActor
    func testCorruptedDataHandling() async throws {
        let testStorage = TestRecentSearchesStorage()
        
        // Simulate corrupted data by setting invalid JSON
        testStorage.userDefaults.set("invalid json data".data(using: .utf8), forKey: testStorage.storageKey)
        
        // Should return empty array and clear corrupted data
        let loadedSearches = testStorage.loadRecentSearches()
        #expect(loadedSearches.isEmpty)
        
        // Verify corrupted data was cleared
        #expect(testStorage.userDefaults.data(forKey: testStorage.storageKey) == nil)
    }
    
    @Test("RecentSearchesStorage clears all searches")
    @MainActor
    func testClearSearches() async throws {
        let testStorage = TestRecentSearchesStorage()
        
        // Add some searches
        testStorage.addSearch("Search1")
        testStorage.addSearch("Search2")
        
        // Clear all searches
        testStorage.clearRecentSearches()
        
        // Verify searches are cleared
        let loadedSearches = testStorage.loadRecentSearches()
        #expect(loadedSearches.isEmpty)
    }
}

// Test helper class that uses a separate UserDefaults suite for testing
@MainActor
final class TestRecentSearchesStorage {
    let userDefaults: UserDefaults
    let storageKey = "test_recentSearches"
    private let maxSearches = 5
    
    init() {
        // Use a test-specific UserDefaults suite
        self.userDefaults = UserDefaults(suiteName: "BrixieTestSuite") ?? UserDefaults.standard
        // Clear any existing test data
        clearRecentSearches()
    }
    
    func loadRecentSearches() -> [String] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }
        
        do {
            let searches = try JSONDecoder().decode([String].self, from: data)
            return Array(searches.prefix(maxSearches))
        } catch {
            userDefaults.removeObject(forKey: storageKey)
            return []
        }
    }
    
    func saveRecentSearches(_ searches: [String]) {
        let limitedSearches = Array(searches.prefix(maxSearches))
        
        do {
            let data = try JSONEncoder().encode(limitedSearches)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            // Handle encoding failure silently in tests
        }
    }
    
    func addSearch(_ search: String) {
        var searches = loadRecentSearches()
        searches.removeAll { $0 == search }
        searches.insert(search, at: 0)
        saveRecentSearches(searches)
    }
    
    func clearRecentSearches() {
        userDefaults.removeObject(forKey: storageKey)
    }
}

struct SearchViewModelTests {
    
    @Test("SearchViewModel loads recent searches on initialization")
    @MainActor
    func testLoadRecentSearchesOnInit() async throws {
        // Setup: Create test storage with some searches
        let testStorage = TestRecentSearchesStorage()
        testStorage.addSearch("Test Search 1")
        testStorage.addSearch("Test Search 2")
        
        // Create a test SearchViewModel with mock repositories
        let mockLegoSetRepo = MockLegoSetRepository()
        let mockLegoThemeRepo = MockLegoThemeRepository()
        
        // Convert test storage to match expected type
        let productionStorage = RecentSearchesStorage.shared
        productionStorage.clearRecentSearches()
        productionStorage.addSearch("Test Search 1")
        productionStorage.addSearch("Test Search 2")
        
        let viewModel = SearchViewModel(
            legoSetRepository: mockLegoSetRepo,
            legoThemeRepository: mockLegoThemeRepo,
            recentSearchesStorage: productionStorage
        )
        
        // Verify recent searches are loaded
        #expect(viewModel.recentSearches.count == 2)
        #expect(viewModel.recentSearches[0] == "Test Search 2") // Most recent first
        #expect(viewModel.recentSearches[1] == "Test Search 1")
        
        // Cleanup
        productionStorage.clearRecentSearches()
    }
    
    @Test("SearchViewModel persists searches when performing search")
    @MainActor
    func testPersistSearchOnPerform() async throws {
        let mockLegoSetRepo = MockLegoSetRepository()
        let mockLegoThemeRepo = MockLegoThemeRepository()
        let testStorage = RecentSearchesStorage.shared
        testStorage.clearRecentSearches()
        
        let viewModel = SearchViewModel(
            legoSetRepository: mockLegoSetRepo,
            legoThemeRepository: mockLegoThemeRepo,
            recentSearchesStorage: testStorage
        )
        
        // Perform a search
        viewModel.searchText = "LEGO Castle"
        await viewModel.performSearch()
        
        // Verify the search was added to recent searches
        #expect(viewModel.recentSearches.count == 1)
        #expect(viewModel.recentSearches[0] == "LEGO Castle")
        
        // Verify it's also persisted in storage
        let persistedSearches = testStorage.loadRecentSearches()
        #expect(persistedSearches.count == 1)
        #expect(persistedSearches[0] == "LEGO Castle")
        
        // Cleanup
        testStorage.clearRecentSearches()
    }
}

// Mock implementations for testing
final class MockLegoSetRepository: LegoSetRepository {
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        return [] // Return empty for tests
    }
    
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
        return [] // Return empty for tests
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        return nil
    }
    
    func markAsFavorite(_ set: LegoSet) async throws {
        // No-op for tests
    }
    
    func removeFromFavorites(_ set: LegoSet) async throws {
        // No-op for tests
    }
    
    func getFavorites() async throws -> [LegoSet] {
        return []
    }
}

final class MockLegoThemeRepository: LegoThemeRepository {
    func fetchThemes() async throws -> [LegoTheme] {
        return []
    }
}
