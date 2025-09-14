//
//  ModelContainerFactory.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation
import SwiftData

/// Factory for creating ModelContainer instances with centralized schema definition
@MainActor
struct ModelContainerFactory {
    /// Centralized schema definition for all SwiftData models
    static let schema = Schema([
        LegoSet.self,
        LegoTheme.self,
        SyncTimestamp.self
    ])
    
    /// Creates a production ModelContainer with persistent storage
    static func createProductionContainer() throws -> ModelContainer {
        let modelConfiguration = ModelConfiguration(
            schema: schema, 
            isStoredInMemoryOnly: false
        )
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    /// Creates a preview ModelContainer with in-memory storage for SwiftUI previews
    static func createPreviewContainer() -> ModelContainer {
        do {
            let modelConfiguration = ModelConfiguration(
                schema: schema, 
                isStoredInMemoryOnly: true
            )
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create preview ModelContainer: \(error)")
        }
    }
}
