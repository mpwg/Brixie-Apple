import Testing
import SwiftData
@testable import Brixie

/// Test suite for SearchHistoryService
@MainActor
struct SearchHistoryServiceTests {
    
    private var service: SearchHistoryService!
    
    init() {
        service = SearchHistoryService.shared
        // Clear any existing history for clean tests
        service.clearHistory()
    }
    
    @Test("SearchHistoryService singleton works")
    func testSingleton() {
        let service1 = SearchHistoryService.shared
        let service2 = SearchHistoryService.shared
        
        #expect(service1 === service2)
    }
    
    @Test("SearchHistoryService can add search terms")
    func testAddSearchTerm() {
        let searchTerm = "Millennium Falcon"
        
        service.addSearchTerm(searchTerm)
        
        let recentSearches = service.recentSearches
        #expect(recentSearches.contains(searchTerm))
    }
    
    @Test("SearchHistoryService limits recent searches")
    func testRecentSearchesLimit() {
        // Add more than the maximum number of searches
        for i in 1...15 {
            service.addSearchTerm("Search Term \(i)")
        }
        
        let recentSearches = service.recentSearches
        #expect(recentSearches.count <= 10) // Assuming max limit is 10
    }
    
    @Test("SearchHistoryService provides suggestions")
    func testGetSuggestions() {
        service.addSearchTerm("Star Wars")
        service.addSearchTerm("Star Trek")
        service.addSearchTerm("Starcraft")
        
        let suggestions = service.getSuggestions(for: "Star")
        
        #expect(suggestions.count == 3)
        #expect(suggestions.contains("Star Wars"))
        #expect(suggestions.contains("Star Trek"))
        #expect(suggestions.contains("Starcraft"))
    }
    
    @Test("SearchHistoryService case-insensitive suggestions")
    func testCaseInsensitiveSuggestions() {
        service.addSearchTerm("LEGO Technic")
        
        let suggestions = service.getSuggestions(for: "lego")
        
        #expect(suggestions.contains("LEGO Technic"))
    }
    
    @Test("SearchHistoryService can clear history")
    func testClearHistory() {
        service.addSearchTerm("Test Search")
        service.clearHistory()
        
        let recentSearches = service.recentSearches
        #expect(recentSearches.isEmpty)
    }
}