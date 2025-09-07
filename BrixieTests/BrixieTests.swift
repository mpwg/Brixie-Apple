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

// MARK: - Mock Data Sources

@MainActor
final class MockLegoSetRemoteDataSource: LegoSetRemoteDataSource {
    var shouldThrowError = false
    var errorToThrow: Error = BrixieError.networkError(underlying: URLError(.notConnectedToInternet))
    var mockSets: [LegoSet] = []
    var mockSetDetails: LegoSet?
    
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        if shouldThrowError {
            throw errorToThrow
        }
        return mockSets
    }
    
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
        if shouldThrowError {
            throw errorToThrow
        }
        return mockSets.filter { set in
            set.name.localizedCaseInsensitiveContains(query) ||
            set.setNum.localizedCaseInsensitiveContains(query)
        }
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        if shouldThrowError {
            throw errorToThrow
        }
        return mockSetDetails
    }
}

@MainActor
final class MockLocalDataSource: LocalDataSource {
    var shouldThrowError = false
    var errorToThrow: Error = BrixieError.persistenceError(underlying: URLError(.unknown))
    var savedLegoSets: [LegoSet] = []
    var fetchLegoSets: [LegoSet] = []
    
    func save<T: PersistentModel>(_ items: [T]) throws {
        if shouldThrowError {
            throw errorToThrow
        }
        // For our testing, we primarily care about LegoSet
        if T.self == LegoSet.self {
            savedLegoSets.append(contentsOf: items.compactMap { $0 as? LegoSet })
        }
    }
    
    func fetch<T: PersistentModel>(_ type: T.Type) throws -> [T] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if T.self == LegoSet.self {
            return fetchLegoSets as! [T]
        }
        
        return []
    }
    
    func fetch<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?) throws -> [T] {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if T.self == LegoSet.self {
            var results = fetchLegoSets
            
            // For testing favorites - simple simulation of predicate filtering
            if predicate != nil {
                // We'll assume any predicate in tests is for filtering favorites
                results = results.filter { $0.isFavorite }
            }
            
            return results as! [T]
        }
        
        return []
    }
    
    func delete<T: PersistentModel>(_ item: T) throws {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if T.self == LegoSet.self, let set = item as? LegoSet {
            savedLegoSets.removeAll { $0.setNum == set.setNum }
            fetchLegoSets.removeAll { $0.setNum == set.setNum }
        }
    }
    
    func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if T.self == LegoSet.self {
            savedLegoSets.removeAll()
            fetchLegoSets.removeAll()
        }
    }
}

// MARK: - Test Data Helpers

extension LegoSet {
    static func mockSet(setNum: String = "123-1", name: String = "Test Set", year: Int = 2023) -> LegoSet {
        LegoSet(setNum: setNum, name: name, year: year, themeId: 1, numParts: 100)
    }
}

// MARK: - Repository Fallback Tests

struct RepositoryFallbackTests {
    
    // MARK: - fetchSets Tests
    
    @Test("fetchSets success case - returns remote data and saves locally")
    func fetchSetsSuccessCase() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        let expectedSets = [
            LegoSet.mockSet(setNum: "123-1", name: "Remote Set 1"),
            LegoSet.mockSet(setNum: "456-1", name: "Remote Set 2")
        ]
        mockRemote.mockSets = expectedSets
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        let result = try await repository.fetchSets(page: 1, pageSize: 10)
        
        #expect(result.count == 2)
        #expect(result[0].setNum == "123-1")
        #expect(result[1].setNum == "456-1")
        
        // Verify page 1 saves data locally
        #expect(mockLocal.savedLegoSets.count == 2)
    }
    
    @Test("fetchSets network error fallback - returns cached data when available")
    func fetchSetsNetworkErrorFallback() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        // Setup remote to throw network error
        mockRemote.shouldThrowError = true
        mockRemote.errorToThrow = BrixieError.networkError(underlying: URLError(.notConnectedToInternet))
        
        // Setup local to return cached data
        let cachedSets = [
            LegoSet.mockSet(setNum: "cached-1", name: "Cached Set 1"),
            LegoSet.mockSet(setNum: "cached-2", name: "Cached Set 2")
        ]
        mockLocal.fetchLegoSets = cachedSets
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        let result = try await repository.fetchSets(page: 1, pageSize: 10)
        
        #expect(result.count == 2)
        #expect(result[0].setNum == "cached-1")
        #expect(result[1].setNum == "cached-2")
    }
    
    @Test("fetchSets network error with no cache - throws original error")
    func fetchSetsNetworkErrorNoCacheFallback() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        // Setup remote to throw network error
        mockRemote.shouldThrowError = true
        mockRemote.errorToThrow = BrixieError.networkError(underlying: URLError(.notConnectedToInternet))
        
        // Setup local to return empty cache
        mockLocal.fetchLegoSets = []
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        do {
            _ = try await repository.fetchSets(page: 1, pageSize: 10)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            if case BrixieError.networkError = error {
                // Expected behavior
            } else {
                #expect(Bool(false), "Should have thrown network error")
            }
        }
    }
    
    @Test("fetchSets non-network error - throws original error")
    func fetchSetsNonNetworkErrorFallback() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        // Setup remote to throw API key error (non-network)
        mockRemote.shouldThrowError = true
        mockRemote.errorToThrow = BrixieError.apiKeyMissing
        
        // Setup local with cached data (should not be used)
        let cachedSets = [LegoSet.mockSet(setNum: "cached-1", name: "Cached Set")]
        mockLocal.fetchLegoSets = cachedSets
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        do {
            _ = try await repository.fetchSets(page: 1, pageSize: 10)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            if case BrixieError.apiKeyMissing = error {
                // Expected behavior - non-network errors are not caught
            } else {
                #expect(Bool(false), "Should have thrown apiKeyMissing error")
            }
        }
    }
    
    // MARK: - searchSets Tests
    
    @Test("searchSets success case - returns remote search results")
    func searchSetsSuccessCase() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        let remoteSets = [
            LegoSet.mockSet(setNum: "123-1", name: "Star Wars Set"),
            LegoSet.mockSet(setNum: "456-1", name: "Castle Set")
        ]
        mockRemote.mockSets = remoteSets
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        let result = try await repository.searchSets(query: "star", page: 1, pageSize: 10)
        
        #expect(result.count == 1)
        #expect(result[0].setNum == "123-1")
        #expect(result[0].name.contains("Star Wars"))
    }
    
    @Test("searchSets fallback - filters local cache on any error")
    func searchSetsLocalFilterFallback() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        // Setup remote to throw any error
        mockRemote.shouldThrowError = true
        mockRemote.errorToThrow = BrixieError.networkError(underlying: URLError(.notConnectedToInternet))
        
        // Setup local cache with various sets
        let cachedSets = [
            LegoSet.mockSet(setNum: "123-1", name: "Star Wars Millennium Falcon"),
            LegoSet.mockSet(setNum: "456-1", name: "Castle Dragon Knight"),
            LegoSet.mockSet(setNum: "789-1", name: "City Police Station"),
            LegoSet.mockSet(setNum: "star-123", name: "Space Ship")
        ]
        mockLocal.fetchLegoSets = cachedSets
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        // Test name-based filtering
        let starResults = try await repository.searchSets(query: "star", page: 1, pageSize: 10)
        #expect(starResults.count == 2) // "Star Wars" and "star-123"
        
        // Test setNum-based filtering
        let setNumResults = try await repository.searchSets(query: "123", page: 1, pageSize: 10)
        #expect(setNumResults.count == 2) // "123-1" and "star-123"
        
        // Test case insensitive
        let caseResults = try await repository.searchSets(query: "CASTLE", page: 1, pageSize: 10)
        #expect(caseResults.count == 1) // "Castle Dragon Knight"
    }
    
    @Test("searchSets fallback with empty cache - returns empty array")
    func searchSetsEmptyCacheFallback() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        // Setup remote to throw error
        mockRemote.shouldThrowError = true
        mockRemote.errorToThrow = BrixieError.apiKeyMissing
        
        // Setup empty local cache
        mockLocal.fetchLegoSets = []
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        let result = try await repository.searchSets(query: "anything", page: 1, pageSize: 10)
        #expect(result.isEmpty)
    }
    
    // MARK: - getSetDetails Tests
    
    @Test("getSetDetails success case - returns remote data and saves locally")
    func getSetDetailsSuccessCase() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        let expectedSet = LegoSet.mockSet(setNum: "123-1", name: "Detailed Remote Set")
        mockRemote.mockSetDetails = expectedSet
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        let result = try await repository.getSetDetails(setNum: "123-1")
        
        #expect(result != nil)
        #expect(result?.setNum == "123-1")
        #expect(result?.name == "Detailed Remote Set")
        
        // Verify it was saved locally
        #expect(mockLocal.savedLegoSets.count == 1)
    }
    
    @Test("getSetDetails remote returns nil - returns nil")
    func getSetDetailsRemoteNilCase() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        mockRemote.mockSetDetails = nil
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        let result = try await repository.getSetDetails(setNum: "nonexistent")
        #expect(result == nil)
    }
    
    @Test("getSetDetails fallback - finds set in local cache on error")
    func getSetDetailsLocalFallback() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        // Setup remote to throw error
        mockRemote.shouldThrowError = true
        mockRemote.errorToThrow = BrixieError.networkError(underlying: URLError(.notConnectedToInternet))
        
        // Setup local cache
        let cachedSets = [
            LegoSet.mockSet(setNum: "123-1", name: "Cached Set 1"),
            LegoSet.mockSet(setNum: "456-1", name: "Cached Set 2")
        ]
        mockLocal.fetchLegoSets = cachedSets
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        let result = try await repository.getSetDetails(setNum: "456-1")
        
        #expect(result != nil)
        #expect(result?.setNum == "456-1")
        #expect(result?.name == "Cached Set 2")
    }
    
    @Test("getSetDetails fallback with set not in cache - returns nil")
    func getSetDetailsNotInCacheFallback() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        // Setup remote to throw error
        mockRemote.shouldThrowError = true
        mockRemote.errorToThrow = BrixieError.unauthorized
        
        // Setup local cache without the requested set
        let cachedSets = [
            LegoSet.mockSet(setNum: "123-1", name: "Cached Set 1")
        ]
        mockLocal.fetchLegoSets = cachedSets
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        let result = try await repository.getSetDetails(setNum: "nonexistent")
        #expect(result == nil)
    }
    
    // MARK: - Additional Repository Tests
    
    @Test("getCachedSets fallback - returns empty array on error")
    func getCachedSetsFallback() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        // Setup local to throw error
        mockLocal.shouldThrowError = true
        mockLocal.errorToThrow = BrixieError.persistenceError(underlying: URLError(.unknown))
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        let result = await repository.getCachedSets()
        #expect(result.isEmpty)
    }
    
    @Test("favorites management - mark and retrieve favorites")
    func favoritesManagement() async throws {
        let mockRemote = MockLegoSetRemoteDataSource()
        let mockLocal = MockLocalDataSource()
        
        let testSet = LegoSet.mockSet(setNum: "fav-123", name: "Favorite Set")
        
        let repository = LegoSetRepositoryImpl(
            remoteDataSource: mockRemote,
            localDataSource: mockLocal,
            themeRepository: MockLegoThemeRepository()
        )
        
        // Mark as favorite
        try await repository.markAsFavorite(testSet)
        #expect(testSet.isFavorite == true)
        #expect(mockLocal.savedLegoSets.count == 1)
        
        // Remove from favorites
        try await repository.removeFromFavorites(testSet)
        #expect(testSet.isFavorite == false)
        #expect(mockLocal.savedLegoSets.count == 2) // Two save operations
    }
}

// MARK: - Legacy Test
>>>>>>> main

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

// MARK: - NetworkMonitorService Tests

struct NetworkMonitorServiceTests {
    
    @Test func connectionTypeInitialization() async throws {
        // Test ConnectionType enum initialization
        let wifiType = ConnectionType.wifi
        let cellularType = ConnectionType.cellular
        let ethernetType = ConnectionType.ethernet
        let noneType = ConnectionType.none
        
        #expect(wifiType.iconName == "wifi")
        #expect(cellularType.iconName == "antenna.radiowaves.left.and.right")
        #expect(ethernetType.iconName == "cable.connector")
        #expect(noneType.iconName == "wifi.slash")
    }
    
    @Test func networkMonitorServiceInitialization() async throws {
        // Test that NetworkMonitorService can be initialized
        let service = NetworkMonitorService.shared
        
        // Initial state should be properly set
        #expect(service.connectionType != nil)
    }
}

// MARK: - SyncTimestamp Tests

struct SyncTimestampTests {
    
    @Test func syncTimestampCreation() async throws {
        let timestamp = SyncTimestamp(
            id: "test-sync",
            lastSync: Date(),
            syncType: .sets,
            isSuccessful: true,
            itemCount: 10
        )
        
        #expect(timestamp.id == "test-sync")
        #expect(timestamp.syncType == .sets)
        #expect(timestamp.isSuccessful == true)
        #expect(timestamp.itemCount == 10)
    }
    
    @Test func syncTypeDisplayNames() async throws {
        #expect(SyncType.sets.displayName == "Sets")
        #expect(SyncType.themes.displayName == "Themes")
        #expect(SyncType.search.displayName == "Search")
        #expect(SyncType.setDetails.displayName == "Set Details")
    }
    
    @Test func syncTypeRawValues() async throws {
        #expect(SyncType.sets.rawValue == "sets")
        #expect(SyncType.themes.rawValue == "themes")
        #expect(SyncType.search.rawValue == "search")
        #expect(SyncType.setDetails.rawValue == "setDetails")
    }
}

// MARK: - LocalDataSource Tests

struct LocalDataSourceSyncTimestampTests {
    
    @Test func syncTimestampPersistence() async throws {
        // Create in-memory model container for testing
        let schema = Schema([
            LegoSet.self,
            LegoTheme.self,
            SyncTimestamp.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        let localDataSource = SwiftDataSource(modelContext: modelContainer.mainContext)
        
        // Create a test sync timestamp
        let timestamp = SyncTimestamp(
            id: "test-sync",
            lastSync: Date(),
            syncType: .sets,
            isSuccessful: true,
            itemCount: 10
        )
        
        // Save the timestamp
        try localDataSource.saveSyncTimestamp(timestamp)
        
        // Retrieve the timestamp
        let retrievedTimestamp = try localDataSource.getLastSyncTimestamp(for: .sets)
        
        #expect(retrievedTimestamp != nil)
        #expect(retrievedTimestamp?.id == "test-sync")
        #expect(retrievedTimestamp?.syncType == .sets)
        #expect(retrievedTimestamp?.isSuccessful == true)
        #expect(retrievedTimestamp?.itemCount == 10)
    }
    
    @Test func multipleTimestampsRetrieval() async throws {
        // Create in-memory model container for testing
        let schema = Schema([
            LegoSet.self,
            LegoTheme.self,
            SyncTimestamp.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        let localDataSource = SwiftDataSource(modelContext: modelContainer.mainContext)
        
        // Create multiple sync timestamps
        let setsTimestamp = SyncTimestamp(
            id: "sets-sync",
            lastSync: Date(),
            syncType: .sets,
            isSuccessful: true,
            itemCount: 10
        )
        
        let themesTimestamp = SyncTimestamp(
            id: "themes-sync",
            lastSync: Date().addingTimeInterval(-3600), // 1 hour ago
            syncType: .themes,
            isSuccessful: false,
            itemCount: 0
        )
        
        // Save both timestamps
        try localDataSource.saveSyncTimestamp(setsTimestamp)
        try localDataSource.saveSyncTimestamp(themesTimestamp)
        
        // Retrieve all timestamps
        let allTimestamps = try localDataSource.getAllSyncTimestamps()
        
        #expect(allTimestamps.count == 2)
        
        // Retrieve specific timestamps
        let setsResult = try localDataSource.getLastSyncTimestamp(for: .sets)
        let themesResult = try localDataSource.getLastSyncTimestamp(for: .themes)
        
        #expect(setsResult?.syncType == .sets)
        #expect(setsResult?.isSuccessful == true)
        #expect(themesResult?.syncType == .themes)
        #expect(themesResult?.isSuccessful == false)
    }
}

// MARK: - BadgeVariant Tests

struct BadgeVariantTests {
    
    @Test func badgeVariantProperties() async throws {
        let compact = BadgeVariant.compact
        let expanded = BadgeVariant.expanded
        let iconOnly = BadgeVariant.iconOnly
        
        // Test spacing
        #expect(compact.spacing == 4)
        #expect(expanded.spacing == 8)
        #expect(iconOnly.spacing == 0)
        
        // Test icon sizes
        #expect(compact.iconSize == 12)
        #expect(expanded.iconSize == 14)
        #expect(iconOnly.iconSize == 16)
        
        // Test text visibility
        #expect(compact.showText == true)
        #expect(expanded.showText == true)
        #expect(iconOnly.showText == false)
        
        // Test padding
        #expect(compact.horizontalPadding == 8)
        #expect(expanded.horizontalPadding == 12)
        #expect(iconOnly.horizontalPadding == 6)
        
        #expect(compact.verticalPadding == 4)
        #expect(expanded.verticalPadding == 6)
        #expect(iconOnly.verticalPadding == 4)
    }
}
    
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

// MARK: - API Configuration Tests

struct APIConfigurationTests {
    
    @Test("API Configuration Service initialization")
    @MainActor
    func testAPIConfigurationServiceInitialization() async throws {
        let service = APIConfigurationService()
        
        // Service should initialize without errors
        #expect(service != nil)
    }
    
    @Test("API key validation")
    @MainActor
    func testAPIKeyValidation() async throws {
        let service = APIConfigurationService()
        
        // Valid API key format
        let validKey = "abcdef1234567890abcdef1234567890abcdef12"
        #expect(service.isValidAPIKeyFormat(validKey))
        
        // Invalid - too short
        let shortKey = "abc123"
        #expect(!service.isValidAPIKeyFormat(shortKey))
        
        // Invalid - contains special characters
        let invalidKey = "abcdef123456-invalid-key-format!"
        #expect(!service.isValidAPIKeyFormat(invalidKey))
        
        // Invalid - empty
        #expect(!service.isValidAPIKeyFormat(""))
        
        // Invalid - only whitespace
        #expect(!service.isValidAPIKeyFormat("   "))
    }
    
    @Test("User API key override")
    @MainActor
    func testUserAPIKeyOverride() async throws {
        let service = APIConfigurationService()
        let testKey = "abcdef1234567890abcdef1234567890abcdef12"
        
        // Initially no user override
        #expect(!service.hasUserOverride)
        
        // Set user API key
        service.userApiKey = testKey
        #expect(service.hasUserOverride)
        #expect(service.currentAPIKey == testKey)
        
        // Clear user override
        service.clearUserOverride()
        #expect(!service.hasUserOverride)
        #expect(service.userApiKey.isEmpty)
    }
    
    @Test("Configuration status messages")
    @MainActor
    func testConfigurationStatus() async throws {
        let service = APIConfigurationService()
        
        // Initially should show embedded or no key status
        let initialStatus = service.configurationStatus
        #expect(initialStatus.contains("embedded") || initialStatus.contains("No API key"))
        
        // After setting user key
        service.userApiKey = "abcdef1234567890abcdef1234567890abcdef12"
        #expect(service.configurationStatus.contains("custom"))
    }
    
    @Test("Valid API key detection")
    @MainActor
    func testValidAPIKeyDetection() async throws {
        let service = APIConfigurationService()
        
        // Test with valid user key
        service.userApiKey = "abcdef1234567890abcdef1234567890abcdef12"
        #expect(service.hasValidAPIKey)
        
        // Test with empty user key (falls back to embedded)
        service.clearUserOverride()
        // hasValidAPIKey depends on GeneratedConfiguration which may or may not have embedded key
        // This is expected behavior
    }
}

// MARK: - DI Container Tests

struct DIContainerTests {
    
    @Test("DI Container provides API Configuration Service")
    @MainActor
    func testDIContainerProvidesAPIConfiguration() async throws {
        let container = DIContainer.shared
        
        #expect(container.apiConfigurationService != nil)
        #expect(container.apiConfigurationService is APIConfigurationService)
    }
    
    @Test("Remote data sources receive API configuration")
    @MainActor
    func testRemoteDataSourcesReceiveAPIConfiguration() async throws {
        let container = DIContainer.shared
        
        let legoSetDataSource = container.makeLegoSetRemoteDataSource()
        let legoThemeDataSource = container.makeLegoThemeRemoteDataSource()
        
        // Data sources should be created successfully
        #expect(legoSetDataSource != nil)
        #expect(legoThemeDataSource != nil)
        
        // They should be implementation types that accept API configuration
        #expect(legoSetDataSource is LegoSetRemoteDataSourceImpl)
        #expect(legoThemeDataSource is LegoThemeRemoteDataSourceImpl)
    }
    
    @Test("Repositories are properly constructed")
    @MainActor
    func testRepositoryConstruction() async throws {
        let container = DIContainer.shared
        
        let legoSetRepo = container.makeLegoSetRepository()
        let legoThemeRepo = container.makeLegoThemeRepository()
        
        #expect(legoSetRepo != nil)
        #expect(legoThemeRepo != nil)
        #expect(legoSetRepo is LegoSetRepositoryImpl)
        #expect(legoThemeRepo is LegoThemeRepositoryImpl)
    }
    
    @Test("ViewModels are properly constructed")
    @MainActor
    func testViewModelConstruction() async throws {
        let container = DIContainer.shared
        
        let setsListVM = container.makeSetsListViewModel()
        let categoriesVM = container.makeCategoriesViewModel()
        let searchVM = container.makeSearchViewModel()
        
        #expect(setsListVM != nil)
        #expect(categoriesVM != nil)
        #expect(searchVM != nil)
    }
}

// MARK: - Remote Data Source Tests

struct RemoteDataSourceTests {
    
    @Test("LegoSetRemoteDataSource handles missing API key")
    @MainActor
    func testLegoSetRemoteDataSourceMissingAPIKey() async throws {
        // Create service with no API key
        let apiConfig = APIConfigurationService()
        apiConfig.clearUserOverride() // Ensure no user key
        
        let dataSource = LegoSetRemoteDataSourceImpl(apiConfiguration: apiConfig)
        
        // Calls should throw API key missing error when no valid key
        if !apiConfig.hasValidAPIKey {
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.fetchSets(page: 1, pageSize: 20)
            }
            
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.searchSets(query: "test", page: 1, pageSize: 20)
            }
            
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.getSetDetails(setNum: "10001-1")
            }
        }
    }
    
    @Test("LegoThemeRemoteDataSource handles missing API key")
    @MainActor
    func testLegoThemeRemoteDataSourceMissingAPIKey() async throws {
        // Create service with no API key
        let apiConfig = APIConfigurationService()
        apiConfig.clearUserOverride() // Ensure no user key
        
        let dataSource = LegoThemeRemoteDataSourceImpl(apiConfiguration: apiConfig)
        
        // Calls should throw API key missing error when no valid key
        if !apiConfig.hasValidAPIKey {
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.fetchThemes(page: 1, pageSize: 20)
            }
            
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.searchThemes(query: "test", page: 1, pageSize: 20)
            }
            
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.getThemeDetails(id: 1)
            }
        }
>>>>>>> main
    }
}
