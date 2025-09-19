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
        // Using SwiftData MigrationPlan. Explicit logic can be added for
        // custom transformations when introducing new schema versions.
    }
}