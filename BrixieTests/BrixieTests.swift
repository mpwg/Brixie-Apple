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

// MARK: - Localization Tests

struct LocalizationTests {
    
    @Test("Strings enum provides non-empty localized values")
    func stringsEnumProvidesLocalizedValues() async throws {
        // Test basic strings
        #expect(!Strings.categories.localized.isEmpty)
        #expect(!Strings.sets.localized.isEmpty)
        #expect(!Strings.search.localized.isEmpty)
        #expect(!Strings.favorites.localized.isEmpty)
        #expect(!Strings.settings.localized.isEmpty)
        
        // Test the text alias works
        #expect(Strings.categories.text == Strings.categories.localized)
    }
    
    @Test("Formatted strings work correctly")
    func formattedStringsWorkCorrectly() async throws {
        // Test piece count formatting
        let piecesString = Strings.piecesCount(42).localized
        #expect(piecesString.contains("42"))
        
        // Test set number formatting
        let setNumber = Strings.setNumber("10234").localized
        #expect(setNumber.contains("10234"))
        
        // Test search results formatting
        let noResults = Strings.noSetsFoundFormat("castle").localized
        #expect(noResults.contains("castle"))
    }
    
    @Test("Error strings include proper formatting")
    func errorStringsIncludeProperFormatting() async throws {
        // Test network error
        let networkError = Strings.networkError("Connection timeout").localized
        #expect(networkError.contains("Connection timeout"))
        
        // Test server error
        let serverError = Strings.serverError(404).localized
        #expect(serverError.contains("404"))
        
        // Test cache error
        let cacheError = Strings.cacheError("Disk full").localized
        #expect(cacheError.contains("Disk full"))
    }
    
    @Test("String interpolation works with Strings enum")
    func stringInterpolationWorks() async throws {
        let message = "Welcome to \(Strings.settings)"
        #expect(message.contains(Strings.settings.localized))
    }
    
    @Test("All localized strings are non-empty")
    func allLocalizedStringsAreNonEmpty() async throws {
        // Test a representative sample of all string types
        let testCases: [Strings] = [
            .categories, .sets, .search, .favorites, .settings,
            .done, .reset, .configure, .loadMore,
            .searchSets, .recentSearches, .all, .themes,
            .setInformation, .statistics, .shareImage,
            .sortBy, .nameAscending, .yearNewest,
            .initializing, .loadingSets,
            .light, .dark, .system,
            .apiConfiguration, .enterApiKey, .notConfigured,
            .apiKeyMissing, .parsingError, .dataNotFound,
            .checkConnection, .tryAgainLater,
            .noSetsFound, .noFavoritesYet
        ]
        
        for stringCase in testCases {
            #expect(!stringCase.localized.isEmpty, "String case \(stringCase) should not be empty")
        }
    }
}
