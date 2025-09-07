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
