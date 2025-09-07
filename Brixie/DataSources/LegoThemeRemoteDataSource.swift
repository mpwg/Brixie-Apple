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
    
    func fetchThemes(page: Int, pageSize: Int) async throws -> [LegoTheme] {
        guard GeneratedConfiguration.hasEmbeddedAPIKey else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            // Set API key globally
            RebrickableLegoAPIClientAPIConfiguration.shared.apiKey = GeneratedConfiguration.rebrickableAPIKey 
            
            let response = try await LegoAPI.legoThemesList(
                page: page,
                pageSize: pageSize,
                ordering: "name"
            )
            
            return response.results.map { apiTheme in
                LegoTheme(
                    id: apiTheme.id,
                    name: apiTheme.name,
                    parentId: apiTheme.parentId,
                    setCount: 0 // TODO: Get actual set count
                )
            }
        } catch {
            throw BrixieError.networkError(underlying: error)
        }
    }
    
    func searchThemes(query: String, page: Int, pageSize: Int) async throws -> [LegoTheme] {
        guard GeneratedConfiguration.hasEmbeddedAPIKey else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            // Set API key globally
            RebrickableLegoAPIClientAPIConfiguration.shared.apiKey = GeneratedConfiguration.rebrickableAPIKey 
            
            let response = try await LegoAPI.legoThemesList(
                page: page,
                pageSize: pageSize,
                ordering: "name"
            )
            
            return response.results.map { apiTheme in
                LegoTheme(
                    id: apiTheme.id,
                    name: apiTheme.name,
                    parentId: apiTheme.parentId,
                    setCount: 0 // TODO: Get actual set count
                )
            }
        } catch {
            throw BrixieError.networkError(underlying: error)
        }
    }
    
    func getThemeDetails(id: Int) async throws -> LegoTheme? {
        guard GeneratedConfiguration.hasEmbeddedAPIKey else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            // Set API key globally
            RebrickableLegoAPIClientAPIConfiguration.shared.apiKey = GeneratedConfiguration.rebrickableAPIKey 
            
            let apiTheme = try await LegoAPI.legoThemesRead(id: id)
            
            return LegoTheme(
                id: apiTheme.id,
                name: apiTheme.name,
                parentId: apiTheme.parentId,
                setCount: 0 // TODO: Get actual set count
            )
        } catch {
            throw BrixieError.networkError(underlying: error)
        }
    }
}
