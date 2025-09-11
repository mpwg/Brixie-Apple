//
//  LegoSetService.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Foundation
import RebrickableLegoAPIClient
import SwiftData

@Observable
@MainActor
final class LegoSetService {
    private let modelContext: ModelContext
    private let errorReporter = ErrorReporter.shared
    
    var isLoading = false
    var error: BrixieError? {
        didSet {
            if let error = error {
                errorReporter.report(error)
            }
        }
    }
    
    init(modelContext: ModelContext, apiKey: String) {
        RebrickableLegoAPIClientAPIConfiguration.shared.apiKey = apiKey
        self.modelContext = modelContext
    }
    
    func fetchSets(page: Int = 1, pageSize: Int = 20) async throws -> [LegoSet] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await LegoAPI.legoSetsList(
                page: page,
                pageSize: pageSize,
                ordering: "-year"
            )
            
            let legoSets = response.results.map { apiSet in
                LegoSet(
                    setNum: apiSet.setNum ?? "",
                    name: apiSet.name ?? "",
                    year: apiSet.year ?? 0,
                    themeId: apiSet.themeId ?? 301, // other
                    numParts: apiSet.numParts ?? 0,
                    imageURL: apiSet.setImgUrl
                )
            }
            
            // Save to SwiftData
            for set in legoSets {
                modelContext.insert(set)
            }
            
            try modelContext.save()
            return legoSets
        } catch {
            self.error = mapToBrixieError(error)
            throw self.error!
        }
    }
    
    func searchSets(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [LegoSet] {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await LegoAPI.legoSetsList(
                page: page,
                pageSize: pageSize,
                ordering: "-year",
                search: query
            )
            
            let legoSets = response.results.map { apiSet in
                LegoSet(
                    setNum: apiSet.setNum ?? "",
                    name: apiSet.name ?? "",
                    year: apiSet.year ?? 0,
                    themeId: apiSet.themeId ?? 301, // other
                    numParts: apiSet.numParts ?? 0,
                    imageURL: apiSet.setImgUrl
                )
            }
            
            return legoSets
        } catch {
            self.error = mapToBrixieError(error)
            throw self.error!
        }
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        isLoading = true
        error = nil
        
        defer { isLoading = false }
        
        do {
            let apiSet = try await LegoAPI.legoSetsRead(setNum: setNum)
            
            let legoSet = LegoSet(
                setNum: apiSet.setNum ?? "",
                name: apiSet.name ?? "",
                year: apiSet.year ?? 0,
                themeId: apiSet.themeId ?? 301, // other
                numParts: apiSet.numParts ?? 0,
                imageURL: apiSet.setImgUrl
            )
            
            return legoSet
        } catch {
            self.error = mapToBrixieError(error)
            throw self.error!
        }
    }
    
    func getCachedSets() -> [LegoSet] {
        let descriptor = FetchDescriptor<LegoSet>(
            sortBy: [SortDescriptor(\.year, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            self.error = BrixieError.cacheError(underlying: error)
            return []
        }
    }
    
    func toggleFavorite(_ set: LegoSet) {
        set.isFavorite.toggle()
        
        do {
            try modelContext.save()
        } catch {
            self.error = BrixieError.persistenceError(underlying: error)
        }
    }
    
    func markAsViewed(_ set: LegoSet) {
        set.lastViewed = Date()
        
        do {
            try modelContext.save()
        } catch {
            self.error = BrixieError.persistenceError(underlying: error)
        }
    }
    
    // MARK: Error Mapping
    
    private func mapToBrixieError(_ error: Error) -> BrixieError {
        if let brixieError = error as? BrixieError {
            return brixieError
        }
        
        // Map common error types
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError(underlying: error)
            case .timedOut:
                return .networkError(underlying: error)
            case .badURL:
                return .invalidURL(urlError.localizedDescription)
            default:
                return .networkError(underlying: error)
            }
        }
        
        // Default mapping
        return .networkError(underlying: error)
    }
}
