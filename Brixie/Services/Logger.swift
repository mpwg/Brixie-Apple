//
//  Logger.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import OSLog

/// Centralized logging configuration for Brixie app
/// Based on best practices from https://www.avanderlee.com/debugging/oslog-unified-logging/
extension Logger {
    /// Using bundle identifier as a unique identifier for the subsystem
    private static var subsystem = Bundle.main.bundleIdentifier!


    static let imageOptimization = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.brixie",
        category: "ImageOptimization"
    )
    // MARK: - Service Loggers
    
    /// All logs related to Theme operations (API, caching, hierarchy)
    static let themeService = Logger(subsystem: subsystem, category: "theme-service")
    
    /// All logs related to LEGO set operations (API, caching, search)
    static let legoSetService = Logger(subsystem: subsystem, category: "legoset-service")
    
    /// All logs related to image caching and loading
    static let imageCache = Logger(subsystem: subsystem, category: "image-cache")
    
    /// All logs related to collection management (wishlist, owned sets)
    static let collection = Logger(subsystem: subsystem, category: "collection")
    
    /// All logs related to offline mode and synchronization
    static let offline = Logger(subsystem: subsystem, category: "offline")
    
    /// All logs related to search operations and history
    static let search = Logger(subsystem: subsystem, category: "search")

    // MARK: - UI Loggers
    
    /// Logs for view lifecycle events (appeared, disappeared, etc.)
    static let viewCycle = Logger(subsystem: subsystem, category: "view-cycle")
    
    /// All logs related to navigation and user interaction
    static let navigation = Logger(subsystem: subsystem, category: "navigation")
    
    /// All logs related to accessibility and user experience
    static let accessibility = Logger(subsystem: subsystem, category: "accessibility")

    // MARK: - Data Loggers
    
    /// All logs related to SwiftData operations (persistence, queries, etc.)
    static let database = Logger(subsystem: subsystem, category: "database")
    
    /// All logs related to API communication and networking
    static let network = Logger(subsystem: subsystem, category: "network")
    
    /// All logs related to configuration and app setup
    static let configuration = Logger(subsystem: subsystem, category: "configuration")

    // MARK: - Error and Performance Loggers
    
    /// All logs related to error handling and recovery
    static let error = Logger(subsystem: subsystem, category: "error")
    
    /// All logs related to performance monitoring and optimization
    static let performance = Logger(subsystem: subsystem, category: "performance")
}

// MARK: - Logging Helpers

extension Logger {
    /// Log a function entry with optional parameters
    func entering(_ function: String = #function, parameters: [String: Any] = [:]) {
        if parameters.isEmpty {
            self.debug("⏭️ Entering \(function)")
        } else {
            let paramString = parameters.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            self.debug("⏭️ Entering \(function) with parameters: \(paramString)")
        }
    }
    
    /// Log exit of a function
    func exitWith(function: String = #function) {
        self.debug("⏪ Exiting \(function)")
    }

    /// Log exit of a function with result
    func exitWith<T>(function: String = #function, result: T) {
        self.debug("⏪ Exiting \(function) with result: \(String(describing: result))")
    }
    
    /// Log an API call with timing
    func apiCall(_ endpoint: String, duration: TimeInterval? = nil) {
        if let duration = duration {
            self.info("🌐 API call to \(endpoint) completed in \(duration, format: .fixed(precision: 3))s")
        } else {
            self.info("🌐 Starting API call to \(endpoint)")
        }
    }
    
    /// Log cache operations
    func cache(_ operation: String, key: String, hit: Bool? = nil) {
        if let hit = hit {
            let status = hit ? "HIT" : "MISS"
            self.debug("📦 Cache \(operation) for '\(key)' - \(status)")
        } else {
            self.debug("📦 Cache \(operation) for '\(key)'")
        }
    }
    
    /// Log user interactions
    func userAction(_ action: String, context: [String: Any] = [:]) {
        if context.isEmpty {
            self.info("👤 User action: \(action)")
        } else {
            let contextString = context.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            self.info("👤 User action: \(action) - \(contextString)")
        }
    }
}