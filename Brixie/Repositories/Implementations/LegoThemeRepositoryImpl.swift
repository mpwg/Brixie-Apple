//
//  LegoThemeRepositoryImpl.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@MainActor
final class LegoThemeRepositoryImpl: LegoThemeRepository {
    private let remoteDataSource: LegoThemeRemoteDataSource
    private let localDataSource: LocalDataSource
    
    init(remoteDataSource: LegoThemeRemoteDataSource, localDataSource: LocalDataSource) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }
    
    func fetchThemes(page: Int, pageSize: Int) async throws -> [LegoTheme] {
        do {
            let remoteThemes = try await remoteDataSource.fetchThemes(page: page, pageSize: pageSize)
            
            if page == 1 {
                try localDataSource.deleteAll(LegoTheme.self)
            }
            
            try localDataSource.save(remoteThemes)
            
            // Save successful sync timestamp
            let syncTimestamp = SyncTimestamp(
                id: "themes-sync",
                lastSync: Date(),
                syncType: .themes,
                isSuccessful: true,
                itemCount: remoteThemes.count
            )
            try localDataSource.saveSyncTimestamp(syncTimestamp)
            
            return remoteThemes
        } catch {
            // Save failed sync timestamp
            let syncTimestamp = SyncTimestamp(
                id: "themes-sync",
                lastSync: Date(),
                syncType: .themes,
                isSuccessful: false,
                itemCount: 0
            )
            try? localDataSource.saveSyncTimestamp(syncTimestamp)
            
            if case BrixieError.networkError = error {
                let cachedThemes = await getCachedThemes()
                if !cachedThemes.isEmpty {
                    return cachedThemes
                }
            }
            throw error
        }
    }
    
    func searchThemes(query: String, page: Int, pageSize: Int) async throws -> [LegoTheme] {
        do {
            return try await remoteDataSource.searchThemes(query: query, page: page, pageSize: pageSize)
        } catch {
            let cachedThemes = await getCachedThemes()
            return cachedThemes.filter { theme in
                theme.name.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    func getThemeDetails(id: Int) async throws -> LegoTheme? {
        do {
            if let remoteTheme = try await remoteDataSource.getThemeDetails(id: id) {
                try localDataSource.save([remoteTheme])
                return remoteTheme
            }
            return nil
        } catch {
            let cachedThemes = await getCachedThemes()
            return cachedThemes.first { $0.id == id }
        }
    }
    
    func getCachedThemes() async -> [LegoTheme] {
        do {
            return try localDataSource.fetch(LegoTheme.self)
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
}
