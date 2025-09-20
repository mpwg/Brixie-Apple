//
//  PerformanceTestUtils.swift
//  Brixie
//
//  Created by GitHub Copilot on 20/09/2025.
//

import Foundation
import SwiftUI
import OSLog

/// Performance testing and monitoring utilities
/// Provides methods for measuring execution time and tracking performance metrics
@MainActor
final class PerformanceTestUtils {
    /// Shared instance
    static let shared = PerformanceTestUtils()
    
    /// Logger for performance measurements
    private let logger = Logger(subsystem: "com.brixie", category: "Performance")
    
    private init() {}
    
    /// Measure the execution time of an operation
    /// - Parameters:
    ///   - operation: Description of the operation being measured
    ///   - work: The work to be performed and measured
    /// - Returns: The result of the work
    func measureTime<T>(operation: String, _ work: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            if elapsed > 16.67 { // Longer than one frame (16.67ms at 60 FPS)
                logger.warning("⚠️ \(operation) took \(elapsed, format: .fixed(precision: 2))ms")
            } else {
                logger.debug("✅ \(operation) completed in \(elapsed, format: .fixed(precision: 2))ms")
            }
        }
        return try work()
    }
    
    /// Measure the execution time of an async operation
    /// - Parameters:
    ///   - operation: Description of the operation being measured
    ///   - work: The async work to be performed and measured
    /// - Returns: The result of the work
    func measureTimeAsync<T>(operation: String, _ work: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            if elapsed > 16.67 { // Longer than one frame
                logger.warning("⚠️ \(operation) took \(elapsed, format: .fixed(precision: 2))ms")
            } else {
                logger.debug("✅ \(operation) completed in \(elapsed, format: .fixed(precision: 2))ms")
            }
        }
        return try await work()
    }
    
    /// Track image loading performance
    /// - Parameters:
    ///   - url: The image URL being loaded
    ///   - imageSize: Size of the loaded image data
    ///   - fromCache: Whether the image was loaded from cache
    ///   - duration: Loading duration in seconds
    func trackImageLoadPerformance(url: URL, imageSize: Int, fromCache: Bool, duration: TimeInterval) {
        let durationMs = duration * 1000
        let sizeMB = Double(imageSize) / (1024 * 1024)
        let source = fromCache ? "cache" : "network"
        
        if fromCache && durationMs > 50 {
            logger.warning("🖼️ Slow cache load: \(url.lastPathComponent) (\(sizeMB, format: .fixed(precision: 2))MB) took \(durationMs, format: .fixed(precision: 1))ms")
        } else if !fromCache && durationMs > 500 {
            logger.warning("🌐 Slow network load: \(url.lastPathComponent) (\(sizeMB, format: .fixed(precision: 2))MB) took \(durationMs, format: .fixed(precision: 1))ms")
        } else {
            logger.info("🖼️ Image loaded from \(source): \(url.lastPathComponent) (\(sizeMB, format: .fixed(precision: 2))MB) in \(durationMs, format: .fixed(precision: 1))ms")
        }
    }
    
    /// Track SwiftData query performance
    /// - Parameters:
    ///   - queryDescription: Description of the query
    ///   - resultCount: Number of results returned
    ///   - duration: Query duration in seconds
    func trackQueryPerformance(queryDescription: String, resultCount: Int, duration: TimeInterval) {
        let durationMs = duration * 1000
        
        if durationMs > 100 { // Queries should be fast
            logger.warning("🗄️ Slow query: \(queryDescription) returned \(resultCount) items in \(durationMs, format: .fixed(precision: 1))ms")
        } else {
            logger.debug("🗄️ Query: \(queryDescription) returned \(resultCount) items in \(durationMs, format: .fixed(precision: 1))ms")
        }
    }
    
    /// Track navigation performance
    /// - Parameters:
    ///   - from: Source view
    ///   - to: Destination view
    ///   - duration: Navigation duration in seconds
    func trackNavigationPerformance(from: String, to: String, duration: TimeInterval) {
        let durationMs = duration * 1000
        
        if durationMs > 250 { // Navigation should be fast
            logger.warning("🧭 Slow navigation: \(from) → \(to) took \(durationMs, format: .fixed(precision: 1))ms")
        } else {
            logger.debug("🧭 Navigation: \(from) → \(to) in \(durationMs, format: .fixed(precision: 1))ms")
        }
    }
    
    /// Log memory usage at a specific point
    /// - Parameter context: Description of where this measurement is taken
    func logMemoryUsage(context: String) {
        // Memory tracking disabled for now - keeping for future use
        logger.debug("🧠 Performance tracking at \(context)")
    }
    
    /// Performance benchmark for comparing implementations
    /// - Parameters:
    ///   - name: Name of the benchmark
    ///   - iterations: Number of iterations to run
    ///   - work: Work to be benchmarked
    /// - Returns: Average execution time in milliseconds
    func benchmark(name: String, iterations: Int = 10, work: () throws -> Void) rethrows -> Double {
        var totalTime: CFAbsoluteTime = 0
        
        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            try work()
            totalTime += CFAbsoluteTimeGetCurrent() - start
        }
        
        let averageTimeMs = (totalTime / Double(iterations)) * 1000
        logger.info("📊 Benchmark '\(name)': \(averageTimeMs, format: .fixed(precision: 2))ms average over \(iterations) iterations")
        
        return averageTimeMs
    }
}

// MARK: - Performance Thresholds

extension PerformanceTestUtils {
    /// Performance thresholds based on the optimization guide
    enum PerformanceThresholds {
        /// Maximum acceptable launch time (1 second)
        static let maxLaunchTime: TimeInterval = 1.0
        
        /// Maximum acceptable cached image load time (50ms)
        static let maxCachedImageLoad: TimeInterval = 0.05
        
        /// Maximum acceptable network image load time (500ms)
        static let maxNetworkImageLoad: TimeInterval = 0.5
        
        /// Maximum acceptable navigation time (250ms)
        static let maxNavigationTime: TimeInterval = 0.25
        
        /// Maximum acceptable memory usage (150MB)
        static let maxMemoryUsageMB: Double = 150.0
        
        /// Minimum acceptable frame rate (60 FPS)
        static let minFrameRate: Double = 60.0
        
        /// Frame time threshold (16.67ms for 60 FPS)
        static let frameTimeThreshold: TimeInterval = 1.0 / 60.0
    }
}

// MARK: - View Extension for Easy Performance Tracking

extension View {
    /// Add performance tracking to a view
    func trackPerformance(context: String) -> some View {
        self.onAppear {
            PerformanceTestUtils.shared.logMemoryUsage(context: "\(context) - onAppear")
        }
        .onDisappear {
            PerformanceTestUtils.shared.logMemoryUsage(context: "\(context) - onDisappear")
        }
    }
}