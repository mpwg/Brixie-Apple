//
//  Strings.swift
//  Brixie
//
//  Created by Claude on 07.09.25.
//

import Foundation

/// Type-safe localization API for Brixie app
/// 
/// This enum provides a centralized, type-safe way to access localized strings
/// throughout the app. Each case corresponds to a localized string with compile-time
/// safety and support for string interpolation.
///
/// ## Usage
/// 
/// ### Simple strings:
/// ```swift
/// let title = Strings.sets.localized
/// ```
/// 
/// ### Formatted strings:
/// ```swift
/// let count = Strings.piecesCount(42).localized
/// let setNumber = Strings.setNumber("10234").localized
/// ```
/// 
/// ### In SwiftUI:
/// ```swift
/// Text(Strings.favorites.localized)
/// Label(Strings.search.localized, systemImage: "magnifyingglass")
/// ```
enum Strings {
    
    // MARK: - Navigation & Tabs
    case categories
    case sets
    case search
    case favorites
    case settings
    
    // MARK: - Common Actions
    case done
    case reset
    case configure
    case loadMore
    case visitWebsite
    
    // MARK: - Search
    case searchSets
    case searchCategories
    case recentSearches
    case searchPlaceholder
    case noResults
    case noSetsFoundFormat(String)
    case searching
    case searchNotAvailable
    case all
    case themes
    case filters
    
    // MARK: - Set Details
    case setInformation
    case statistics
    case shareImage
    case tapToViewFullSize
    case setNumber(String)
    case piecesCount(Int)
    case addToFavorites
    case removeFromFavorites
    
    // MARK: - Sorting & Filtering
    case sortBy
    case nameAscending
    case nameDescending
    case yearNewest
    case yearOldest
    case partsLeast
    case partsMost
    case partCount
    case yearRange
    case minimum
    case maximum
    case min
    case max
    
    // MARK: - States & Loading
    case initializing
    case loadingSets
    case poweredByRebrickable
    
    // MARK: - Themes
    case light
    case dark
    case system
    
    // MARK: - Settings & Configuration
    case apiConfiguration
    case apiKeyRequired
    case apiKeyDescription
    case enterApiKey
    case enterApiKeyDescription
    case getApiKey
    case notConfigured
    case configured
    case imageCache
    case storage
    case clearCache
    case clearAllData
    case clearCacheDescription
    case appVersion
    case about
    case aboutDescription
    
    // MARK: - Error Messages
    case networkError(String)
    case apiKeyMissing
    case parsingError
    case cacheError(String)
    case invalidURL(String)
    case dataNotFound
    case persistenceError(String)
    case rateLimitExceeded
    case unauthorized
    case serverError(Int)
    
    // MARK: - Error Recovery
    case checkConnection
    case enterValidApiKey
    case waitBeforeRetry
    case clearAppCache
    case tryAgainLater
    
    // MARK: - Empty States
    case noSetsFound
    case noSetsFoundDescription
    case noFavoritesYet
    case noFavoritesDescription
    
    /// Returns the localized string for this case
    var localized: String {
        switch self {
        // MARK: - Navigation & Tabs
        case .categories:
            return NSLocalizedString("Categories", comment: "Tab label for categories")
        case .sets:
            return NSLocalizedString("Sets", comment: "Tab label for sets")
        case .search:
            return NSLocalizedString("Search", comment: "Tab label for search")
        case .favorites:
            return NSLocalizedString("Favorites", comment: "Tab label for favorites")
        case .settings:
            return NSLocalizedString("Settings", comment: "Tab label for settings")
            
        // MARK: - Common Actions
        case .done:
            return NSLocalizedString("Done", comment: "Done button")
        case .reset:
            return NSLocalizedString("Reset", comment: "Reset button")
        case .configure:
            return NSLocalizedString("Configure", comment: "Configure button")
        case .loadMore:
            return NSLocalizedString("Load More", comment: "Load more button")
        case .visitWebsite:
            return NSLocalizedString("Visit Website", comment: "Visit website button")
            
        // MARK: - Search
        case .searchSets:
            return NSLocalizedString("Search sets", comment: "Search sets placeholder")
        case .searchCategories:
            return NSLocalizedString("Search categories", comment: "Search categories placeholder")
        case .recentSearches:
            return NSLocalizedString("Recent Searches", comment: "Recent searches section header")
        case .searchPlaceholder:
            return NSLocalizedString("Search by set name, number, or theme", comment: "Search placeholder text")
        case .noResults:
            return NSLocalizedString("No Results", comment: "No search results")
        case .noSetsFoundFormat(let query):
            return String(format: NSLocalizedString("No sets found for '%@'. Try a different search term.", comment: "No sets found for search query"), query)
        case .searching:
            return NSLocalizedString("Searching...", comment: "Searching indicator")
        case .searchNotAvailable:
            return NSLocalizedString("Search Not Available", comment: "Search not available message")
        case .all:
            return NSLocalizedString("All", comment: "Search filter: All")
        case .themes:
            return NSLocalizedString("Themes", comment: "Search filter: Themes")
        case .filters:
            return NSLocalizedString("Filters", comment: "Filters section header")
            
        // MARK: - Set Details
        case .setInformation:
            return NSLocalizedString("Set Information", comment: "Set information section header")
        case .statistics:
            return NSLocalizedString("Statistics", comment: "Statistics section header")
        case .shareImage:
            return NSLocalizedString("Share Image", comment: "Share image action")
        case .tapToViewFullSize:
            return NSLocalizedString("Tap to view full size", comment: "Tap to view full size instruction")
        case .setNumber(let number):
            return String(format: NSLocalizedString("Set #%@", comment: "Set number display"), number)
        case .piecesCount(let count):
            return String(format: NSLocalizedString("%d pieces", comment: "Number of pieces"), count)
        case .addToFavorites:
            return NSLocalizedString("Add to Favorites", comment: "Add to favorites action")
        case .removeFromFavorites:
            return NSLocalizedString("Remove from Favorites", comment: "Remove from favorites action")
            
        // MARK: - Sorting & Filtering
        case .sortBy:
            return NSLocalizedString("Sort by", comment: "Sort by label")
        case .nameAscending:
            return NSLocalizedString("Name (A-Z)", comment: "Sort by name ascending")
        case .nameDescending:
            return NSLocalizedString("Name (Z-A)", comment: "Sort by name descending")
        case .yearNewest:
            return NSLocalizedString("Year (newest first)", comment: "Sort by year newest first")
        case .yearOldest:
            return NSLocalizedString("Year (oldest first)", comment: "Sort by year oldest first")
        case .partsLeast:
            return NSLocalizedString("Parts (least first)", comment: "Sort by parts least first")
        case .partsMost:
            return NSLocalizedString("Parts (most first)", comment: "Sort by parts most first")
        case .partCount:
            return NSLocalizedString("Part Count", comment: "Part count filter")
        case .yearRange:
            return NSLocalizedString("Year Range", comment: "Year range filter")
        case .minimum:
            return NSLocalizedString("Minimum", comment: "Minimum value")
        case .maximum:
            return NSLocalizedString("Maximum", comment: "Maximum value")
        case .min:
            return NSLocalizedString("Min:", comment: "Min label")
        case .max:
            return NSLocalizedString("Max:", comment: "Max label")
            
        // MARK: - States & Loading
        case .initializing:
            return NSLocalizedString("Initializing...", comment: "Initializing state")
        case .loadingSets:
            return NSLocalizedString("Loading sets...", comment: "Loading sets state")
        case .poweredByRebrickable:
            return NSLocalizedString("Powered by Rebrickable", comment: "Powered by Rebrickable attribution")
            
        // MARK: - Themes
        case .light:
            return NSLocalizedString("Light", comment: "Light theme")
        case .dark:
            return NSLocalizedString("Dark", comment: "Dark theme")
        case .system:
            return NSLocalizedString("System", comment: "System theme")
            
        // MARK: - Settings & Configuration
        case .apiConfiguration:
            return NSLocalizedString("API Configuration", comment: "API configuration section")
        case .apiKeyRequired:
            return NSLocalizedString("API Key Required", comment: "API key required title")
        case .apiKeyDescription:
            return NSLocalizedString("A free Rebrickable API key is required to fetch LEGO set data.", comment: "API key description")
        case .enterApiKey:
            return NSLocalizedString("Enter API Key", comment: "Enter API key title")
        case .enterApiKeyDescription:
            return NSLocalizedString("Enter your Rebrickable API key. Get one for free at rebrickable.com", comment: "Enter API key description")
        case .getApiKey:
            return NSLocalizedString("Get API Key", comment: "Get API key button")
        case .notConfigured:
            return NSLocalizedString("Not configured", comment: "Not configured status")
        case .configured:
            return NSLocalizedString("Configured", comment: "Configured status")
        case .imageCache:
            return NSLocalizedString("Image Cache", comment: "Image cache section")
        case .storage:
            return NSLocalizedString("Storage", comment: "Storage section")
        case .clearCache:
            return NSLocalizedString("Clear Cache", comment: "Clear cache button")
        case .clearAllData:
            return NSLocalizedString("Clear All Data", comment: "Clear all data button")
        case .clearCacheDescription:
            return NSLocalizedString("This will clear all cached images and set data. You can always re-download them later.", comment: "Clear cache description")
        case .appVersion:
            return NSLocalizedString("App Version", comment: "App version label")
        case .about:
            return NSLocalizedString("About", comment: "About section")
        case .aboutDescription:
            return NSLocalizedString("Brixie uses the Rebrickable API to provide LEGO set information.", comment: "About description")
            
        // MARK: - Error Messages
        case .networkError(let error):
            return String(format: NSLocalizedString("Network error: %@", comment: "Network error description"), error)
        case .apiKeyMissing:
            return NSLocalizedString("API key is required to fetch data", comment: "API key missing error")
        case .parsingError:
            return NSLocalizedString("Failed to parse response", comment: "Parsing error description")
        case .cacheError(let error):
            return String(format: NSLocalizedString("Cache operation failed: %@", comment: "Cache error description"), error)
        case .invalidURL(let url):
            return String(format: NSLocalizedString("Invalid URL: %@", comment: "Invalid URL error"), url)
        case .dataNotFound:
            return NSLocalizedString("Requested data not found", comment: "Data not found error")
        case .persistenceError(let error):
            return String(format: NSLocalizedString("Data persistence failed: %@", comment: "Persistence error description"), error)
        case .rateLimitExceeded:
            return NSLocalizedString("API rate limit exceeded. Please try again later", comment: "Rate limit error")
        case .unauthorized:
            return NSLocalizedString("Unauthorized. Please check your API key", comment: "Unauthorized error")
        case .serverError(let statusCode):
            return String(format: NSLocalizedString("Server error (status: %d)", comment: "Server error description"), statusCode)
            
        // MARK: - Error Recovery
        case .checkConnection:
            return NSLocalizedString("Check your internet connection and try again", comment: "Network error recovery")
        case .enterValidApiKey:
            return NSLocalizedString("Please enter a valid API key in settings", comment: "API key recovery")
        case .waitBeforeRetry:
            return NSLocalizedString("Wait a few minutes before making more requests", comment: "Rate limit recovery")
        case .clearAppCache:
            return NSLocalizedString("Try clearing the app cache in settings", comment: "Cache error recovery")
        case .tryAgainLater:
            return NSLocalizedString("Please try again later", comment: "Generic recovery suggestion")
            
        // MARK: - Empty States
        case .noSetsFound:
            return NSLocalizedString("No Sets Found", comment: "No sets found title")
        case .noSetsFoundDescription:
            return NSLocalizedString("Pull to refresh or check your internet connection", comment: "No sets found description")
        case .noFavoritesYet:
            return NSLocalizedString("No Favorites Yet", comment: "No favorites yet title")
        case .noFavoritesDescription:
            return NSLocalizedString("Sets you favorite will appear here", comment: "No favorites description")
        }
    }
}

// MARK: - Convenience Extensions

extension Strings {
    /// Returns the localized string (alias for localized property)
    var text: String {
        localized
    }
}

/// String interpolation support for Strings enum
extension String.StringInterpolation {
    mutating func appendInterpolation(_ string: Strings) {
        appendInterpolation(string.localized)
    }
}