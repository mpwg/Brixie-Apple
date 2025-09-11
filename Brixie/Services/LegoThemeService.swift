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
@MainActor
final class LegoThemeService {
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
    
    func fetchThemes(page: Int = 1, pageSize: Int = 100) async throws -> [LegoTheme] {
        isLoading = true
        error = nil
        
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
                    setCount: 0 // TODO: FIXME!
                )
            }
            
            // Save to SwiftData
            for theme in themes {
                modelContext.insert(theme)
            }
            
            do {
                try modelContext.save()
            } catch {
                self.error = BrixieError.persistenceError(underlying: error)
            }
            return themes
        } catch {
            self.error = mapToBrixieError(error)
            throw self.error!
        }
    }
    
    func getCachedThemes() -> [LegoTheme] {
        let descriptor = FetchDescriptor<LegoTheme>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            self.error = BrixieError.cacheError(underlying: error)
            return []
        }
    }
    
    func getSetsForTheme(themeId: Int, page: Int = 1, pageSize: Int = 20, ordering: String = "-year") async throws -> [LegoSet] {
        isLoading = true
        error = nil
        
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
            self.error = mapToBrixieError(error)
            throw self.error!
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
