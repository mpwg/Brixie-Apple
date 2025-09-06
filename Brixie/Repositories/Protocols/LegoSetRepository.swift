//
//  LegoSetRepository.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@MainActor
protocol LegoSetRepository {
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet]
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet]
    func getSetDetails(setNum: String) async throws -> LegoSet?
    func getCachedSets() async -> [LegoSet]
    func markAsFavorite(_ set: LegoSet) async throws
    func removeFromFavorites(_ set: LegoSet) async throws
    func getFavoriteSets() async -> [LegoSet]
}