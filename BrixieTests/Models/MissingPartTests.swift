import Testing
import SwiftData
@testable import Brixie

/// Test suite for MissingPart model
@MainActor
struct MissingPartTests {
    private func createModelContext() -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: MissingPart.self, configurations: config)
        return ModelContext(container)
    }
    
    @Test("MissingPart can be created with required properties")
    func testMissingPartCreation() {
        let part = MissingPart(
            setNumber: "75192",
            partNumber: "3001",
            partName: "Brick 2x4",
            colorName: "Bright Red",
            quantity: 5,
            isFound: false,
            notes: "Lost during build"
        )
        
        #expect(part.setNumber == "75192")
        #expect(part.partNumber == "3001")
        #expect(part.partName == "Brick 2x4")
        #expect(part.colorName == "Bright Red")
        #expect(part.quantity == 5)
        #expect(part.isFound == false)
        #expect(part.notes == "Lost during build")
    }
    
    @Test("MissingPart defaults work correctly")
    func testMissingPartDefaults() {
        let part = MissingPart(setNumber: "12345", partNumber: "3001")
        
        #expect(part.quantity == 1)
        #expect(part.isFound == false)
        #expect(part.dateAdded != nil)
    }
}
