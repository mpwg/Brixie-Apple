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
    
    var isLoading = false
    var errorMessage: String?
    
    init(modelContext: ModelContext, apiKey: String) {
        RebrickableLegoAPIClientAPIConfiguration.shared.apiKey = apiKey
        self.modelContext = modelContext
    }
    
    func fetchSets(page: Int = 1, pageSize: Int = 20) async throws -> [LegoSet] {
        isLoading = true
        errorMessage = nil
        
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
                    themeId: apiSet.themeId ?? 301, //other
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
            errorMessage = "Failed to fetch sets: \(error.localizedDescription)"
            throw error
        }
    }
    
    func searchSets(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [LegoSet] {
        isLoading = true
        errorMessage = nil
        
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
                    themeId: apiSet.themeId ?? 301, //other
                    numParts: apiSet.numParts ?? 0,
                    imageURL: apiSet.setImgUrl
                )
            }
            
            return legoSets
            
        } catch {
            errorMessage = "Failed to search sets: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getSetDetails(setNum: String) async throws -> LegoSet? {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let apiSet = try await LegoAPI.legoSetsRead(setNum: setNum)
            
            let legoSet = LegoSet(
                setNum: apiSet.setNum ?? "",
                name: apiSet.name   ?? "",
                year: apiSet.year ?? 0,
                themeId: apiSet.themeId ?? 301, //other
                numParts: apiSet.numParts ?? 0,
                imageURL: apiSet.setImgUrl
            )
            
            return legoSet
            
        } catch {
            errorMessage = "Failed to get set details: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getCachedSets() -> [LegoSet] {
        let descriptor = FetchDescriptor<LegoSet>(
            sortBy: [SortDescriptor(\.year, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch cached sets: \(error.localizedDescription)"
            return []
        }
    }
    
    func toggleFavorite(_ set: LegoSet) {
        set.isFavorite.toggle()
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update favorite: \(error.localizedDescription)"
        }
    }
    
    func markAsViewed(_ set: LegoSet) {
        set.lastViewed = Date()
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update view date: \(error.localizedDescription)"
        }
    }
}
