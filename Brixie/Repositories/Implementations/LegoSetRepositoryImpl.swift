//
//  LegoSetRepositoryImpl.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@MainActor
final class LegoSetRepositoryImpl: LegoSetRepository {
    private let remoteDataSource: LegoSetRemoteDataSource
    private let localDataSource: LocalDataSource
    private let themeRepository: LegoThemeRepository

    init(
        remoteDataSource: LegoSetRemoteDataSource,
        localDataSource: LocalDataSource,
        themeRepository: LegoThemeRepository
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.themeRepository = themeRepository
    }
    
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        do {
            let remoteSets = try await remoteDataSource.fetchSets(page: page, pageSize: pageSize)
            let setsWithThemeNames = await populateThemeNames(for: remoteSets)
            
            if page == 1 {
                try localDataSource.deleteAll(LegoSet.self)
            }
            
            try localDataSource.save(setsWithThemeNames)
            
            // Save successful sync timestamp
            let syncTimestamp = SyncTimestamp(
                id: "sets-sync",
                lastSync: Date(),
                syncType: .sets,
                isSuccessful: true,
                itemCount: setsWithThemeNames.count
            )
            try localDataSource.saveSyncTimestamp(syncTimestamp)
            
            return setsWithThemeNames
        } catch {
            // Save failed sync timestamp
            let syncTimestamp = SyncTimestamp(
                id: "sets-sync",
                lastSync: Date(),
                syncType: .sets,
                isSuccessful: false,
                itemCount: 0
            )
            try? localDataSource.saveSyncTimestamp(syncTimestamp)
            
            if case BrixieError.networkError = error {
                let cachedSets = await getCachedSets()
                if !cachedSets.isEmpty {
                    return cachedSets
                }
            }
            throw error
        }
    }
    
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
        do {
            let remoteSets = try await remoteDataSource.searchSets(query: query, page: page, pageSize: pageSize)
            let setsWithThemeNames = await populateThemeNames(for: remoteSets)
            
            // Save successful search sync timestamp
            let syncTimestamp = SyncTimestamp(
                id: "search-sync",
                lastSync: Date(),
                syncType: .search,
                isSuccessful: true,
                itemCount: setsWithThemeNames.count
            )
            try? localDataSource.saveSyncTimestamp(syncTimestamp)
            
            return setsWithThemeNames
        } catch {
            // Save failed search sync timestamp
            let syncTimestamp = SyncTimestamp(
                id: "search-sync",
                lastSync: Date(),
                syncType: .search,
                isSuccessful: false,
                itemCount: 0
            )
            try? localDataSource.saveSyncTimestamp(syncTimestamp)
            
            let cachedSets = await getCachedSets()
            return cachedSets.filter { set in
                set.name.localizedCaseInsensitiveContains(query) ||
                set.setNum.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        do {
            if let remoteSet = try await remoteDataSource.getSetDetails(setNum: setNum) {
                let setsWithThemeNames = await populateThemeNames(for: [remoteSet])
                let setWithThemeName = setsWithThemeNames.first
                if let setWithThemeName = setWithThemeName {
                    try localDataSource.save([setWithThemeName])
                }
                
                // Save successful set details sync timestamp
                let syncTimestamp = SyncTimestamp(
                    id: "setDetails-sync",
                    lastSync: Date(),
                    syncType: .setDetails,
                    isSuccessful: true,
                    itemCount: 1
                )
                try? localDataSource.saveSyncTimestamp(syncTimestamp)
                
                return setWithThemeName
            }
            return nil
        } catch {
            // Save failed set details sync timestamp
            let syncTimestamp = SyncTimestamp(
                id: "setDetails-sync",
                lastSync: Date(),
                syncType: .setDetails,
                isSuccessful: false,
                itemCount: 0
            )
            try? localDataSource.saveSyncTimestamp(syncTimestamp)
            
            let cachedSets = await getCachedSets()
            return cachedSets.first { $0.setNum == setNum }
        }
    }
    
    func getCachedSets() async -> [LegoSet] {
        do {
            return try localDataSource.fetch(LegoSet.self)
        } catch {
            return []
        }
    }
    
    func markAsFavorite(_ set: LegoSet) async throws {
        set.isFavorite = true
        try localDataSource.save([set])
    }
    
    func removeFromFavorites(_ set: LegoSet) async throws {
        set.isFavorite = false
        try localDataSource.save([set])
    }
    
    func getFavoriteSets() async -> [LegoSet] {
        do {
            return try localDataSource.fetch(
                LegoSet.self,
                predicate: #Predicate<LegoSet> { $0.isFavorite }
            )
        } catch {
            return []
        }
    }
    
    func getLastSyncTimestamp(for syncType: SyncType) async -> SyncTimestamp? {
        do {
            return try localDataSource.getLastSyncTimestamp(for: syncType)
        } catch {
            return nil
        }
    }
    
    // MARK: - Theme Name Population    
    /// Populate theme names for sets using cached themes
    private func populateThemeNames(for sets: [LegoSet]) async -> [LegoSet] {
        let cachedThemes = await themeRepository.getCachedThemes()
        let themeNameMap = Dictionary(uniqueKeysWithValues: cachedThemes.map { ($0.id, $0.name) })
        
        return sets.map { set in
            let themeName = themeNameMap[set.themeId]
            return LegoSet(
                setNum: set.setNum,
                name: set.name,
                year: set.year,
                themeId: set.themeId,
                numParts: set.numParts,
                imageURL: set.imageURL,
                themeName: themeName
            )
        }
    }
    
    /// Backfill existing sets with theme names
    func backfillThemeNames() async throws {
        let cachedSets = await getCachedSets()
        let setsNeedingThemeNames = cachedSets.filter { $0.themeName == nil }
        
        if setsNeedingThemeNames.isEmpty {
            return
        }
        
        let setsWithThemeNames = await populateThemeNames(for: setsNeedingThemeNames)
        
        // Update existing sets with theme names
        for (index, set) in setsNeedingThemeNames.enumerated() where index < setsWithThemeNames.count {
            set.themeName = setsWithThemeNames[index].themeName
        }
        
        try localDataSource.save(setsNeedingThemeNames)
    }
}
