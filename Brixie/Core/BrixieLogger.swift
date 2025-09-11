//
//  BrixieLogger.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation
import OSLog

/// Centralized logging utility for Brixie app using OSLog
@MainActor
final class BrixieLogger {
    
    // MARK: - Subsystem
    private static let subsystem = "com.brixie.app"
    
    // MARK: - Categories
    enum Category: String, CaseIterable {
        case ui = "ui"
        case network = "network"
        case persistence = "persistence"
        case cache = "cache"
        case general = "general"
        
        var logger: Logger {
            Logger(subsystem: BrixieLogger.subsystem, category: self.rawValue)
        }
    }
    
    // MARK: - Static Methods
    
    /// Log debug information
    static func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        category.logger.debug("[\(sourceLocation(file: file, function: function, line: line))] \(message)")
    }
    
    /// Log informational messages
    static func info(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        category.logger.info("[\(sourceLocation(file: file, function: function, line: line))] \(message)")
    }
    
    /// Log warning messages
    static func warning(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        category.logger.warning("[\(sourceLocation(file: file, function: function, line: line))] \(message)")
    }
    
    /// Log error messages
    static func error(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        category.logger.error("[\(sourceLocation(file: file, function: function, line: line))] \(message)")
    }
    
    /// Log critical errors/faults
    static func fault(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        category.logger.fault("[\(sourceLocation(file: file, function: function, line: line))] \(message)")
    }
    
    // MARK: - Error Logging Convenience Methods
    
    /// Log error with Error object
    static func error(_ error: Error, message: String? = nil, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        let errorMessage = message ?? "Error occurred"
        let fullMessage = "\(errorMessage): \(error.localizedDescription)"
        BrixieLogger.error(fullMessage, category: category, file: file, function: function, line: line)
    }
    
    /// Log network-related errors
    static func networkError(_ error: Error, message: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        BrixieLogger.error(error, message: message, category: .network, file: file, function: function, line: line)
    }
    
    /// Log persistence-related errors
    static func persistenceError(_ error: Error, message: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        BrixieLogger.error(error, message: message, category: .persistence, file: file, function: function, line: line)
    }
    
    /// Log cache-related errors
    static func cacheError(_ error: Error, message: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        BrixieLogger.error(error, message: message, category: .cache, file: file, function: function, line: line)
    }
    
    /// Log UI-related errors
    static func uiError(_ error: Error, message: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        BrixieLogger.error(error, message: message, category: .ui, file: file, function: function, line: line)
    }
    
    // MARK: - Private Helpers
    
    private static func sourceLocation(file: String, function: String, line: Int) -> String {
        let filename = (file as NSString).lastPathComponent
        return "\(filename):\(function):\(line)"
    }
}

// MARK: - Global Convenience Functions

/// Global convenience function for debug logging
func logDebug(_ message: String, category: BrixieLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    BrixieLogger.debug(message, category: category, file: file, function: function, line: line)
}

/// Global convenience function for info logging
func logInfo(_ message: String, category: BrixieLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    BrixieLogger.info(message, category: category, file: file, function: function, line: line)
}

/// Global convenience function for warning logging
func logWarning(_ message: String, category: BrixieLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    BrixieLogger.warning(message, category: category, file: file, function: function, line: line)
}

/// Global convenience function for error logging
func logError(_ message: String, category: BrixieLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    BrixieLogger.error(message, category: category, file: file, function: function, line: line)
}

/// Global convenience function for error with Error object
func logError(_ error: Error, message: String? = nil, category: BrixieLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    BrixieLogger.error(error, message: message, category: category, file: file, function: function, line: line)
}