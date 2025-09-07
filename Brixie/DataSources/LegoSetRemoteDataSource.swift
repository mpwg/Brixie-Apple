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
    private let apiConfiguration: APIConfigurationService
    
    init(apiConfiguration: APIConfigurationService) {
        self.apiConfiguration = apiConfiguration
    }
    
    func fetchSets(page: Int, pageSize: Int) async throws -> [LegoSet] {
        guard apiConfiguration.hasValidAPIKey else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            // Set API key globally
            RebrickableLegoAPIClientAPIConfiguration.shared.apiKey = apiConfiguration.currentAPIKey 
            
            let response = try await LegoAPI.legoSetsList(
                page: page,
                pageSize: pageSize,
                ordering: "-year"
            )
            
            return response.results.map { apiSet in
                LegoSet(
                    setNum: apiSet.setNum ?? "",
                    name: apiSet.name ?? "",
                    year: apiSet.year ?? 0,
                    themeId: apiSet.themeId ?? 0,
                    numParts: apiSet.numParts ?? 0,
                    imageURL: apiSet.setImgUrl
                )
            }
        } catch {
            throw BrixieError.networkError(underlying: error)
        }
    }
    
    func searchSets(query: String, page: Int, pageSize: Int) async throws -> [LegoSet] {
        guard apiConfiguration.hasValidAPIKey else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            // Set API key globally
            RebrickableLegoAPIClientAPIConfiguration.shared.apiKey = apiConfiguration.currentAPIKey
            
            let response = try await LegoAPI.legoSetsList(
                page: page,
                pageSize: pageSize,
                ordering: "-year"
            )
            
            return response.results.map { apiSet in
                LegoSet(
                    setNum: apiSet.setNum ?? "",
                    name: apiSet.name ?? "",
                    year: apiSet.year ?? 0,
                    themeId: apiSet.themeId ?? 0,
                    numParts: apiSet.numParts ?? 0,
                    imageURL: apiSet.setImgUrl
                )
            }
        } catch {
            throw BrixieError.networkError(underlying: error)
        }
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        guard apiConfiguration.hasValidAPIKey else {
            throw BrixieError.apiKeyMissing
        }
        
        do {
            // Set API key globally
            RebrickableLegoAPIClientAPIConfiguration.shared.apiKey = apiConfiguration.currentAPIKey 
            
            let apiSet = try await LegoAPI.legoSetsRead(setNum: setNum)
            
            return LegoSet(
                setNum: apiSet.setNum ?? "",
                name: apiSet.name ?? "",
                year: apiSet.year ?? 0,
                themeId: apiSet.themeId ?? 0,
                numParts: apiSet.numParts ?? 0,
                imageURL: apiSet.setImgUrl
            )
        } catch {
            throw BrixieError.networkError(underlying: error)
        }
    }
}
