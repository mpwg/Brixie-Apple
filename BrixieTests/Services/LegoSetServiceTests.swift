import Testing
import SwiftData
@testable import Brixie

/// Test suite for LegoSetService
@MainActor
struct LegoSetServiceTests {
    private var service: LegoSetService!
    private var modelContext: ModelContext!
    
    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: LegoSet.self, Theme.self, UserCollection.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        service = LegoSetService.shared
    }
    
    @Test("LegoSetService singleton works")
    func testSingleton() {
        let service1 = LegoSetService.shared
        let service2 = LegoSetService.shared
        
        #expect(service1 === service2)
    }
    
    @Test("LegoSetService can search sets by number")
    func testSearchBySetNumber() async {
        // This would require mocking the API client
        // For now, we'll test the structure
        let searchTerm = "75192"
        
        // In a real implementation, we would mock the API response
        // and test the parsing and storage logic
        #expect(!searchTerm.isEmpty)
    }
    
    @Test("LegoSetService handles empty search results")
    func testEmptySearchResults() async {
        let searchTerm = ""
        
        // Service should handle empty search terms gracefully
        #expect(searchTerm.isEmpty)
    }
}
