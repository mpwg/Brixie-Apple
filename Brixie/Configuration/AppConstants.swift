//
//  AppConstants.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import Foundation
import SwiftUI

/// Centralized constants for the Brixie application
enum AppConstants {
    
    // MARK: - API & Networking
    enum API {
        /// Default page size for API requests
        static let defaultPageSize = 200
        
        /// Maximum page size allowed for API requests
        static let maxPageSize = 1000
        
        /// Cache freshness duration in seconds (1 hour)
        static let cacheExpirationInterval: TimeInterval = 3_600
        
        /// Network request timeout in seconds
        static let requestTimeout: TimeInterval = 30
        
        /// Retry delay for offline actions in nanoseconds (0.5 seconds)
        static let offlineRetryDelay: UInt64 = 500_000_000
    }
    
    // MARK: - Cache Configuration
    enum Cache {
        /// Maximum disk cache size in bytes (50MB)
        static let maxDiskCacheSize: Int = 50 * 1_024 * 1_024
        
        /// Memory cache limit for image data in bytes (15MB)
        static let memoryDataCacheLimit: Int = 15 * 1_024 * 1_024
        
        /// Memory cache limit for images in bytes (10MB)
        static let memoryImageCacheLimit: Int = 10 * 1_024 * 1_024
        
        /// Maximum number of images to keep in memory
        static let maxImagesInMemory = 50
    }
    
    // MARK: - User Interface
    enum UI {
        /// Standard corner radius for cards and containers
        static let standardCornerRadius: Double = 12
        
        /// Small corner radius for buttons and small elements
        static let smallCornerRadius: Double = 8
        
        /// Standard spacing between elements
        static let standardSpacing: Double = 16
        
        /// Small spacing between elements
        static let smallSpacing: Double = 8
        
        /// Large spacing between sections
        static let largeSpacing: Double = 24
        
        /// Standard card height for set images
        static let cardImageHeight: Double = 120
        
        /// Navigation split view minimum width
        static let navigationMinWidth: Double = 200
        
        /// Navigation split view ideal width
        static let navigationIdealWidth: Double = 250
        
        /// Skeleton loading shimmer height
        static let skeletonHeight: Double = 24
        
        /// Skeleton loading opacity
        static let skeletonOpacity: Double = 0.15
        
        /// Grid item minimum width
        static let gridItemMinWidth: Double = 280
    }
    
    // MARK: - Animation Durations
    enum Animation {
        /// Quick animation duration (0.2 seconds)
        static let quick: Double = 0.2
        
        /// Normal animation duration (0.3 seconds)
        static let normal: Double = 0.3
        
        /// Slow animation duration (0.5 seconds)
        static let slow: Double = 0.5
        
        /// Long animation duration (1.0 second)
        static let long: Double = 1.0
        
        /// Tab switching animation duration
        static let tabSwitchDuration: Double = 0.3
        
        /// Detail navigation delay
        static let navigationDelay: Double = 0.5
        
        /// Spring animation response
        static let springResponse: Double = 0.5
        
        /// Spring animation damping fraction
        static let springDamping: Double = 0.8
        
        /// Scale effect for loading animations
        static let loadingScaleEffect: Double = 0.1
        
        /// Scale multiplier for pressed state
        static let pressedScale: Double = 1.2
    }
    
    // MARK: - Search & History
    enum Search {
        /// Maximum number of search history items to keep
        static let maxHistoryItems = 20
        
        /// Minimum search query length
        static let minQueryLength = 1
        
        /// Maximum search results to display
        static let maxSearchResults = 50
        
        /// Number of recent searches to show in suggestions
        static let recentSuggestionsCount = 5
        
        /// Number of popular searches to show in suggestions
        static let popularSuggestionsCount = 5
        
        /// Number of matching recent searches to show
        static let matchingRecentCount = 3
        
        /// Number of matching default suggestions to show
        static let matchingDefaultCount = 7
    }
    
    // MARK: - Collection Management
    enum Collection {
        /// Default limit for recent acquisitions
        static let recentAcquisitionsLimit = 10
        
        /// Maximum missing parts per set to display
        static let maxDisplayedMissingParts = 100
    }
    
    // MARK: - Data Persistence
    enum Storage {
        /// Key for storing last sync date in UserDefaults
        static let lastSyncDateKey = "LastSyncDate"
        
        /// Key for storing search history in UserDefaults
        static let searchHistoryKey = "SearchHistory"
        
        /// Key for storing API key in UserDefaults
        static let apiKeyKey = "rebrickableAPIKey"
    }
    
    // MARK: - Testing & UI Tests
    enum Testing {
        /// Default timeout for UI element appearance
        static let defaultUITimeout: Double = 5.0
        
        /// Short timeout for quick UI interactions
        static let shortUITimeout: Double = 2.0
        
        /// Long timeout for network operations
        static let networkTimeout: Double = 10.0
        
        /// Performance test iteration count
        static let performanceIterations = 3
        
        /// Performance test inner loop count
        static let performanceInnerLoopCount = 10
    }
    
    // MARK: - Accessibility
    enum Accessibility {
        /// Font size for large icons
        static let largeIconSize: Double = 64
        
        /// Minimum tap target size (44x44 points per Apple HIG)
        static let minTapTargetSize: Double = 44
        
        /// Standard padding for accessible content
        static let accessiblePadding: Double = 16
    }
    
    // MARK: - Sample Data
    enum SampleData {
        /// Sample LEGO part number for testing
        static let samplePartNumber = "3001"
        
        /// Sample theme ID for testing
        static let sampleThemeId = 1
        
        /// Sample subtheme ID for testing
        static let sampleSubthemeId = 2
    }
}

// MARK: - Computed Properties
extension AppConstants {
    
    /// Commonly used UserDefaults keys as a collection
    enum UserDefaultsKeys {
        static let lastSyncDate = Storage.lastSyncDateKey
        static let searchHistory = Storage.searchHistoryKey
        static let apiKey = Storage.apiKeyKey
    }
    
    /// Common animation configurations
    enum CommonAnimations {
        static let quickEaseInOut = SwiftUI.Animation.easeInOut(duration: Animation.quick)
        static let normalEaseInOut = SwiftUI.Animation.easeInOut(duration: Animation.normal)
        static let slowEaseInOut = SwiftUI.Animation.easeInOut(duration: Animation.slow)
        static let tabSwitch = SwiftUI.Animation.easeInOut(duration: Animation.tabSwitchDuration)
        static let loadingPulse = SwiftUI.Animation.easeInOut(duration: Animation.long).repeatForever(autoreverses: true)
        static let springDefault = SwiftUI.Animation.spring(
            response: Animation.springResponse,
            dampingFraction: Animation.springDamping,
            blendDuration: 0
        )
    }
    
    /// Common spacing values for UI layout
    enum Spacing {
        static let xs: Double = 4
        static let small = UI.smallSpacing
        static let standard = UI.standardSpacing
        static let large = UI.largeSpacing
        static let xl: Double = 32
    }
    
    /// Common corner radius values
    enum CornerRadius {
        static let small = UI.smallCornerRadius
        static let standard = UI.standardCornerRadius
        static let large: Double = 16
        static let extraLarge: Double = 20
    }
}