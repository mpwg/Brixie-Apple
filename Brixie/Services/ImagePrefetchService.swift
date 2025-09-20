//
//  ImagePrefetchService.swift
//  Brixie
//
//  Created by GitHub Copilot on 20/09/2025.
//

import Foundation
import SwiftUI
import OSLog

/// Service for prefetching images to improve scroll performance
@MainActor
final class ImagePrefetchService {
    /// Singleton instance
    static let shared = ImagePrefetchService()
    
    /// Logger for prefetch operations
    private let logger = Logger.imagePrefetch
    
    /// Image cache service for actual prefetching
    private let cacheService = ImageCacheService.shared
    
    /// Active prefetch tasks
    private var prefetchTasks: Set<Task<Void, Never>> = []
    
    /// Maximum number of concurrent prefetch operations
    private let maxConcurrentPrefetches = 10
    
    /// Prefetch priority for background operations
    private let prefetchPriority: TaskPriority = .background
    
    // MARK: - Initialization
    
    private init() {
        logger.debug("ImagePrefetchService initialized")
    }
    
    // MARK: - Public Methods
    
    /// Prefetch images for the given URLs with specified priority
    /// - Parameters:
    ///   - urls: Array of image URLs to prefetch
    ///   - imageType: Type of image optimization to apply
    ///   - priority: Task priority for prefetch operations
    func prefetchImages(for urls: [URL], imageType: ImageOptimizationService.ImageType = .thumbnail, priority: TaskPriority = .background) {
        logger.debug("Starting prefetch for \(urls.count) images of type \(imageType.description)")
        
        // Cancel existing tasks if we're starting a new prefetch batch
        cancelAllPrefetches()
        
        // Limit the number of concurrent prefetches to prevent memory issues
        let urlsToProcess = Array(urls.prefix(maxConcurrentPrefetches))
        
        for url in urlsToProcess {
            let task = Task(priority: priority) { [weak self] in
                guard let self = self else { return }
                
                // Check if already in cache before attempting to fetch
                if await self.cacheService.isImageCached(url: url, imageType: imageType) {
                    self.logger.debug("Image already cached, skipping: \(url.absoluteString)")
                    return
                }
                
                // Prefetch the image data
                _ = await self.cacheService.optimizedImageData(from: url, imageType: imageType)
                self.logger.debug("Successfully prefetched: \(url.absoluteString)")
            }
            
            prefetchTasks.insert(task)
        }
    }
    
    /// Prefetch images for LEGO sets, extracting URLs from set data
    /// - Parameters:
    ///   - sets: Array of LEGO sets to prefetch images for
    ///   - imageType: Type of image optimization to apply
    ///   - priority: Task priority for prefetch operations
    func prefetchImages(for sets: [LegoSet], imageType: ImageOptimizationService.ImageType = .thumbnail, priority: TaskPriority = .background) {
        let urls: [URL] = sets.compactMap { set in
            guard let imageURLString = set.imageURL else { return nil }
            return URL(string: imageURLString)
        }
        
        prefetchImages(for: urls, imageType: imageType, priority: priority)
    }
    
    /// Cancel all active prefetch operations
    func cancelAllPrefetches() {
        logger.debug("Cancelling \(self.prefetchTasks.count) active prefetch tasks")
        
        self.prefetchTasks.forEach { task in
            task.cancel()
        }
        self.prefetchTasks.removeAll()
    }
    
    /// Get the number of active prefetch tasks
    var activePrefetchCount: Int {
        prefetchTasks.count
    }
    
    /// Prefetch images for visible and upcoming items in a scroll view
    /// This method is designed to be called during scroll events
    /// - Parameters:
    ///   - visibleSets: Currently visible LEGO sets
    ///   - upcomingSets: Sets that will be visible soon (next page/screen)
    ///   - imageType: Type of image optimization to apply
    func prefetchForScrollView(visible visibleSets: [LegoSet], upcoming upcomingSets: [LegoSet], imageType: ImageOptimizationService.ImageType = .thumbnail) {
        // Prioritize upcoming sets for prefetch since visible ones should already be loading
        let upcomingUrls: [URL] = upcomingSets.compactMap { set in
            guard let imageURLString = set.imageURL else { return nil }
            return URL(string: imageURLString)
        }
        
        // Use higher priority for upcoming visible items
        prefetchImages(for: upcomingUrls, imageType: imageType, priority: .utility)
    }
}

// MARK: - Logger Extension

extension Logger {
    static let imagePrefetch = Logger(subsystem: "com.brixie", category: "ImagePrefetch")
}