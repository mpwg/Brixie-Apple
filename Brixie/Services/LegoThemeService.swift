//
//  LegoThemeService.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Foundation
import RebrickableLegoAPIClient
import SwiftData

@Observable
class LegoThemeService {
    private let modelContext: ModelContext
    
    var isLoading = false
    var errorMessage: String?
    
    init(modelContext: ModelContext, apiKey: String) {
        RebrickableLegoAPIClientAPIConfiguration.shared.apiKey = apiKey
        self.modelContext = modelContext
    }
    
    func fetchThemes(page: Int = 1, pageSize: Int = 100) async throws -> [LegoTheme] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await LegoAPI.legoThemesList(
                page: page,
                pageSize: pageSize,
                ordering: "name"
            )
            
            let themes = response.results.map { apiTheme in
                LegoTheme(
                    id: apiTheme.id,
                    name: apiTheme.name,
                    parentId: apiTheme.parentId,
                    setCount: apiTheme.setCount ?? 0
                )
            }
            
            // Save to SwiftData
            for theme in themes {
                modelContext.insert(theme)
            }
            
            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to save themes: \(error.localizedDescription)"
            }
            return themes
            
        } catch {
            errorMessage = "Failed to fetch themes: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getCachedThemes() -> [LegoTheme] {
        let descriptor = FetchDescriptor<LegoTheme>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch cached themes: \(error.localizedDescription)"
            return []
        }
    }
    
    func getSetsForTheme(themeId: Int, page: Int = 1, pageSize: Int = 20, ordering: String = "-year") async throws -> [LegoSet] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let response = try await LegoAPI.legoSetsList(
                page: page,
                pageSize: pageSize,
                themeId: String(themeId),
                ordering: ordering
            )
            
            let legoSets = response.results.map { apiSet in
                LegoSet(
                    setNum: apiSet.setNum ?? "",
                    name: apiSet.name ?? "",
                    year: apiSet.year ?? 0,
                    themeId: apiSet.themeId ?? themeId,
                    numParts: apiSet.numParts ?? 0,
                    imageURL: apiSet.setImgUrl
                )
            }
            
            return legoSets
            
        } catch {
            errorMessage = "Failed to fetch sets for theme: \(error.localizedDescription)"
            throw error
        }
    }
}