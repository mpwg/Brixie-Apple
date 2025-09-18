//
//  BrixieMigrationPlan.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import Foundation
import SwiftData

/// SwiftData migration plan for Brixie app schemas
enum BrixieMigrationPlan: SchemaMigrationPlan {
    // Initial set of versioned schemas supported by the app
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    // No migration stages are required for the initial schema version.
    // Future schema updates should append `.lightweight(from:to:)` or `.custom(...)` stages here.
    static var stages: [MigrationStage] { [] }
}

// MARK: - Schema V1

enum SchemaV1: VersionedSchema {
    // Semantic version for the initial schema
    static var versionIdentifier: Schema.Version { .init(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            LegoSet.self,
            Theme.self,
            UserCollection.self
        ]
    }
}
