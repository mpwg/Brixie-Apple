//
//  BrixieApp.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import SwiftData

@main
struct BrixieApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            LegoSet.self,
            Theme.self,
            UserCollection.self
        ], isUndoEnabled: true)
    }
}

// MARK: - Model Container Configuration

extension BrixieApp {
    /// Creates and configures the SwiftData model container
    static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            LegoSet.self,
            Theme.self,
            UserCollection.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}

// MARK: - Migration Support

extension BrixieApp {
    /// Handles data migration between app versions
    static func performMigrationIfNeeded() {
        // Migration logic will be implemented when needed
        // This placeholder ensures we have a place to handle
        // future schema changes
    }
}