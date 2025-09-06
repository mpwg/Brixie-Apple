//
//  LegoThemeRemoteDataSource.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation
import RebrickableLegoAPIClient

protocol LegoThemeRemoteDataSource: Sendable {
    func fetchThemes(page: Int, pageSize: Int) async throws -> [LegoTheme]
    func searchThemes(query: String, page: Int, pageSize: Int) async throws -> [LegoTheme]
    func getThemeDetails(id: Int) async throws -> LegoTheme?
}

final class LegoThemeRemoteDataSourceImpl: LegoThemeRemoteDataSource {
    private let apiKeyManager: APIKeyManager
    private let apiClient: ThemesAPI
    
    init(apiKeyManager: APIKeyManager) {
        self.apiKeyManager = apiKeyManager
        self.apiClient = ThemesAPI()
    }
    
    func fetchThemes(page: Int, pageSize: Int) async throws -> [LegoTheme] {
        guard !apiKeyManager.apiKey.isEmpty else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            let result = try await apiClient.themesList(
                key: apiKeyManager.apiKey,
                page: page,
                pageSize: pageSize,
                ordering: "name"
            )
            
            return result.results?.compactMap { apiTheme in
                LegoTheme(
                    id: apiTheme.id ?? 0,
                    name: apiTheme.name ?? "",
                    parentId: apiTheme.parentID
                )
            } ?? []
        } catch {
            throw BrixieError.networkError(underlying: error)
        }
    }
    
    func searchThemes(query: String, page: Int, pageSize: Int) async throws -> [LegoTheme] {
        guard !apiKeyManager.apiKey.isEmpty else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            let result = try await apiClient.themesList(
                key: apiKeyManager.apiKey,
                page: page,
                pageSize: pageSize,
                search: query,
                ordering: "name"
            )
            
            return result.results?.compactMap { apiTheme in
                LegoTheme(
                    id: apiTheme.id ?? 0,
                    name: apiTheme.name ?? "",
                    parentId: apiTheme.parentID
                )
            } ?? []
        } catch {
            throw BrixieError.networkError(underlying: error)
        }
    }
    
    func getThemeDetails(id: Int) async throws -> LegoTheme? {
        guard !apiKeyManager.apiKey.isEmpty else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            let apiTheme = try await apiClient.themesRead(
                id: id,
                key: apiKeyManager.apiKey
            )
            
            return LegoTheme(
                id: apiTheme.id ?? 0,
                name: apiTheme.name ?? "",
                parentId: apiTheme.parentID
            )
        } catch {
            throw BrixieError.networkError(underlying: error)
        }
    }
}