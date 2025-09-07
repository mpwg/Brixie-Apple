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

struct LocalDataSourceTests {
    
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
