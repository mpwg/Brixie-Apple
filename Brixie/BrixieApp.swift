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
    // Configure SwiftData for our models; migration plan scaffolding exists for future changes.
    .modelContainer(for: [LegoSet.self, Theme.self, UserCollection.self], isUndoEnabled: true)
    }
}

// MARK: - Model Container Configuration

extension BrixieApp {
    /// Creates and configures the SwiftData model container
    static func createModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: LegoSet.self, Theme.self, UserCollection.self)
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