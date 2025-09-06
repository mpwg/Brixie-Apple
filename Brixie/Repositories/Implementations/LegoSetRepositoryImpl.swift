//
//  LegoSetRepositoryImpl.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

final class LegoSetRepositoryImpl: LegoSetRepository {
    private let remoteDataSource: LegoSetRemoteDataSource
    private let localDataSource: LocalDataSource
    
    init(remoteDataSource: LegoSetRemoteDataSource, localDataSource: LocalDataSource) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }
    
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        do {
            let remoteSets = try await remoteDataSource.fetchSets(page: page, pageSize: pageSize)
            
            if page == 1 {
                try await localDataSource.deleteAll(LegoSet.self)
            }
            
            try await localDataSource.save(remoteSets)
            return remoteSets
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
            return try await remoteDataSource.searchSets(query: query, page: page, pageSize: pageSize)
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
                try await localDataSource.save([remoteSet])
                return remoteSet
            }
            return nil
        } catch {
            let cachedSets = await getCachedSets()
            return cachedSets.first { $0.setNum == setNum }
        }
    }
    
    func getCachedSets() async -> [LegoSet] {
        do {
            return try await localDataSource.fetch(LegoSet.self)
        } catch {
            return []
        }
    }
    
    func markAsFavorite(_ set: LegoSet) async throws {
        var updatedSet = set
        updatedSet.isFavorite = true
        try await localDataSource.save([updatedSet])
    }
    
    func removeFromFavorites(_ set: LegoSet) async throws {
        var updatedSet = set
        updatedSet.isFavorite = false
        try await localDataSource.save([updatedSet])
    }
    
    func getFavoriteSets() async -> [LegoSet] {
        do {
            return try await localDataSource.fetch(
                LegoSet.self,
                predicate: #Predicate<LegoSet> { $0.isFavorite }
            )
        } catch {
            return []
        }
    }
}