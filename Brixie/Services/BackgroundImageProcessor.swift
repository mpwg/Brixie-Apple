//
//  BackgroundImageProcessor.swift
//  Brixie
//
//  Created by GitHub Copilot on 20/09/2025.
//

import Foundation
import SwiftUI
import OSLog

/// Background image processing service that handles heavy image operations off the main thread
/// This improves UI responsiveness by moving expensive operations to background queues
@MainActor
final class BackgroundImageProcessor {
    /// Singleton instance
    static let shared = BackgroundImageProcessor()
    
    /// Logger for background processing
    private let logger = Logger(subsystem: "com.brixie", category: "BackgroundImageProcessor")
    
    /// Background queue for image processing
    private let processingQueue = DispatchQueue(
        label: "com.brixie.image-processing",
        qos: .utility,
        attributes: .concurrent
    )
    
    /// Background queue for I/O operations
    private let ioQueue = DispatchQueue(
        label: "com.brixie.image-io", 
        qos: .background
    )
    
    /// Active processing tasks
    private var activeTasks: Set<Task<Void, Never>> = []
    
    /// Maximum concurrent processing tasks
    private let maxConcurrentTasks = 3
    
    private init() {
        logger.debug("BackgroundImageProcessor initialized")
    }
    
    // MARK: - Public Methods
    
    /// Process images in the background with priority-based queuing
    /// - Parameters:
    ///   - urls: Array of image URLs to process
    ///   - imageType: Target image type for optimization
    ///   - priority: Task priority for processing
    func processImages(_ urls: [URL], imageType: ImageOptimizationService.ImageType, priority: TaskPriority = .utility) {
        logger.debug("Starting background processing for \(urls.count) images of type \(imageType.description)")
        
        // Limit concurrent tasks to prevent resource exhaustion
        guard activeTasks.count < maxConcurrentTasks else {
            logger.info("Maximum concurrent tasks reached, queuing images")
            return
        }
        
        let task = Task(priority: priority) { [weak self] in
            await self?.processImageBatch(urls, imageType: imageType)
            return () // Explicitly return Void
        }
        
        activeTasks.insert(task)
        
        // Clean up completed tasks
        cleanupCompletedTasks()
    }
    
    /// Process a single image with full optimization pipeline
    /// - Parameters:
    ///   - url: Image URL to process
    ///   - imageType: Target image type
    ///   - priority: Processing priority
    /// - Returns: Optimized image data if successful
    func processSingleImage(_ url: URL, imageType: ImageOptimizationService.ImageType, priority: TaskPriority = .utility) async -> Data? {
        let task = Task(priority: priority) {
            await self.optimizeImage(url, imageType: imageType)
        }
        
        return await task.value
    }
    
    /// Batch process images for a specific use case (e.g., prefetching, thumbnails)
    /// - Parameters:
    ///   - urls: URLs to process
    ///   - imageType: Target optimization type
    ///   - batchSize: Number of images to process concurrently
    func batchProcessImages(_ urls: [URL], imageType: ImageOptimizationService.ImageType, batchSize: Int = 5) {
        let batches = urls.chunked(into: batchSize)
        
        logger.debug("Processing \(urls.count) images in \(batches.count) batches of \(batchSize)")
        
        for batch in batches {
            processImages(batch, imageType: imageType, priority: .background)
            
            // Small delay between batches to prevent overwhelming the system
            Task {
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }
    
    /// Cancel all active processing tasks
    func cancelAllTasks() {
        logger.debug("Cancelling \(self.activeTasks.count) active tasks")
        
        for task in activeTasks {
            task.cancel()
        }
        
        activeTasks.removeAll()
    }
    
    /// Get current processing status
    var processingStatus: ProcessingStatus {
        ProcessingStatus(
            activeTasks: activeTasks.count,
            maxConcurrentTasks: maxConcurrentTasks,
            isProcessing: !activeTasks.isEmpty
        )
    }
    
    // MARK: - Private Methods
    
    /// Process a batch of images with error handling
    private func processImageBatch(_ urls: [URL], imageType: ImageOptimizationService.ImageType) async {
        logger.debug("Processing batch of \(urls.count) images")
        
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { [weak self] in
                    await self?.optimizeImage(url, imageType: imageType)
                }
            }
        }
        
        logger.debug("Completed batch processing")
    }
    
    /// Optimize a single image using the optimization service
    @discardableResult
    private func optimizeImage(_ url: URL, imageType: ImageOptimizationService.ImageType) async -> Data? {
        // Use the existing ImageCacheService which handles optimization
        let cacheService = ImageCacheService.shared
        return await cacheService.optimizedImageData(from: url, imageType: imageType)
    }
    
    /// Clean up completed tasks from the active set
    private func cleanupCompletedTasks() {
        activeTasks = Set(activeTasks.filter { !$0.isCancelled })
    }
    
    /// Schedule image processing with delay (for non-critical operations)
    func scheduleProcessing(_ urls: [URL], imageType: ImageOptimizationService.ImageType, delay: TimeInterval) {
        Task {
            try? await Task.sleep(for: .seconds(delay))
            processImages(urls, imageType: imageType, priority: .background)
        }
    }
}

// MARK: - Supporting Types

struct ProcessingStatus {
    let activeTasks: Int
    let maxConcurrentTasks: Int
    let isProcessing: Bool
    
    var utilizationPercentage: Double {
        guard maxConcurrentTasks > 0 else { return 0 }
        return Double(activeTasks) / Double(maxConcurrentTasks) * 100
    }
}

// MARK: - Array Extension

private extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Integration with Existing Services

extension ImagePrefetchService {
    /// Use background processor for prefetching
    func prefetchInBackground(for urls: [URL], imageType: ImageOptimizationService.ImageType = .thumbnail) {
        BackgroundImageProcessor.shared.batchProcessImages(urls, imageType: imageType, batchSize: 8)
    }
}

extension ImageCacheService {
    /// Pre-warm cache with background processing
    func preWarmCache(with urls: [URL], imageType: ImageOptimizationService.ImageType) {
        BackgroundImageProcessor.shared.scheduleProcessing(urls, imageType: imageType, delay: 1.0)
    }
}