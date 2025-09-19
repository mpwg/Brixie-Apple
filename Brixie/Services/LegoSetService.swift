//
//  LegoSetService.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import Foundation
import SwiftData
import SwiftUI
import RebrickableLegoAPIClient
import OSLog

/// Service for managing LEGO set data from Rebrickable API and local cache
@MainActor
final class LegoSetService {
    /// Singleton instance
    static let shared = LegoSetService()
    
    /// Logger for LegoSet service operations
    private let logger = Logger.legoSetService
    
    /// SwiftData model context for database operations
    private var modelContext: ModelContext?
    
    /// API configuration manager
    private let apiConfig = APIConfiguration.shared
    
    /// Current loading state
    var isLoading: Bool = false
    
    /// Current error state
    var currentError: (any Error)?
    
    /// Last sync date
    var lastSyncDate: Date?
    
    // MARK: - Initialization
    
    init() {
        logger.debug("🎯 LegoSetService initialized")
        loadLastSyncDate()
    }
    
    /// Configure with SwiftData model context
    func configure(with context: ModelContext) {
        self.modelContext = context
        logger.info("⚙️ LegoSetService configured with ModelContext")
    }
    
    // MARK: - Set Operations
    
    /// Fetch sets from API or local cache
    func fetchSets(limit: Int = AppConstants.API.defaultPageSize, offset: Int = 0) async throws -> [LegoSet] {
        logger.entering(parameters: ["limit": limit, "offset": offset])
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard modelContext != nil else {
            logger.error("❌ ModelContext not configured")
            logger.exitWith(result: "error: not configured")
            throw ServiceError.notConfigured
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // First try to load from local cache
            let cachedSets = try fetchCachedSets(limit: limit, offset: offset)
            
            // If we have cached data and it's recent, return it
            if !cachedSets.isEmpty && isDataFresh() {
                logger.info("📱 Using cached sets: \(cachedSets.count) items (data is fresh)")
                // Ensure relationships are established even for cached data
                try await establishSetThemeRelationships()
                
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                logger.debug("⏱️ Cache fetch completed in \(duration, format: .fixed(precision: 3))s")
                logger.exitWith(result: "\(cachedSets.count) cached sets")
                return cachedSets
            }
            
            logger.debug("🌐 Cached data unavailable or stale, fetching from API")
            // Otherwise, fetch from API
            let fetchedSets = try await fetchSetsFromAPI(limit: limit, offset: offset)
            
            // Establish relationships after fetching from API
            try await establishSetThemeRelationships()
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.info("✅ Fetched \(fetchedSets.count) sets in \(duration, format: .fixed(precision: 3))s")
            logger.exitWith(result: "\(fetchedSets.count) API sets")
            return fetchedSets
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.error("❌ Failed to fetch sets after \(duration, format: .fixed(precision: 3))s: \(error.localizedDescription)")
            logger.exitWith(result: "error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Fetch sets by theme with pagination info
    func fetchSets(forThemeId themeId: Int, limit: Int = AppConstants.API.defaultPageSize, offset: Int = 0) async throws -> [LegoSet] {
        let result = try await fetchSetsWithPagination(forThemeId: themeId, limit: limit, offset: offset)
        return result.sets
    }
    
    /// Fetch sets by theme returning both sets and pagination information
    func fetchSetsWithPagination(forThemeId themeId: Int, limit: Int = AppConstants.API.defaultPageSize, offset: Int = 0) async throws -> (sets: [LegoSet], totalCount: Int) {
        guard let context = modelContext else {
            throw ServiceError.notConfigured
        }
        
        // Try local cache first
        let descriptor = FetchDescriptor<LegoSet>(
            predicate: #Predicate { $0.themeId == themeId },
            sortBy: [SortDescriptor(\.year, order: .reverse), SortDescriptor(\.name)]
        )
        
        let cachedSets = try context.fetch(descriptor)
        
        if !cachedSets.isEmpty && isDataFresh() {
            let paginatedSets = Array(cachedSets.dropFirst(offset).prefix(limit))
            return (sets: paginatedSets, totalCount: cachedSets.count)
        }
        
        // Fetch from API
        guard apiConfig.isConfigured else {
            throw ServiceError.apiNotConfigured
        }
        
        do {
            // Calculate page number (API uses 1-based pagination)
            let page = (offset / limit) + 1
            
            // Get the API client configuration
            guard let apiClientConfig = apiConfig.apiClient else {
                throw ServiceError.apiNotConfigured
            }
            
            // Call Rebrickable API to get sets list filtered by theme
            let apiResponse = try await LegoAPI.legoSetsList(
                page: page,
                pageSize: limit,
                themeId: String(themeId),
                apiConfiguration: apiClientConfig
            )
            
            // Convert and cache the results
            var convertedSets: [LegoSet] = []
            
            for apiSet in apiResponse.results {
                let localSet = convertToLegoSet(apiSet)
                
                // Check if set already exists in context
                let setNumber = localSet.setNumber
                let fetchExistingSetDescriptor = FetchDescriptor<LegoSet>(
                    predicate: #Predicate<LegoSet> { set in
                        set.setNumber == setNumber
                    }
                )
                
                if let existingSet = try context.fetch(fetchExistingSetDescriptor).first {
                    // Update existing set
                    existingSet.name = localSet.name
                    existingSet.year = localSet.year
                    existingSet.themeId = localSet.themeId
                    existingSet.numParts = localSet.numParts
                    existingSet.setImageURL = localSet.setImageURL
                    existingSet.lastModified = localSet.lastModified
                    convertedSets.append(existingSet)
                } else {
                    // Insert new set
                    context.insert(localSet)
                    convertedSets.append(localSet)
                }
            }
            
            // Save context
            try context.save()
            
            // Return both sets and total count from API response
            return (sets: convertedSets, totalCount: apiResponse.count)
        } catch {
            // If API fails, return cached data if available
            if !cachedSets.isEmpty {
                let paginatedSets = Array(cachedSets.dropFirst(offset).prefix(limit))
                return (sets: paginatedSets, totalCount: cachedSets.count)
            }
            
            // Convert API errors to service errors
            if error is ErrorResponse {
                throw ServiceError.networkError
            } else {
                throw ServiceError.parseError
            }
        }
    }
    
    /// Search sets by various criteria
    func searchSets(
        query: String,
        searchType: SearchType = .name,
        limit: Int = AppConstants.API.defaultPageSize
    ) async throws -> [LegoSet] {
        guard let context = modelContext else {
            throw ServiceError.notConfigured
        }
        
        let predicate: Predicate<LegoSet>
        
        switch searchType {
        case .name:
            predicate = #Predicate { set in
                set.name.localizedStandardContains(query)
            }
        case .setNumber:
            predicate = #Predicate { set in
                set.setNumber.localizedStandardContains(query)
            }
        case .theme:
            // This would need to join with Theme table
            predicate = #Predicate { set in
                set.name.localizedStandardContains(query)
            }
        case .barcode:
            // Barcode search would need special handling
            predicate = #Predicate { set in
                set.setNumber == query
            }
        }
        
        let descriptor = FetchDescriptor<LegoSet>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.year, order: .reverse)]
        )
        
        let cachedResults = try context.fetch(descriptor)
        
        // If we have cached results or API is not configured, return cached data
        if !cachedResults.isEmpty || !apiConfig.isConfigured {
            return Array(cachedResults.prefix(limit))
        }
        
        // Try API search for name-based queries
        if searchType == .name && !query.isEmpty {
            do {
                // Get the API client configuration
                guard let apiClientConfig = apiConfig.apiClient else {
                    return Array(cachedResults.prefix(limit))
                }
                
                let apiResponse = try await LegoAPI.legoSetsList(
                    pageSize: limit,
                    search: query,
                    apiConfiguration: apiClientConfig
                )
                
                // Convert and cache the results
                var convertedSets: [LegoSet] = []
                
                for apiSet in apiResponse.results {
                    let localSet = convertToLegoSet(apiSet)
                    
                    // Check if set already exists in context
                    let setNumber = localSet.setNumber
                    let searchExistingSetDescriptor = FetchDescriptor<LegoSet>(
                        predicate: #Predicate<LegoSet> { set in
                            set.setNumber == setNumber
                        }
                    )
                    
                    if let existingSet = try context.fetch(searchExistingSetDescriptor).first {
                        // Update existing set
                        existingSet.name = localSet.name
                        existingSet.year = localSet.year
                        existingSet.themeId = localSet.themeId
                        existingSet.numParts = localSet.numParts
                        existingSet.setImageURL = localSet.setImageURL
                        existingSet.lastModified = localSet.lastModified
                        convertedSets.append(existingSet)
                    } else {
                        // Insert new set
                        context.insert(localSet)
                        convertedSets.append(localSet)
                    }
                }
                
                // Save context
                try context.save()
                
                return convertedSets
            } catch {
                // If API fails, fall back to cached results
                return Array(cachedResults.prefix(limit))
            }
        }
        
        return Array(cachedResults.prefix(limit))
    }
    
    /// Get set by set number
    func getSet(byNumber setNumber: String) async throws -> LegoSet? {
        guard let context = modelContext else {
            throw ServiceError.notConfigured
        }
        
        let descriptor = FetchDescriptor<LegoSet>(
            predicate: #Predicate { $0.setNumber == setNumber }
        )
        
        // Try to find in cache first
        if let cachedSet = try context.fetch(descriptor).first {
            // If data is fresh, return cached version
            if isDataFresh() {
                return cachedSet
            }
        }
        
        // Try to fetch from API if configured
        guard apiConfig.isConfigured else {
            // Return cached version even if not fresh if API is not configured
            return try context.fetch(descriptor).first
        }
        
        do {
            // Get the API client configuration
            guard let apiClientConfig = apiConfig.apiClient else {
                // Return cached version if API client not available
                return try context.fetch(descriptor).first
            }
            
            // Call API to get specific set details
            let apiSet = try await LegoAPI.legoSetsRead(
                setNum: setNumber,
                apiConfiguration: apiClientConfig
            )
            
            let localSet = convertToLegoSet(apiSet)
            
            // Check if set already exists in context
            if let existingSet = try context.fetch(descriptor).first {
                // Update existing set
                existingSet.name = localSet.name
                existingSet.year = localSet.year
                existingSet.themeId = localSet.themeId
                existingSet.numParts = localSet.numParts
                existingSet.setImageURL = localSet.setImageURL
                existingSet.lastModified = localSet.lastModified
                
                try context.save()
                return existingSet
            } else {
                // Insert new set
                context.insert(localSet)
                try context.save()
                return localSet
            }
        } catch {
            // If API fails, return cached version if available
            return try context.fetch(descriptor).first
        }
    }
    
    // MARK: - Private Methods
    
    /// Fetch sets from local cache
    private func fetchCachedSets(limit: Int, offset: Int) throws -> [LegoSet] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<LegoSet>(
            sortBy: [SortDescriptor(\.year, order: .reverse), SortDescriptor(\.name)]
        )
        
        let allSets = try context.fetch(descriptor)
        let startIndex = min(offset, allSets.count)
        let endIndex = min(offset + limit, allSets.count)
        
        return Array(allSets[startIndex..<endIndex])
    }
    
    /// Fetch sets from API and cache them
    private func fetchSetsFromAPI(limit: Int, offset: Int) async throws -> [LegoSet] {
        guard let context = modelContext else {
            throw ServiceError.notConfigured
        }
        
        guard apiConfig.isConfigured else {
            throw ServiceError.apiNotConfigured
        }
        
        do {
            // Calculate page number (API uses 1-based pagination)
            let page = (offset / limit) + 1
            
            // Get the API client configuration
            guard let apiClientConfig = apiConfig.apiClient else {
                throw ServiceError.apiNotConfigured
            }
            
            // Call Rebrickable API to get sets list
            let apiResponse = try await LegoAPI.legoSetsList(
                page: page,
                pageSize: limit,
                apiConfiguration: apiClientConfig
            )
            
            // Convert API models to local models and save to context
            var convertedSets: [LegoSet] = []
            
            for apiSet in apiResponse.results {
                // Convert ModelSet to LegoSet
                let localSet = convertToLegoSet(apiSet)
                
                // Check if set already exists in context
                let setNumber = localSet.setNumber
                let existingDescriptor = FetchDescriptor<LegoSet>(
                    predicate: #Predicate<LegoSet> { set in
                        set.setNumber == setNumber
                    }
                )
                
                if let existingSet = try context.fetch(existingDescriptor).first {
                    // Update existing set
                    existingSet.name = localSet.name
                    existingSet.year = localSet.year
                    existingSet.themeId = localSet.themeId
                    existingSet.numParts = localSet.numParts
                    existingSet.setImageURL = localSet.setImageURL
                    existingSet.lastModified = localSet.lastModified
                    convertedSets.append(existingSet)
                } else {
                    // Insert new set
                    context.insert(localSet)
                    convertedSets.append(localSet)
                }
            }
            
            // Save context
            try context.save()
            
            // Update last sync date
            lastSyncDate = Date()
            saveLastSyncDate()
            
            return convertedSets
        } catch {
            // Convert API errors to service errors
            if error is ErrorResponse {
                throw ServiceError.networkError
            } else {
                throw ServiceError.parseError
            }
        }
    }
    
    /// Check if cached data is fresh (less than 1 hour old)
    private func isDataFresh() -> Bool {
        guard let lastSync = lastSyncDate else { return false }
        return Date().timeIntervalSince(lastSync) < AppConstants.API.cacheExpirationInterval
    }
    
    /// Load last sync date from UserDefaults
    private func loadLastSyncDate() {
        if let date = UserDefaults.standard.object(forKey: AppConstants.UserDefaultsKeys.lastSyncDate) as? Date {
            lastSyncDate = date
        }
    }
    
    /// Save last sync date to UserDefaults
    private func saveLastSyncDate() {
        if let date = lastSyncDate {
            UserDefaults.standard.set(date, forKey: AppConstants.UserDefaultsKeys.lastSyncDate)
        }
    }
    
    // MARK: - Model Conversion
    
    /// Convert API ModelSet to local LegoSet
    private func convertToLegoSet(_ apiSet: ModelSet) -> LegoSet {
        return LegoSet(
            setNumber: apiSet.setNum ?? "",
            name: apiSet.name ?? "Unknown Set",
            year: apiSet.year ?? 0,
            themeId: apiSet.themeId ?? 0,
            numParts: apiSet.numParts ?? 0,
            setImageURL: apiSet.setImgUrl,
            lastModified: apiSet.lastModifiedDt ?? Date()
        )
    }
}

// MARK: - Supporting Types

extension LegoSetService {
    /// Types of search that can be performed
    enum SearchType: CaseIterable {
        case name
        case setNumber
        case theme
        case barcode
        
        var localizedTitle: String {
            switch self {
            case .name:
                return NSLocalizedString("Set Name", comment: "Search by set name")
            case .setNumber:
                return NSLocalizedString("Set Number", comment: "Search by set number")
            case .theme:
                return NSLocalizedString("Theme", comment: "Search by theme")
            case .barcode:
                return NSLocalizedString("Barcode", comment: "Search by barcode")
            }
        }
    }
    
    // MARK: - Relationship Management
    
    /// Establish relationships between sets and themes
    private func establishSetThemeRelationships() async throws {
        guard let modelContext = modelContext else {
            throw ServiceError.notConfigured
        }
        
        // Fetch all themes and sets
        let allThemes = try modelContext.fetch(FetchDescriptor<Theme>())
        let allSets = try modelContext.fetch(FetchDescriptor<LegoSet>())
        
        // Create lookup dictionary for efficient theme access
        var themeById: [Int: Theme] = [:]
        for theme in allThemes {
            themeById[theme.id] = theme
        }
        
        Logger.legoSetService.info("Establishing set-theme relationships for \(allSets.count) sets")
        
        // Establish set-theme relationships
        var relationshipsEstablished = 0
        for set in allSets {
            if let theme = themeById[set.themeId] {
                // Set the theme relationship if not already set
                if set.theme != theme {
                    set.theme = theme
                    relationshipsEstablished += 1
                }
                
                // Add set to theme's sets if not already there
                if !theme.sets.contains(set) {
                    theme.sets.append(set)
                }
            }
        }
        
        if relationshipsEstablished > 0 {
            Logger.legoSetService.info("Established \(relationshipsEstablished) new set-theme relationships")
            try modelContext.save()
        } else {
            Logger.legoSetService.debug("All set-theme relationships already established")
        }
    }
    
    /// Service errors
    enum ServiceError: LocalizedError {
        case notConfigured
        case apiNotConfigured
        case networkError
        case parseError
        
        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return NSLocalizedString("Service not configured with model context", comment: "Service error")
            case .apiNotConfigured:
                return NSLocalizedString("API not configured. Please add your Rebrickable API key.", comment: "API error")
            case .networkError:
                return NSLocalizedString("Network error occurred", comment: "Network error")
            case .parseError:
                return NSLocalizedString("Failed to parse API response", comment: "Parse error")
            }
        }
    }
}
