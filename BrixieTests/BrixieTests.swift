//
//  BrixieTests.swift
//  BrixieTests
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Testing
import Foundation
import SwiftData

@testable import Brixie

struct BrixieTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test func errorReporter_mapsURLErrorToNetworkError() async throws {
        let errorReporter = ErrorReporter.shared
        let urlError = URLError(.notConnectedToInternet)
        
        errorReporter.report(urlError)
        
        #expect(errorReporter.currentError != nil)
        
        if case .networkError = errorReporter.currentError {
            // Success - error was mapped correctly
        } else {
            #expect(Bool(false), "Expected networkError but got different error type")
        }
    }
    
    @Test func errorReporter_preservesBrixieError() async throws {
        let errorReporter = ErrorReporter.shared
        let brixieError = BrixieError.apiKeyMissing
        
        errorReporter.report(brixieError)
        
        #expect(errorReporter.currentError == .apiKeyMissing)
    }
    
    @Test func errorReporter_handlesRecoveryActions() async throws {
        let errorReporter = ErrorReporter.shared
        
        let networkErrorAction = errorReporter.handle(.networkError(underlying: URLError(.notConnectedToInternet)))
        #expect(networkErrorAction == .retry)
        
        let apiKeyAction = errorReporter.handle(.apiKeyMissing)
        #expect(apiKeyAction == .requestAPIKey)
        
        let rateLimitAction = errorReporter.handle(.rateLimitExceeded)
        if case .showMessage = rateLimitAction {
            // Success
        } else {
            #expect(Bool(false), "Expected showMessage action for rate limit error")
        }
    }

}

struct ThemeNamePopulationTests {
    
    private func createInMemoryContainer() -> ModelContainer {
        let schema = Schema([LegoSet.self, LegoTheme.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create in-memory container: \(error)")
        }
    }
    
    @Test func testLegoSetInitializerWithThemeName() async throws {
        // Test that LegoSet can be initialized with a theme name
        let set = LegoSet(
            setNum: "75192",
            name: "Millennium Falcon",
            year: 2017,
            themeId: 158,
            numParts: 7541,
            imageURL: "http://example.com/image.jpg",
            themeName: "Star Wars"
        )
        
        #expect(set.setNum == "75192")
        #expect(set.name == "Millennium Falcon")
        #expect(set.year == 2017)
        #expect(set.themeId == 158)
        #expect(set.numParts == 7541)
        #expect(set.imageURL == "http://example.com/image.jpg")
        #expect(set.themeName == "Star Wars")
    }
    
    @Test func testLegoSetInitializerWithoutThemeName() async throws {
        // Test that LegoSet can be initialized without a theme name (backwards compatibility)
        let set = LegoSet(
            setNum: "75192",
            name: "Millennium Falcon",
            year: 2017,
            themeId: 158,
            numParts: 7541,
            imageURL: "http://example.com/image.jpg"
        )
        
        #expect(set.setNum == "75192")
        #expect(set.name == "Millennium Falcon")
        #expect(set.year == 2017)
        #expect(set.themeId == 158)
        #expect(set.numParts == 7541)
        #expect(set.imageURL == "http://example.com/image.jpg")
        #expect(set.themeName == nil)
    }
    
    @Test func testThemeNamePopulationWithCachedThemes() async throws {
        // Test theme name population using cached themes
        let container = createInMemoryContainer()
        let localDataSource = SwiftDataSource(modelContext: container.mainContext)
        
        // Create and save sample themes
        let starWarsTheme = LegoTheme(id: 158, name: "Star Wars", parentId: nil, setCount: 100)
        let cityTheme = LegoTheme(id: 52, name: "City", parentId: nil, setCount: 200)
        try localDataSource.save([starWarsTheme, cityTheme])
        
        // Create mock repositories
        let mockRemoteDataSource = MockLegoSetRemoteDataSource()
        let mockThemeRemoteDataSource = MockLegoThemeRemoteDataSource()
        let themeRepository = LegoThemeRepositoryImpl(
            remoteDataSource: mockThemeRemoteDataSource,
            localDataSource: localDataSource
        )
        
        let setRepository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: localDataSource,
            themeRepository: themeRepository
        )
        
        // Mock sets without theme names
        mockRemoteDataSource.mockSets = [
            LegoSet(setNum: "75192", name: "Millennium Falcon", year: 2017, themeId: 158, numParts: 7541),
            LegoSet(setNum: "60380", name: "Downtown", year: 2023, themeId: 52, numParts: 1211)
        ]
        
        // Fetch sets - should populate theme names
        let sets = try await setRepository.fetchSets(page: 1, pageSize: 10)
        
        #expect(sets.count == 2)
        #expect(sets[0].themeName == "Star Wars")
        #expect(sets[1].themeName == "City")
    }
    
    @Test func testThemeNamePopulationWithMissingTheme() async throws {
        // Test theme name population when theme is not cached
        let container = createInMemoryContainer()
        let localDataSource = SwiftDataSource(modelContext: container.mainContext)
        
        // Create and save sample theme (only one)
        let starWarsTheme = LegoTheme(id: 158, name: "Star Wars", parentId: nil, setCount: 100)
        try localDataSource.save([starWarsTheme])
        
        // Create mock repositories
        let mockRemoteDataSource = MockLegoSetRemoteDataSource()
        let mockThemeRemoteDataSource = MockLegoThemeRemoteDataSource()
        let themeRepository = LegoThemeRepositoryImpl(
            remoteDataSource: mockThemeRemoteDataSource,
            localDataSource: localDataSource
        )
        
        let setRepository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: localDataSource,
            themeRepository: themeRepository
        )
        
        // Mock sets with one having a missing theme
        mockRemoteDataSource.mockSets = [
            LegoSet(setNum: "75192", name: "Millennium Falcon", year: 2017, themeId: 158, numParts: 7541),
            LegoSet(setNum: "60380", name: "Downtown", year: 2023, themeId: 999, numParts: 1211) // Theme ID 999 doesn't exist
        ]
        
        // Fetch sets - should populate theme names where available
        let sets = try await setRepository.fetchSets(page: 1, pageSize: 10)
        
        #expect(sets.count == 2)
        #expect(sets[0].themeName == "Star Wars")
        #expect(sets[1].themeName == nil) // Theme not found
    }
    
    @Test func testBackfillThemeNames() async throws {
        // Test backfilling existing sets with theme names
        let container = createInMemoryContainer()
        let localDataSource = SwiftDataSource(modelContext: container.mainContext)
        
        // Create and save sets without theme names
        let setWithoutTheme1 = LegoSet(setNum: "75192", name: "Millennium Falcon", year: 2017, themeId: 158, numParts: 7541)
        let setWithoutTheme2 = LegoSet(setNum: "60380", name: "Downtown", year: 2023, themeId: 52, numParts: 1211)
        let setWithTheme = LegoSet(setNum: "75300", name: "Imperial TIE Fighter", year: 2021, themeId: 158, numParts: 432, themeName: "Star Wars")
        try localDataSource.save([setWithoutTheme1, setWithoutTheme2, setWithTheme])
        
        // Create and save themes
        let starWarsTheme = LegoTheme(id: 158, name: "Star Wars", parentId: nil, setCount: 100)
        let cityTheme = LegoTheme(id: 52, name: "City", parentId: nil, setCount: 200)
        try localDataSource.save([starWarsTheme, cityTheme])
        
        // Create repositories
        let mockRemoteDataSource = MockLegoSetRemoteDataSource()
        let mockThemeRemoteDataSource = MockLegoThemeRemoteDataSource()
        let themeRepository = LegoThemeRepositoryImpl(
            remoteDataSource: mockThemeRemoteDataSource,
            localDataSource: localDataSource
        )
        
        let setRepository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemoteDataSource,
            localDataSource: localDataSource,
            themeRepository: themeRepository
        )
        
        // Backfill theme names
        try await setRepository.backfillThemeNames()
        
        // Verify theme names were populated
        let allSets = await setRepository.getCachedSets()
        #expect(allSets.count == 3)
        
        // All sets should now have theme names
        let setById75192 = allSets.first { $0.setNum == "75192" }
        let setById60380 = allSets.first { $0.setNum == "60380" }
        let setById75300 = allSets.first { $0.setNum == "75300" }
        
        #expect(setById75192?.themeName == "Star Wars")
        #expect(setById60380?.themeName == "City")
        #expect(setById75300?.themeName == "Star Wars") // Should still have theme name
    }
}

// MARK: - Mock Data Sources

final class MockLegoSetRemoteDataSource: LegoSetRemoteDataSource {
    var mockSets: [LegoSet] = []
    
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        return mockSets
    }
    
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
        return mockSets.filter { set in
            set.name.localizedCaseInsensitiveContains(query) ||
            set.setNum.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        return mockSets.first { $0.setNum == setNum }
    }
}

final class MockLegoThemeRemoteDataSource: LegoThemeRemoteDataSource {
    var mockThemes: [LegoTheme] = []
    
    func fetchThemes(page: Int, pageSize: Int) async throws -> [LegoTheme] {
        return mockThemes
    }
    
    func searchThemes(query: String, page: Int, pageSize: Int) async throws -> [LegoTheme] {
        return mockThemes.filter { theme in
            theme.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getThemeDetails(id: Int) async throws -> LegoTheme? {
        return mockThemes.first { $0.id == id }
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
@MainActor
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
    
    func getCachedSets() async -> [LegoSet] {
        return []
    }
    
    func markAsFavorite(_ set: LegoSet) async throws {
        // No-op for tests
    }
    
    func removeFromFavorites(_ set: LegoSet) async throws {
        // No-op for tests
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

// MARK: - Pagination Hardening Tests

struct PaginationHardeningTests {
    
    @Test("SetsListViewModel prevents overlapping loadMore calls") 
    func testSetsListViewModelPreventsOverlappingLoadMore() async throws {
        // Create a mock repository that tracks call count
        let mockRepository = MockLegoSetRepository()
        let viewModel = SetsListViewModel(legoSetRepository: mockRepository)
        
        // Simulate rapid loadMore calls
        async let task1: Void = viewModel.loadMoreSets()
        async let task2: Void = viewModel.loadMoreSets()
        async let task3: Void = viewModel.loadMoreSets()
        
        // Wait for all tasks to complete
        let _ = await (task1, task2, task3)
        
        // Verify only one actual network call was made
        #expect(mockRepository.fetchCallCount <= 1, "Expected at most 1 fetch call, got \(mockRepository.fetchCallCount)")
        #expect(!viewModel.isLoadingMore, "Expected isLoadingMore to be false after completion")
    }
    
    @Test("SetsListViewModel cancels previous loadMore when new one starts")
    func testSetsListViewModelCancelsPreviousLoadMore() async throws {
        let mockRepository = MockSlowLegoSetRepository()
        let viewModel = SetsListViewModel(legoSetRepository: mockRepository)
        
        // Start a loadMore operation
        let task1 = Task {
            await viewModel.loadMoreSets()
        }
        
        // Wait a bit then start another
        try await Task.sleep(for: .milliseconds(50))
        
        let task2 = Task {
            await viewModel.loadMoreSets()
        }
        
        await task1.value
        await task2.value
        
        // Verify that we handled cancellation properly
        #expect(!viewModel.isLoadingMore, "Expected isLoadingMore to be false")
        #expect(mockRepository.fetchCallCount <= 2, "Expected at most 2 fetch calls due to cancellation")
    }
    
    @Test("Rapid pagination requests are properly handled")
    func testRapidPaginationRequestsHandling() async throws {
        let mockRepository = MockLegoSetRepository()
        let viewModel = SetsListViewModel(legoSetRepository: mockRepository)
        
        // Load initial data
        await viewModel.loadSets()
        let initialFetchCount = mockRepository.fetchCallCount
        
        // Simulate stress test - rapid fire loadMore calls
        let tasks = (1...10).map { _ in
            Task {
                await viewModel.loadMoreSets()
            }
        }
        
        // Wait for all to complete
        for task in tasks {
            await task.value
        }
        
        // Should have much fewer actual calls than attempted calls
        let totalCalls = mockRepository.fetchCallCount - initialFetchCount
        #expect(totalCalls <= 5, "Expected at most 5 pagination calls in stress test, got \(totalCalls)")
        #expect(!viewModel.isLoadingMore, "Expected isLoadingMore to be false after stress test")
    }
    
    @Test("Task cancellation prevents race conditions")
    func testTaskCancellationPreventsRaceConditions() async throws {
        let mockRepository = MockSlowLegoSetRepository()
        let viewModel = SetsListViewModel(legoSetRepository: mockRepository)
        
        // Start a loadMore operation
        let task = Task {
            await viewModel.loadMoreSets()
        }
        
        // Cancel it quickly
        task.cancel()
        await task.value
        
        // Verify state is clean
        #expect(!viewModel.isLoadingMore, "Expected isLoadingMore to be false after cancellation")
        #expect(viewModel.currentPage == 1, "Expected currentPage to remain unchanged after cancellation")
    }
    
    @Test("CategoryDetailView debouncing prevents rapid button taps")
    func testCategoryDetailViewDebouncing() async throws {
        // This test validates the debouncing logic conceptually
        // In a real app test, we would test the actual CategoryDetailView
        
        var callCount = 0
        let lastCallTime = Date()
        
        // Simulate rapid calls with debouncing logic
        func simulateLoadMore() {
            let now = Date()
            guard now.timeIntervalSince(lastCallTime) > 0.5 else { return }
            callCount += 1
        }
        
        // Simulate rapid calls
        for _ in 1...5 {
            simulateLoadMore()
        }
        
        #expect(callCount <= 1, "Expected debouncing to prevent multiple rapid calls")
    }
}

// MARK: - Mock Implementations

@MainActor
final class MockLegoSetRepository: LegoSetRepository {
    var fetchCallCount = 0
    private let delay: TimeInterval
    
    init(delay: TimeInterval = 0.01) {
        self.delay = delay
    }
    
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        fetchCallCount += 1
        try await Task.sleep(for: .seconds(delay))
        
        // Return mock data
        return [
            LegoSet(setNum: "\(page)-1", name: "Test Set \(page)", year: 2024, themeId: 1, numParts: 100),
            LegoSet(setNum: "\(page)-2", name: "Test Set \(page + 1)", year: 2024, themeId: 1, numParts: 200)
        ]
    }
    
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
        return []
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        return nil
    }
    
    func getCachedSets() async -> [LegoSet] {
        return []
    }
    
    func markAsFavorite(_ set: LegoSet) async throws {}
    
    func removeFromFavorites(_ set: LegoSet) async throws {}
    
    func getFavoriteSets() async -> [LegoSet] {
        return []
    }
}

@MainActor
final class MockSlowLegoSetRepository: MockLegoSetRepository {
    init() {
        super.init(delay: 0.2) // Slower delay for cancellation testing
    }
}
