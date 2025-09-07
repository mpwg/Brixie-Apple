//
//  LegoThemeRepository.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@MainActor
protocol LegoThemeRepository {
    func fetchThemes(page: Int, pageSize: Int) async throws -> [LegoTheme]
    func searchThemes(query: String, page: Int, pageSize: Int) async throws -> [LegoTheme]
    func getThemeDetails(id: Int) async throws -> LegoTheme?
    func getCachedThemes() async -> [LegoTheme]
    func getLastSyncTimestamp(for syncType: SyncType) async -> SyncTimestamp?
}