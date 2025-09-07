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
    
    nonisolated init(modelContainer: ModelContainer? = nil) {
        if let modelContainer = modelContainer {
            self.modelContainer = modelContainer
        } else {
            do {
                let schema = Schema([
                    LegoSet.self,
                    LegoTheme.self
                ])
                let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }
    
    // MARK: - Managers
    
    var apiKeyManager: APIKeyManager = APIKeyManager.shared
    var themeManager: ThemeManager = ThemeManager.shared
    
    // MARK: - Services
    
    var imageCacheService: ImageCacheService = ImageCacheService.shared
    
    // MARK: - Data Sources
    
    func makeLocalDataSource() -> LocalDataSource {
        SwiftDataSource(modelContext: modelContainer.mainContext)
    }
    
    func makeLegoSetRemoteDataSource() -> LegoSetRemoteDataSource {
        LegoSetRemoteDataSourceImpl(apiKeyManager: apiKeyManager)
    }
    
    func makeLegoThemeRemoteDataSource() -> LegoThemeRemoteDataSource {
        LegoThemeRemoteDataSourceImpl(apiKeyManager: apiKeyManager)
    }
    
    // MARK: - Repositories
    
    func makeLegoSetRepository() -> LegoSetRepository {
        LegoSetRepositoryImpl(
            remoteDataSource: makeLegoSetRemoteDataSource(),
            localDataSource: makeLocalDataSource()
        )
    }
    
    func makeLegoThemeRepository() -> LegoThemeRepository {
        LegoThemeRepositoryImpl(
            remoteDataSource: makeLegoThemeRemoteDataSource(),
            localDataSource: makeLocalDataSource()
        )
    }
    
    // MARK: - ViewModels
    
    func makeSetsListViewModel() -> SetsListViewModel {
        SetsListViewModel(
            legoSetRepository: makeLegoSetRepository(),
            apiKeyManager: apiKeyManager
        )
    }
    
    func makeCategoriesViewModel() -> CategoriesViewModel {
        CategoriesViewModel(
            legoThemeRepository: makeLegoThemeRepository(),
            apiKeyManager: apiKeyManager
        )
    }
    
    func makeSetDetailViewModel(set: LegoSet) -> SetDetailViewModel {
        SetDetailViewModel(
            set: set,
            legoSetRepository: makeLegoSetRepository()
        )
    }
    
    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            legoSetRepository: makeLegoSetRepository(),
            legoThemeRepository: makeLegoThemeRepository(),
            apiKeyManager: apiKeyManager
        )
    }
}

// MARK: - Environment Key

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