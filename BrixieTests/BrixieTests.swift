//
//  BrixieTests.swift
//  BrixieTests
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Testing
@testable import Brixie

struct BrixieTests {
    
    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
}

// MARK: - PaginatedAsyncSequence Tests

@Suite("PaginatedAsyncSequence Tests")
struct PaginatedAsyncSequenceTests {
    
    @Test("Basic pagination iteration works correctly")
    func testBasicPagination() async throws {
        // Given: A mock data source with multiple pages
        let totalItems = 25
        let pageSize = 10
        
        let fetchPage: @Sendable (Int, Int) async throws -> [Int] = { page, pageSize in
            let startIndex = (page - 1) * pageSize
            let endIndex = min(startIndex + pageSize, totalItems)
            guard startIndex < totalItems else { return [] }
            return Array(startIndex..<endIndex)
        }
        
        // When: We iterate through the sequence
        let sequence = PaginatedAsyncSequence(pageSize: pageSize, fetchPage: fetchPage)
        var collectedItems: [Int] = []
        
        for try await item in sequence {
            collectedItems.append(item)
        }
        
        // Then: All items should be collected
        #expect(collectedItems.count == totalItems)
        #expect(collectedItems == Array(0..<totalItems))
    }
    
    @Test("Empty page handling works correctly")
    func testEmptyPageHandling() async throws {
        // Given: A data source that returns empty results
        let fetchPage: @Sendable (Int, Int) async throws -> [String] = { _, _ in
            return []
        }
        
        // When: We iterate through the sequence
        let sequence = PaginatedAsyncSequence(fetchPage: fetchPage)
        var collectedItems: [String] = []
        
        for try await item in sequence {
            collectedItems.append(item)
        }
        
        // Then: No items should be collected
        #expect(collectedItems.isEmpty)
    }
    
    @Test("Error propagation works correctly")
    func testErrorPropagation() async throws {
        // Given: A data source that throws an error
        struct TestError: Error {}
        
        let fetchPage: @Sendable (Int, Int) async throws -> [String] = { _, _ in
            throw TestError()
        }
        
        // When/Then: Iterating should propagate the error
        let sequence = PaginatedAsyncSequence(fetchPage: fetchPage)
        
        do {
            for try await _ in sequence {
                // Should not reach here
                #expect(Bool(false), "Expected error to be thrown")
            }
        } catch is TestError {
            // Expected - error was properly propagated
            #expect(Bool(true))
        } catch {
            #expect(Bool(false), "Unexpected error type: \(error)")
        }
    }
    
    @Test("Collect with limit works correctly")
    func testCollectWithLimit() async throws {
        // Given: A sequence with many items
        let fetchPage: @Sendable (Int, Int) async throws -> [Int] = { page, pageSize in
            let startIndex = (page - 1) * pageSize
            return Array(startIndex..<(startIndex + pageSize))
        }
        
        let sequence = PaginatedAsyncSequence(pageSize: 10, fetchPage: fetchPage)
        
        // When: We collect with a limit
        let limitedItems = try await sequence.collect(limit: 15)
        
        // Then: Only the limited number of items should be collected
        #expect(limitedItems.count == 15)
        #expect(limitedItems == Array(0..<15))
    }
    
    @Test("Collect by pages works correctly")
    func testCollectByPages() async throws {
        // Given: A sequence with multiple pages
        let pageSize = 5
        let totalItems = 12
        
        let fetchPage: @Sendable (Int, Int) async throws -> [Int] = { page, pageSize in
            let startIndex = (page - 1) * pageSize
            let endIndex = min(startIndex + pageSize, totalItems)
            guard startIndex < totalItems else { return [] }
            return Array(startIndex..<endIndex)
        }
        
        let sequence = PaginatedAsyncSequence(pageSize: pageSize, fetchPage: fetchPage)
        
        // When: We collect by pages
        var pages: [[Int]] = []
        for try await page in sequence.collectByPages() {
            pages.append(page)
        }
        
        // Then: Pages should be correctly structured
        #expect(pages.count == 3) // 12 items with page size 5 = 3 pages
        #expect(pages[0] == [0, 1, 2, 3, 4])
        #expect(pages[1] == [5, 6, 7, 8, 9])
        #expect(pages[2] == [10, 11]) // Partial last page
    }
    
    @Test("Custom start page works correctly")
    func testCustomStartPage() async throws {
        // Given: A sequence starting from page 2
        let startPage = 2
        let pageSize = 3
        
        let fetchPage: @Sendable (Int, Int) async throws -> [Int] = { page, pageSize in
            let startIndex = (page - 1) * pageSize
            return Array(startIndex..<(startIndex + pageSize))
        }
        
        let sequence = PaginatedAsyncSequence(
            pageSize: pageSize,
            startPage: startPage,
            fetchPage: fetchPage
        )
        
        // When: We collect a limited number of items
        let items = try await sequence.collect(limit: 6)
        
        // Then: Items should start from the correct page
        #expect(items == [3, 4, 5, 6, 7, 8]) // Page 2 starts at index 3
    }
    
    @Test("Single page sequence works correctly")
    func testSinglePageSequence() async throws {
        // Given: A sequence with only one partial page
        let fetchPage: @Sendable (Int, Int) async throws -> [String] = { page, _ in
            if page == 1 {
                return ["item1", "item2", "item3"]
            } else {
                return []
            }
        }
        
        let sequence = PaginatedAsyncSequence(pageSize: 10, fetchPage: fetchPage)
        
        // When: We collect all items
        let items = try await sequence.collect()
        
        // Then: All items from the single page should be collected
        #expect(items == ["item1", "item2", "item3"])
    }
}

// MARK: - Repository Integration Tests

@Suite("Repository AsyncSequence Integration Tests")
struct RepositoryAsyncSequenceIntegrationTests {
    
    @Test("LegoSetRepository allSets sequence works correctly")
    func testLegoSetRepositoryAllSetsSequence() async throws {
        // Given: A mock repository implementation
        let mockRepository = MockLegoSetRepository()
        
        // When: We use the allSets sequence
        let sequence = mockRepository.allSets(pageSize: 5)
        let sets = try await sequence.collect(limit: 10)
        
        // Then: Sets should be returned correctly
        #expect(sets.count == 10)
        #expect(sets.allSatisfy { $0.name.hasPrefix("Set") })
    }
    
    @Test("LegoSetRepository searchSets sequence works correctly")
    func testLegoSetRepositorySearchSetsSequence() async throws {
        // Given: A mock repository implementation
        let mockRepository = MockLegoSetRepository()
        
        // When: We use the searchSets sequence
        let sequence = mockRepository.searchSets(query: "test", pageSize: 3)
        let sets = try await sequence.collect(limit: 6)
        
        // Then: Search results should be returned correctly
        #expect(sets.count == 6)
        #expect(sets.allSatisfy { $0.name.contains("test") })
    }
}

// MARK: - Mock Implementations

private class MockLegoSetRepository: LegoSetRepository {
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        let startIndex = (page - 1) * pageSize
        return (startIndex..<(startIndex + pageSize)).map { index in
            LegoSet(
                setNum: "\(index)",
                name: "Set \(index)",
                year: 2020 + (index % 10),
                themeId: 1,
                numParts: 100 + index
            )
        }
    }
    
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
        let startIndex = (page - 1) * pageSize
        return (startIndex..<(startIndex + pageSize)).map { index in
            LegoSet(
                setNum: "\(index)",
                name: "Set \(query) \(index)",
                year: 2020 + (index % 10),
                themeId: 1,
                numParts: 100 + index
            )
        }
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        return LegoSet(setNum: setNum, name: "Detailed Set", year: 2023, themeId: 1, numParts: 500)
    }
    
    func getCachedSets() async -> [LegoSet] {
        return []
    }
    
    func markAsFavorite(_ set: LegoSet) async throws {
        set.isFavorite = true
    }
    
    func removeFromFavorites(_ set: LegoSet) async throws {
        set.isFavorite = false
    }
    
    func getFavoriteSets() async -> [LegoSet] {
        return []
    }
    
    func allSets(pageSize: Int) -> PaginatedAsyncSequence<LegoSet> {
        PaginatedAsyncSequence(pageSize: pageSize) { [weak self] page, pageSize in
            guard let self = self else { throw BrixieError.dataNotFound }
            return try await self.fetchSets(page: page, pageSize: pageSize)
        }
    }
    
    func searchSets(query: String, pageSize: Int) -> PaginatedAsyncSequence<LegoSet> {
        PaginatedAsyncSequence(pageSize: pageSize) { [weak self] page, pageSize in
            guard let self = self else { throw BrixieError.dataNotFound }
            return try await self.searchSets(query: query, page: page, pageSize: pageSize)
        }
    }
}
