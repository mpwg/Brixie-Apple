//
//  DIContainer.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class DIContainer: @unchecked Sendable {
    static let shared = DIContainer()

    let modelContainer: ModelContainer

    init(modelContainer: ModelContainer? = nil) {
        if let modelContainer = modelContainer {
            self.modelContainer = modelContainer
        } else {
            do {
                self.modelContainer = try ModelContainerFactory.createProductionContainer()
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    // MARK: Managers

    var themeManager: ThemeManager = ThemeManager.shared
    var networkMonitorService: NetworkMonitorService = NetworkMonitorService.shared

    // MARK: Services

    var imageCacheService = ImageCacheService.shared
    var apiConfigurationService = APIConfigurationService()

    // MARK: Data Sources

    func makeLocalDataSource() -> LocalDataSource {
        SwiftDataSource(modelContext: modelContainer.mainContext)
    }

    func makeLegoSetRemoteDataSource() -> LegoSetRemoteDataSource {
        LegoSetRemoteDataSourceImpl(apiConfiguration: apiConfigurationService)
    }

    func makeLegoThemeRemoteDataSource() -> LegoThemeRemoteDataSource {
        LegoThemeRemoteDataSourceImpl(apiConfiguration: apiConfigurationService)
    }

    // MARK: Repositories

    func makeLegoSetRepository() -> LegoSetRepository {
        LegoSetRepositoryImpl(
            remoteDataSource: makeLegoSetRemoteDataSource(),
            localDataSource: makeLocalDataSource(),
            themeRepository: makeLegoThemeRepository()
        )
    }

    func makeLegoThemeRepository() -> LegoThemeRepository {
        LegoThemeRepositoryImpl(
            remoteDataSource: makeLegoThemeRemoteDataSource(),
            localDataSource: makeLocalDataSource()
        )
    }
}

// MARK: Environment Key

struct DIContainerKey: EnvironmentKey {
    // Provide a lazily-evaluated container; EnvironmentKey requires nonisolated static.
    // We capture the MainActor instance indirectly to avoid isolation diagnostics.
    static let defaultValue: DIContainer = {
        // Access on MainActor explicitly.
        MainActor.assumeIsolated { DIContainer.shared }
    }()
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
