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
        
        /// Maximum number of data objects in memory cache
        static let maxDataObjectsInMemory = 100
    }
    
    // MARK: - User Interface
    enum UI {
        /// Standard corner radius for cards and containers
        static let standardCornerRadius: CGFloat = 12
        
        /// Small corner radius for buttons and small elements
        static let smallCornerRadius: CGFloat = 8
        
        /// Standard spacing between elements
        static let standardSpacing: CGFloat = 16
        
        /// Small spacing between elements
        static let smallSpacing: CGFloat = 8
        
        /// Large spacing between sections
        static let largeSpacing: CGFloat = 24
        
        /// Large padding for major layout sections
        static let largePadding: CGFloat = 32
        
        /// Standard card height for set images
        static let cardImageHeight: CGFloat = 120
        
        /// Navigation split view minimum width
        static let navigationMinWidth: CGFloat = 200
        
        /// Navigation split view ideal width
        static let navigationIdealWidth: CGFloat = 250
        
        /// Skeleton loading shimmer height
        static let skeletonHeight: CGFloat = 24
        
        /// Skeleton loading opacity
        static let skeletonOpacity: Double = 0.15
        
        /// Grid item minimum width
        static let gridItemMinWidth: CGFloat = 280
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
        
        /// Bouncy spring response
        static let bouncySpringResponse: Double = 0.6
        
        /// Bouncy spring damping
        static let bouncySpringDamping: Double = 0.6
        
        /// Gentle spring response
        static let gentleSpringResponse: Double = 0.8
        
        /// Gentle spring damping (no overshoot)
        static let gentleSpringDamping: Double = 1.0
        
        /// List animation duration (insert)
        static let listInsertDuration: Double = 0.4
        
        /// List animation duration (remove)
        static let listRemoveDuration: Double = 0.3
        
        /// Sheet presentation duration
        static let sheetDuration: Double = 0.4
        
        /// Long animation duration for loading states
        static let longDuration: Double = 1.0
        
        /// Rotation animation duration
        static let rotationDuration: Double = 1.5
    }
    
    // MARK: - Image Quality Settings
    enum ImageQuality {
        /// High quality image compression (for full-size images)
        static let high: Double = 0.95
        
        /// Medium quality image compression (for standard images)
        static let medium: Double = 0.85
        
        /// Low quality image compression (for background/preview)
        static let low: Double = 0.75
        
        /// Standard HEIC quality
        static let standardHEIC: Double = 0.8
        
        /// Standard JPEG quality
        static let standardJPEG: Double = 0.8
        
        /// Maximum quality (lossless)
        static let maximum: Double = 1.0
        
        /// Minimum quality
        static let minimum: Double = 0.1
    }
    
    // MARK: - Time Intervals
    enum TimeIntervals {
        /// Hours in a day
        static let hoursPerDay: Double = 24.0
        
        /// Seconds per hour
        static let secondsPerHour: Double = 3600.0
        
        /// Cache sync validity period (hours)
        static let cacheSyncValidHours: Double = 24.0
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
        static let matchingDefaultCount = 2
        
        /// Maximum part count for filters
        static let maxPartCount: Double = 10000
        
        /// Part count step for sliders
        static let partCountStep: Double = 50
    }
    
    // MARK: - Achievement Thresholds
    enum Achievements {
        /// Sets needed for Collector achievement
        static let collectorSets = 100
        
        /// Sets needed for Enthusiast achievement
        static let enthusiastSets = 50
        
        /// Sets needed for Builder achievement
        static let builderSets = 10
        
        /// Parts needed for Parts Master achievement
        static let partsMasterThreshold = 10000
        
        /// ROI percentage for Smart Investor achievement
        static let smartInvestorROI = 50.0
        
        /// Themes needed for Theme Explorer achievement
        static let themeExplorerCount = 10
        
        /// Percentage multiplier for calculations
        static let percentageMultiplier = 100.0
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
        static let largeIconSize: CGFloat = 64
        
        /// Minimum tap target size (44x44 points per Apple HIG)
        static let minTapTargetSize: CGFloat = 44
        
        /// Standard padding for accessible content
        static let accessiblePadding: CGFloat = 16
    }
    
    // MARK: - Visual Effects
    enum VisualEffects {
        /// Standard shadow opacity
        static let standardShadowOpacity: Double = 0.1
        
        /// Hover shadow opacity
        static let hoverShadowOpacity: Double = 0.15
        
        /// Standard shadow radius
        static let standardShadowRadius: Double = 2
        
        /// Hover shadow radius
        static let hoverShadowRadius: Double = 6
        
        /// Standard shadow offset Y
        static let standardShadowY: Double = 1
        
        /// Hover shadow offset Y
        static let hoverShadowY: Double = 3
        
        /// Pressed scale factor
        static let pressedScaleFactor: Double = 0.98
        
        /// Selected icon scale factor
        static let selectedIconScale: Double = 1.1
        
        /// Standard placeholder opacity
        static let placeholderOpacity: Double = 0.8
        
        /// Shimmer gradient opacity
        static let shimmerOpacity: Double = 0.3
        
        /// Progress view scale factor
        static let progressViewScale: Double = 1.2
        
        /// Error icon scale effect
        static let errorIconScale: Double = 0.8
        
        /// Loading icon scale base
        static let loadingIconScaleBase: Double = 1.0
    }
    
    // MARK: - Layout Dimensions
    enum Layout {
        /// Standard list item height
        static let standardListItemHeight: CGFloat = 60
        
        /// Set card image size
        static let setCardImageSize: CGFloat = 60
        
        /// Icon button size for collection actions
        static let iconButtonSize: CGFloat = 48
        
        /// Large preview image size
        static let largePreviewSize: CGFloat = 200
        
        /// Skeleton loading item count
        static let defaultSkeletonItemCount = 8
        
        /// Theme grid item count for preview
        static let themePreviewItemCount = 5
        
        /// Grid spacing in grids and lists
        static let gridSpacing: CGFloat = 16
        
        /// List row vertical spacing
        static let listRowSpacing: CGFloat = 12
        
        /// Card content vertical spacing
        static let cardContentSpacing: CGFloat = 4
        
        /// Small field width for filters
        static let smallFieldWidth: CGFloat = 50
        
        /// Medium field width for labels
        static let mediumFieldWidth: CGFloat = 60
        
        /// Button row horizontal spacing  
        static let buttonRowSpacing: CGFloat = 2
        
        /// Stats container spacing
        static let statsSpacing: CGFloat = 20
        
        /// Skeleton row internal spacing
        static let skeletonRowSpacing: CGFloat = 4
    }
    
    // MARK: - Image Dimensions
    enum ImageSize {
        /// Thumbnail width
        static let thumbnailWidth: CGFloat = 60
        
        /// Thumbnail height  
        static let thumbnailHeight: CGFloat = 60
        
        /// Icon size for collection status
        static let collectionIconSize: CGFloat = 48
        
        /// Large icon size
        static let largeIconSize: CGFloat = 64
        
        /// Preview image width for sharing
        static let previewWidth: CGFloat = 200
        
        /// Preview image height for sharing
        static let previewHeight: CGFloat = 200
        
        /// Skeleton placeholder dimensions
        static let skeletonPlaceholderHeight: CGFloat = 16
        
        /// Skeleton secondary placeholder height
        static let skeletonSecondaryHeight: CGFloat = 12
        
        /// Maximum skeleton placeholder width
        static let skeletonMaxWidth: CGFloat = 100
    }
    
    // MARK: - Timing & Delays
    enum Timing {
        /// Quick interaction delay (ms)
        static let quickDelay: UInt64 = 100_000_000 // 0.1 seconds in nanoseconds
        
        /// Standard loading delay
        static let standardDelay: Double = 1.0
        
        /// Skeleton animation duration
        static let skeletonAnimationDuration: Double = 1.5
        
        /// Search debounce delay (ms)
        static let searchDebounceDelay: UInt64 = 300_000_000 // 0.3 seconds
        
        /// Haptic feedback delay
        static let hapticDelay: UInt64 = 50_000_000 // 0.05 seconds
        
        /// Auto refresh interval (seconds)
        static let autoRefreshInterval: TimeInterval = 300 // 5 minutes
    }
    
    // MARK: - Numeric Limits & Thresholds
    enum Limits {
        /// Maximum items to show in wishlists sharing  
        static let maxSharedWishlistItems = 10
        
        /// Maximum fraction digits for price formatting
        static let maxPriceDecimalPlaces = 0
        
        /// HTTP success status code
        static let httpSuccessCode = 200
        
        /// Cache cleanup threshold (80% of max size)
        static let cacheCleanupThreshold: Double = 0.8
        
        /// Percentage display precision
        static let percentagePrecision = 1
        
        /// Performance measurement precision (decimal places)
        static let performancePrecision = 3
        
        /// Base scale for animation calculations
        static let baseAnimationScale: Double = 1.0
        
        /// Zero value for default/fallback cases (as Double for animations)
        static let zeroValue: Double = 0
        
        /// Zero value as Int for counts and indices
        static let zeroInt = 0
        
        /// Directory index for documents path
        static let documentsDirectoryIndex = 0
    }
    
    // MARK: - Opacity & Transparency
    enum Opacity {
        /// Secondary text opacity
        static let secondaryText: Double = 0.8
        
        /// Disabled element opacity
        static let disabled: Double = 0.6
        
        /// Skeleton animation minimum opacity
        static let skeletonMin: Double = 0.3
        
        /// Skeleton animation maximum opacity
        static let skeletonMax: Double = 0.8
        
        /// Loading shimmer primary
        static let shimmerPrimary: Double = 0.5
        
        /// Loading shimmer secondary
        static let shimmerSecondary: Double = 0.8
        
        /// Full opacity for accessibility compliance
        static let full: Double = 1.0
        
        /// Visible (no transparency)
        static let visible: Double = 1.0
        
        /// Light overlay or background
        static let light: Double = 0.2
        
        /// Medium transparency
        static let medium: Double = 0.5
        
        /// Subtle background overlay
        static let backgroundOverlay: Double = 0.95
        
        /// Subtle effect opacity
        static let subtle: Double = 0.1
        
        /// Accessibility high contrast opacity
        static let highContrast: Double = 0.95
        
        /// Accessibility border opacity (differentiate without color)
        static let accessibilityBorder: Double = 0.3
        
        /// Accessibility background opacity (differentiate without color)
        static let accessibilityBackground: Double = 0.1
    }
    
    // MARK: - Sample Data
    enum SampleData {
        /// Sample LEGO part number for testing
        static let samplePartNumber = "3001"
        
        /// Sample theme ID for testing
        static let sampleThemeId = 1
        
        /// Sample subtheme ID for testing
        static let sampleSubthemeId = 2
        
        /// Sample set number for testing
        static let sampleSetNumber = "75301"
        
        /// Sample theme name
        static let sampleThemeName = "Star Wars"
        
        /// Sample set year
        static let sampleYear = 2021
        
        /// Sample piece count
        static let samplePieceCount = 474
        
        /// Sample theme ID for set
        static let sampleSetThemeId = 158
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
        /// Standard duration for common animations
        static let standardDuration = Animation.normal
        
        static let quickEaseInOut = SwiftUI.Animation.easeInOut(duration: Animation.quick)
        static let normalEaseInOut = SwiftUI.Animation.easeInOut(duration: Animation.normal)
        static let slowEaseInOut = SwiftUI.Animation.easeInOut(duration: Animation.slow)
        static let tabSwitch = SwiftUI.Animation.easeInOut(duration: Animation.tabSwitchDuration)
        static let loadingPulse = SwiftUI.Animation.easeInOut(duration: Animation.long).repeatForever(autoreverses: true)
        static let springDefault = SwiftUI.Animation.spring(
            response: Animation.springResponse,
            dampingFraction: Animation.springDamping,
            blendDuration: Limits.zeroValue
        )
    }
    
    /// Common spacing values for UI layout
    enum Spacing {
        static let xs: CGFloat = 4
        static let small = UI.smallSpacing
        static let standard = UI.standardSpacing
        static let large = UI.largeSpacing
        static let xl: CGFloat = 32
    }
    
    /// Common corner radius values
    enum CornerRadius {
        static let small = UI.smallCornerRadius
        static let standard = UI.standardCornerRadius
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let button: CGFloat = 6
        static let card: CGFloat = 12
        static let thumbnail: CGFloat = 8
        static let skeleton: CGFloat = 4
    }
    
    /// Common scale values for animations
    enum Scale {
        static let pressed = VisualEffects.pressedScaleFactor
        static let selected = VisualEffects.selectedIconScale
        static let progress = VisualEffects.progressViewScale
        static let error = VisualEffects.errorIconScale
        static let small = VisualEffects.errorIconScale  // 0.8 - small scale for animations
        static let base = Limits.baseAnimationScale
    }
    
    /// Common numeric values
    enum Numbers {
        static let zeroValue = Limits.zeroValue
        static let zeroInt = Limits.zeroInt
        static let percentMultiplier = Achievements.percentageMultiplier
    }
    
    /// Common delays in nanoseconds for Task.sleep
    enum Delays {
        static let quick = Timing.quickDelay
        static let search = Timing.searchDebounceDelay
        static let haptic = Timing.hapticDelay
        static let offline = API.offlineRetryDelay
    }
    
    /// HTTP status codes
    enum HTTPStatus {
        static let success = Limits.httpSuccessCode
    }
    
    /// Common frame sizes
    enum FrameSize {
        static let thumbnail = CGSize(width: ImageSize.thumbnailWidth, height: ImageSize.thumbnailHeight)
        static let collectionIcon = CGSize(width: ImageSize.collectionIconSize, height: ImageSize.collectionIconSize)
        static let preview = CGSize(width: ImageSize.previewWidth, height: ImageSize.previewHeight)
        static let largeIcon = CGSize(width: Accessibility.largeIconSize, height: Accessibility.largeIconSize)
    }
}