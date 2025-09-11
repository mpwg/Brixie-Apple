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
    
    // MARK: - AsyncSequence Methods
    
    /// Returns an async sequence of all themes with automatic pagination
    func allThemes(pageSize: Int) -> PaginatedAsyncSequence<LegoTheme>
    
    /// Returns an async sequence of search results with automatic pagination
    func searchThemes(query: String, pageSize: Int) -> PaginatedAsyncSequence<LegoTheme>
}
