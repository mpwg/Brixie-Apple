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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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
            localDataSource: mockLocal
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

struct BrixieTests {
    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
}
