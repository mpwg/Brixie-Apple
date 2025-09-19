import Testing
import SwiftData
@testable import Brixie

/// Test suite for OfflineManager
@MainActor 
struct OfflineManagerTests {
    
    private var offlineManager: OfflineManager!
    
    init() {
        offlineManager = OfflineManager.shared
    }
    
    @Test("OfflineManager singleton works")
    func testSingleton() {
        let manager1 = OfflineManager.shared
        let manager2 = OfflineManager.shared
        
        #expect(manager1 === manager2)
    }
    
    @Test("OfflineManager can queue actions")
    func testQueueAction() {
        let initialCount = offlineManager.queuedActions.count
        
        let action = QueuedAction(
            type: .addToCollection,
            data: ["setNumber": "75192", "name": "Millennium Falcon"]
        )
        
        offlineManager.queueAction(action)
        
        #expect(offlineManager.queuedActions.count == initialCount + 1)
    }
    
    @Test("OfflineManager can remove queued actions")
    func testRemoveQueuedAction() {
        let action = QueuedAction(
            type: .addToWishlist,
            data: ["setNumber": "75193"]
        )
        
        offlineManager.queueAction(action)
        let countAfterAdd = offlineManager.queuedActions.count
        
        offlineManager.removeQueuedAction(action)
        let countAfterRemove = offlineManager.queuedActions.count
        
        #expect(countAfterRemove == countAfterAdd - 1)
    }
    
    @Test("OfflineManager can clear all queued actions")
    func testClearAllQueuedActions() {
        let action1 = QueuedAction(type: .addToCollection, data: ["setNumber": "001"])
        let action2 = QueuedAction(type: .addToWishlist, data: ["setNumber": "002"])
        
        offlineManager.queueAction(action1)
        offlineManager.queueAction(action2)
        
        #expect(!offlineManager.queuedActions.isEmpty)
        
        offlineManager.clearAllQueuedActions()
        
        #expect(offlineManager.queuedActions.isEmpty)
    }
    
    @Test("QueuedAction has correct properties")
    func testQueuedActionProperties() {
        let data = ["setNumber": "75192", "name": "Millennium Falcon"]
        let action = QueuedAction(type: .addToCollection, data: data)
        
        #expect(action.type == .addToCollection)
        #expect(action.data["setNumber"] == "75192")
        #expect(action.data["name"] == "Millennium Falcon")
        #expect(action.timestamp != nil)
        #expect(!action.id.uuidString.isEmpty)
    }
}