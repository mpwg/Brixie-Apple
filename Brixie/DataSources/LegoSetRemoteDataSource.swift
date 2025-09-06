//
//  LegoSetRemoteDataSource.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation
import RebrickableLegoAPIClient

protocol LegoSetRemoteDataSource: Sendable {
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet]
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet]
    func getSetDetails(setNum: String) async throws -> LegoSet?
}

final class LegoSetRemoteDataSourceImpl: LegoSetRemoteDataSource {
    private let apiKeyManager: APIKeyManager
    private let apiClient: SetsAPI
    
    init(apiKeyManager: APIKeyManager) {
        self.apiKeyManager = apiKeyManager
        self.apiClient = SetsAPI()
    }
    
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        guard !apiKeyManager.apiKey.isEmpty else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            let result = try await apiClient.setsList(
                key: apiKeyManager.apiKey,
                page: page,
                pageSize: pageSize,
                ordering: "-year"
            )
            
            return result.results?.compactMap { apiSet in
                LegoSet(
                    setNum: apiSet.setNum ?? "",
                    name: apiSet.name ?? "",
                    year: apiSet.year ?? 0,
                    themeId: apiSet.themeID ?? 0,
                    numParts: apiSet.numParts ?? 0,
                    imageURL: apiSet.setImgURL
                )
            } ?? []
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    throw BrixieError.networkError(underlying: error)
                case .badServerResponse:
                    throw BrixieError.serverError(statusCode: 500)
                default:
                    throw BrixieError.networkError(underlying: error)
                }
            } else {
                throw BrixieError.networkError(underlying: error)
            }
        }
    }
    
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
        guard !apiKeyManager.apiKey.isEmpty else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            let result = try await apiClient.setsList(
                key: apiKeyManager.apiKey,
                page: page,
                pageSize: pageSize,
                search: query,
                ordering: "-year"
            )
            
            return result.results?.compactMap { apiSet in
                LegoSet(
                    setNum: apiSet.setNum ?? "",
                    name: apiSet.name ?? "",
                    year: apiSet.year ?? 0,
                    themeId: apiSet.themeID ?? 0,
                    numParts: apiSet.numParts ?? 0,
                    imageURL: apiSet.setImgURL
                )
            } ?? []
        } catch {
            throw BrixieError.networkError(underlying: error)
        }
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        guard !apiKeyManager.apiKey.isEmpty else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            let apiSet = try await apiClient.setsRead(
                setNum: setNum,
                key: apiKeyManager.apiKey
            )
            
            return LegoSet(
                setNum: apiSet.setNum ?? "",
                name: apiSet.name ?? "",
                year: apiSet.year ?? 0,
                themeId: apiSet.themeID ?? 0,
                numParts: apiSet.numParts ?? 0,
                imageURL: apiSet.setImgURL
            )
        } catch {
            throw BrixieError.networkError(underlying: error)
        }
    }
}