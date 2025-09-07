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

    init(remoteDataSource: LegoSetRemoteDataSource, localDataSource: LocalDataSource, themeRepository: LegoThemeRepository) {
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
            return setsWithThemeNames
        } catch {
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
            return await populateThemeNames(for: remoteSets)
        } catch {
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
                return setWithThemeName
            }
            return nil
        } catch {
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
        for (index, set) in setsNeedingThemeNames.enumerated() {
            if index < setsWithThemeNames.count {
                set.themeName = setsWithThemeNames[index].themeName
            }
        }
        
        try localDataSource.save(setsNeedingThemeNames)
    }
}
