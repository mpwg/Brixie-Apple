import Testing
import SwiftData
@testable import Brixie

/// Test suite for Theme model
@MainActor
struct ThemeTests {
    
    private func createModelContext() -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Theme.self, configurations: config)
        return ModelContext(container)
    }
    
    @Test("Theme can be created with required properties")
    func testThemeCreation() {
        let theme = Theme(
            id: 158,
            parentID: 157,
            name: "Star Wars",
            sortOrder: 1
        )
        
        #expect(theme.id == 158)
        #expect(theme.parentID == 157)
        #expect(theme.name == "Star Wars")
        #expect(theme.sortOrder == 1)
    }
    
    @Test("Theme hierarchy relationships work")
    func testThemeHierarchy() {
        let context = createModelContext()
        
        let parentTheme = Theme(id: 1, parentID: nil, name: "Licensed", sortOrder: 1)
        let childTheme = Theme(id: 158, parentID: 1, name: "Star Wars", sortOrder: 1)
        
        context.insert(parentTheme)
        context.insert(childTheme)
        
        do {
            try context.save()
            
            #expect(childTheme.parentID == parentTheme.id)
            #expect(parentTheme.parentID == nil)
        } catch {
            Issue.record("Failed to save theme hierarchy: \(error)")
        }
    }
    
    @Test("Theme example data is valid")
    func testThemeExample() {
        let example = Theme.example
        
        #expect(example.id > 0)
        #expect(!example.name.isEmpty)
        #expect(example.sortOrder >= 0)
    }
}