//
//  ImageCacheService.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import Foundation
import SwiftUI
import OSLog

/// Image caching service with memory and disk storage
@MainActor
final class ImageCacheService {
    /// Singleton instance
    static let shared = ImageCacheService()
    
    /// Logger for image cache operations
    private let logger = Logger.imageCache
    
    /// Maximum cache size in bytes (50MB)
    static let maxCacheSize: Int = AppConstants.Cache.maxDiskCacheSize
    
    /// Memory cache for quick access to image data
    private let memoryCache = NSCache<NSString, NSData>()
    
    /// Memory cache for SwiftUI Images (separate for performance)
    private let imageCache = NSCache<NSString, ImageWrapper>()
    
    /// Disk cache directory URL
    private let cacheDirectory: URL
    
    /// File manager for disk operations
    private let fileManager = FileManager.default
    
    /// URLSession for downloading images
    private let urlSession = URLSession.shared
    
    /// Current cache size in bytes
    private(set) var currentCacheSize: Int = 0
    
    /// Active download tasks
    private var downloadTasks: [URL: Task<Data?, Never>] = [:]
    
    /// Queue for disk operations
    private let diskQueue = DispatchQueue(label: "com.brixie.image-cache", qos: .utility)
    
    // MARK: - Initialization
    
    init() {
        logger.debug("🎯 ImageCacheService initializing...")
        
        // Set up cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        logger.debug("📁 Cache directory path: \(self.cacheDirectory.path)")
        
        // Create cache directory if needed
        createCacheDirectoryIfNeeded()
        
        // Configure memory caches
        memoryCache.totalCostLimit = AppConstants.Cache.memoryDataCacheLimit
        memoryCache.countLimit = AppConstants.Cache.maxDataObjectsInMemory // Max data objects in memory
        
        imageCache.totalCostLimit = AppConstants.Cache.memoryImageCacheLimit
        imageCache.countLimit = AppConstants.Cache.maxImagesInMemory
        
        logger.info("⚙️ Memory caches configured: data cache \(AppConstants.Cache.memoryDataCacheLimit / (1_024 * 1_024))MB/\(AppConstants.Cache.maxDataObjectsInMemory) items, image cache \(AppConstants.Cache.memoryImageCacheLimit / (1_024 * 1_024))MB/\(AppConstants.Cache.maxImagesInMemory) items")
        
        // Calculate initial disk cache size
        calculateDiskCacheSize()
        
        // Clean up cache on memory warnings if available
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.logger.warning("⚠️ Memory warning received - clearing memory cache")
                self?.handleMemoryWarning()
            }
        }
        logger.debug("📱 Memory warning observer registered")
        #endif
        
        logger.debug("✅ ImageCacheService initialized successfully")
    }
    
    // MARK: - SwiftUI Image Caching
    
    /// Get cached SwiftUI Image if available
    func getCachedImage(from url: URL) async -> Image? {
        let cacheKey = NSString(string: url.absoluteString)
        let cachedImage = imageCache.object(forKey: cacheKey)?.image
        
        if cachedImage != nil {
            logger.cache("GET", key: url.lastPathComponent, hit: true)
        } else {
            logger.cache("GET", key: url.lastPathComponent, hit: false)
        }
        
        return cachedImage
    }
    
    /// Cache a SwiftUI Image for future use
    func cacheImage(_ image: Image, for url: URL) async {
        let cacheKey = NSString(string: url.absoluteString)
        imageCache.setObject(ImageWrapper(image: image), forKey: cacheKey)
        logger.cache("STORE", key: url.lastPathComponent)
    }
    
    // MARK: - Public Methods
    
    /// Get optimized image data from cache or download and optimize if needed
    func optimizedImageData(
        from url: URL, 
        imageType: ImageOptimizationService.ImageType = .medium
    ) async -> Data? {
        logger.entering(parameters: ["url": url.lastPathComponent, "type": "\(imageType)"])
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let optimizationService = ImageOptimizationService.shared
        let cacheKey = optimizationService.cacheKey(for: url, imageType: imageType)
        let memoryCacheKey = NSString(string: cacheKey)
        
        // Check memory cache for optimized image
        if let cachedData = memoryCache.object(forKey: memoryCacheKey) as Data? {
            logger.cache("MEMORY_OPT", key: url.lastPathComponent, hit: true)
            logger.debug("🎯 Memory cache hit for optimized \(url.lastPathComponent) (\(cachedData.count) bytes)")
            logger.exitWith(result: "memory cache hit (optimized) - \(cachedData.count) bytes")
            return cachedData
        }
        
        logger.cache("MEMORY_OPT", key: url.lastPathComponent, hit: false)
        
        // Check disk cache for optimized image
        if let optimizedData = await loadOptimizedImageFromDisk(url: url, imageType: imageType) {
            logger.cache("DISK_OPT", key: url.lastPathComponent, hit: true)
            logger.debug("💾 Disk cache hit for optimized \(url.lastPathComponent) (\(optimizedData.count) bytes)")
            
            // Store in memory cache
            memoryCache.setObject(optimizedData as NSData, forKey: memoryCacheKey, cost: optimizedData.count)
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.debug("⏱️ Optimized disk cache retrieval took \(duration, format: .fixed(precision: 3))s")
            logger.exitWith(result: "disk cache hit (optimized) - \(optimizedData.count) bytes")
            return optimizedData
        }
        
        logger.cache("DISK_OPT", key: url.lastPathComponent, hit: false)
        
        // Get original image data (this will download if needed)
        guard let originalData = await imageData(from: url) else {
            logger.warning("⚠️ Failed to get original image data for optimization")
            logger.exitWith(result: "failed - no original data")
            return nil
        }
        
        // Optimize the image
        logger.debug("🔄 Optimizing image \(url.lastPathComponent) for \(imageType)")
        guard let optimizedData = await optimizationService.optimizeImage(
            data: originalData,
            for: imageType
        ) else {
            logger.warning("⚠️ Image optimization failed, using original data")
            logger.exitWith(result: "optimization failed - using original")
            return originalData
        }
        
        // Cache the optimized data
        await storeOptimizedImageToDisk(data: optimizedData, url: url, imageType: imageType)
        memoryCache.setObject(optimizedData as NSData, forKey: memoryCacheKey, cost: optimizedData.count)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("📥 Optimized image request completed for \(url.lastPathComponent) in \(duration, format: .fixed(precision: 3))s (\(optimizedData.count) bytes)")
        logger.exitWith(result: "optimization complete - \(optimizedData.count) bytes")
        
        return optimizedData
    }
    
    /// Get image data from cache or download if needed (legacy method)
    func imageData(from url: URL) async -> Data? {
        logger.entering(parameters: ["url": url.lastPathComponent])
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Check memory cache first
        let cacheKey = NSString(string: url.absoluteString)
        if let cachedData = memoryCache.object(forKey: cacheKey) as Data? {
            logger.cache("MEMORY", key: url.lastPathComponent, hit: true)
            logger.debug("🎯 Memory cache hit for \(url.lastPathComponent) (\(cachedData.count) bytes)")
            logger.exitWith(result: "memory cache hit - \(cachedData.count) bytes")
            return cachedData
        }
        
        logger.cache("MEMORY", key: url.lastPathComponent, hit: false)
        
        // Check if download is already in progress
        if let existingTask = downloadTasks[url] {
            logger.debug("⏳ Download already in progress for \(url.lastPathComponent)")
            let data = await existingTask.value
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.debug("⏱️ Waited for existing download \(duration, format: .fixed(precision: 3))s")
            logger.exitWith(result: "awaited existing download - \(data?.count ?? 0) bytes")
            return data
        }
        
        // Check disk cache
        if let diskData = await loadImageDataFromDisk(url: url) {
            logger.cache("DISK", key: url.lastPathComponent, hit: true)
            logger.debug("💾 Disk cache hit for \(url.lastPathComponent) (\(diskData.count) bytes)")
            
            // Store in memory cache for quick access
            memoryCache.setObject(diskData as NSData, forKey: cacheKey, cost: diskData.count)
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.debug("⏱️ Disk cache retrieval took \(duration, format: .fixed(precision: 3))s")
            logger.exitWith(result: "disk cache hit - \(diskData.count) bytes")
            return diskData
        }
        
        logger.cache("DISK", key: url.lastPathComponent, hit: false)
        
        // Download image
        logger.debug("🌐 Starting download for \(url.lastPathComponent)")
        let downloadTask = Task<Data?, Never> {
            await downloadImageData(from: url)
        }
        
        downloadTasks[url] = downloadTask
        let data = await downloadTask.value
        downloadTasks.removeValue(forKey: url)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("📥 Image data request completed for \(url.lastPathComponent) in \(duration, format: .fixed(precision: 3))s (\(data?.count ?? 0) bytes)")
        logger.exitWith(result: "download complete - \(data?.count ?? 0) bytes")
        
        return data
    }
    
    /// Preload image into cache without returning it
    func preloadImage(from url: URL) {
        logger.debug("⚡ Preloading image: \(url.lastPathComponent)")
        Task {
            let data = await imageData(from: url)
            if data != nil {
                logger.debug("✅ Preload completed for \(url.lastPathComponent)")
            } else {
                logger.warning("⚠️ Preload failed for \(url.lastPathComponent)")
            }
        }
    }
    
    /// Clear all caches
    func clearAllCaches() {
        logger.info("🧹 Clearing all caches (memory and disk)")
        clearMemoryCache()
        clearDiskCache()
        logger.userAction("cleared_all_caches")
    }
    
    /// Clear memory cache to free up memory
    func clearMemoryCache() {
        let previousDataCount = memoryCache.name.isEmpty ? 0 : memoryCache.totalCostLimit
        let previousImageCount = imageCache.name.isEmpty ? 0 : imageCache.totalCostLimit
        
        memoryCache.removeAllObjects()
        imageCache.removeAllObjects()
        
        logger.info("🗑️ Memory cache cleared (data: \(ByteCountFormatter.string(fromByteCount: Int64(previousDataCount), countStyle: .memory)), images: \(ByteCountFormatter.string(fromByteCount: Int64(previousImageCount), countStyle: .memory)))")
        logger.userAction("cleared_memory_cache")
    }
    
    /// Handle memory warning by clearing both memory caches but keeping disk cache
    @MainActor
    private func handleMemoryWarning() {
        memoryCache.removeAllObjects()
        imageCache.removeAllObjects()
        logger.warning("⚠️ Memory caches cleared due to memory pressure - disk cache preserved")
    }
    
    /// Clear disk cache
    func clearDiskCache() {
        logger.info("🗑️ Starting disk cache cleanup")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        Task {
            let cacheDir = cacheDirectory
            
            await withCheckedContinuation { continuation in
                diskQueue.async { [weak self] in
                    guard let self = self else {
                        continuation.resume()
                        return
                    }
                    
                    var filesDeleted = 0
                    var bytesFreed = 0
                    
                    do {
                        let contents = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.fileSizeKey])
                        for url in contents {
                            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                            bytesFreed += resourceValues.fileSize ?? 0
                            try FileManager.default.removeItem(at: url)
                            filesDeleted += 1
                        }
                        
                        Task { @MainActor in
                            self.currentCacheSize = 0
                            let duration = CFAbsoluteTimeGetCurrent() - startTime
                            self.logger.info("✅ Disk cache cleared: \(filesDeleted) files, \(ByteCountFormatter.string(fromByteCount: Int64(bytesFreed), countStyle: .file)) freed in \(duration, format: .fixed(precision: 3))s")
                            self.logger.userAction("cleared_disk_cache", context: ["filesDeleted": filesDeleted, "bytesFreed": bytesFreed])
                        }
                    } catch {
                        Task { @MainActor in
                            let duration = CFAbsoluteTimeGetCurrent() - startTime
                            self.logger.error("❌ Failed to clear disk cache after \(duration, format: .fixed(precision: 3))s: \(error.localizedDescription)")
                        }
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    /// Clean up old cache files to maintain size limit
    func cleanupCacheIfNeeded() {
        guard currentCacheSize > Self.maxCacheSize else {
            logger.debug("✅ Cache size within limits: \(self.formattedCacheSize) / \(ByteCountFormatter.string(fromByteCount: Int64(Self.maxCacheSize), countStyle: .file))")
            return
        }
        
        logger.warning("⚠️ Cache size exceeded limit: \(self.formattedCacheSize) / \(ByteCountFormatter.string(fromByteCount: Int64(Self.maxCacheSize), countStyle: .file)) - starting cleanup")
        
        Task {
            await performCacheCleanup()
        }
    }
    
    // MARK: - Private Methods
    
    /// Create cache directory if it doesn't exist
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
                logger.info("📁 Created cache directory: \(self.cacheDirectory.path)")
            } catch {
                logger.error("❌ Failed to create cache directory: \(error.localizedDescription)")
            }
        } else {
            logger.debug("📁 Cache directory already exists: \(self.cacheDirectory.path)")
        }
    }
    
    /// Download image data from URL
    private func downloadImageData(from url: URL) async -> Data? {
        logger.entering(parameters: ["url": url.lastPathComponent])
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            logger.apiCall(url.absoluteString)
            let (data, response) = try await urlSession.data(from: url)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == AppConstants.HTTPStatus.success else {
                logger.error("❌ Invalid response for image \(url.lastPathComponent): \(response)")
                logger.exitWith(result: "invalid response")
                return nil
            }
            
            logger.apiCall(url.absoluteString, duration: duration)
            logger.info("📥 Downloaded image \(url.lastPathComponent): \(data.count) bytes in \(duration, format: .fixed(precision: 3))s")
            
            // Store in memory cache
            let cacheKey = NSString(string: url.absoluteString)
            memoryCache.setObject(data as NSData, forKey: cacheKey, cost: data.count)
            logger.cache("STORE_MEMORY", key: url.lastPathComponent)
            
            // Store in disk cache
            await saveImageDataToDisk(data: data, url: url)
            
            logger.exitWith(result: "\(data.count) bytes downloaded and cached")
            return data
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            logger.error("❌ Failed to download image \(url.lastPathComponent) after \(duration, format: .fixed(precision: 3))s: \(error.localizedDescription)")
            logger.exitWith(result: "download failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Load image data from disk cache
    private func loadImageDataFromDisk(url: URL) async -> Data? {
        let fileName = Self.fileName(for: url)
        let cacheDir = cacheDirectory
        
        return await withCheckedContinuation { continuation in
            diskQueue.async { [weak self] in
                let fileURL = cacheDir.appendingPathComponent(fileName)
                
                guard let data = try? Data(contentsOf: fileURL) else {
                    Task { @MainActor in
                        self?.logger.debug("💾 No disk cache found for \(fileName)")
                    }
                    continuation.resume(returning: nil)
                    return
                }
                
                Task { @MainActor in
                    self?.logger.debug("💾 Loaded \(data.count) bytes from disk cache for \(fileName)")
                }
                
                continuation.resume(returning: data)
            }
        }
    }
    
    /// Save image data to disk cache
    private func saveImageDataToDisk(data: Data, url: URL) async {
        let fileName = Self.fileName(for: url)
        let cacheDir = cacheDirectory
        
        await withCheckedContinuation { continuation in
            diskQueue.async { [weak self] in
                let fileURL = cacheDir.appendingPathComponent(fileName)
                
                do {
                    try data.write(to: fileURL)
                    
                    Task { @MainActor in
                        guard let self = self else { return }
                        self.currentCacheSize += data.count
                        self.logger.cache("STORE_DISK", key: fileName)
                        self.logger.debug("💾 Saved \(data.count) bytes to disk cache: \(fileName)")
                        self.cleanupCacheIfNeeded()
                    }
                } catch {
                    Task { @MainActor in
                        self?.logger.error("❌ Failed to save image \(fileName) to disk: \(error.localizedDescription)")
                    }
                }
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - Optimized Disk Cache Methods
    
    /// Load optimized image data from disk cache
    private func loadOptimizedImageFromDisk(
        url: URL, 
        imageType: ImageOptimizationService.ImageType
    ) async -> Data? {
        let optimizationService = ImageOptimizationService.shared
        let cacheKey = optimizationService.cacheKey(for: url, imageType: imageType)
        let cacheDir = cacheDirectory
        
        return await withCheckedContinuation { continuation in
            diskQueue.async { [weak self] in
                let fileURL = cacheDir.appendingPathComponent(cacheKey)
                
                guard let data = try? Data(contentsOf: fileURL) else {
                    Task { @MainActor in
                        self?.logger.debug("💾 No optimized disk cache found for \(cacheKey)")
                    }
                    continuation.resume(returning: nil)
                    return
                }
                
                Task { @MainActor in
                    self?.logger.debug("💾 Loaded \(data.count) bytes from optimized disk cache for \(cacheKey)")
                }
                
                continuation.resume(returning: data)
            }
        }
    }
    
    /// Save optimized image data to disk cache
    private func storeOptimizedImageToDisk(
        data: Data, 
        url: URL, 
        imageType: ImageOptimizationService.ImageType
    ) async {
        let optimizationService = ImageOptimizationService.shared
        let cacheKey = optimizationService.cacheKey(for: url, imageType: imageType)
        let cacheDir = cacheDirectory
        let typeDirName = imageType.directoryName  // Access outside the closure
        
        await withCheckedContinuation { continuation in
            diskQueue.async { [weak self] in
                // Create subdirectory for image type if needed
                let typeDir = cacheDir.appendingPathComponent(typeDirName)
                if !FileManager.default.fileExists(atPath: typeDir.path) {
                    try? FileManager.default.createDirectory(
                        at: typeDir,
                        withIntermediateDirectories: true,
                        attributes: nil
                    )
                }
                
                let fileURL = cacheDir.appendingPathComponent(cacheKey)
                
                do {
                    try data.write(to: fileURL)
                    
                    Task { @MainActor in
                        guard let self = self else { return }
                        self.currentCacheSize += data.count
                        self.logger.cache("STORE_DISK_OPT", key: cacheKey)
                        self.logger.debug("💾 Saved \(data.count) bytes to optimized disk cache: \(cacheKey)")
                        self.cleanupCacheIfNeeded()
                    }
                } catch {
                    Task { @MainActor in
                        self?.logger.error("❌ Failed to save optimized image \(cacheKey) to disk: \(error.localizedDescription)")
                    }
                }
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Generate filename for cached image
    nonisolated private static func fileName(for url: URL) -> String {
        let hash = url.absoluteString.hash
        let pathExtension = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
        return "\(abs(hash)).\(pathExtension)"
    }
    
    /// Calculate current disk cache size
    private func calculateDiskCacheSize() {
        let cacheDir = cacheDirectory
        
        Task {
            await withCheckedContinuation { continuation in
                diskQueue.async { [weak self] in
                    var totalSize = 0
                    var fileCount = 0
                    
                    do {
                        let contents = try FileManager.default.contentsOfDirectory(
                            at: cacheDir,
                            includingPropertiesForKeys: [.fileSizeKey]
                        )
                        
                        fileCount = contents.count
                        
                        for url in contents {
                            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                            totalSize += resourceValues.fileSize ?? 0
                        }
                        
                        Task { @MainActor in
                            guard let self = self else { 
                                continuation.resume()
                                return 
                            }
                            self.currentCacheSize = totalSize
                            self.logger.info("📊 Initial cache size calculated: \(ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)) in \(fileCount) files")
                            continuation.resume()
                        }
                    } catch {
                        Task { @MainActor in
                            self?.logger.error("❌ Failed to calculate cache size: \(error.localizedDescription)")
                            continuation.resume()
                        }
                    }
                }
            }
        }
    }
    
    /// Perform cache cleanup to stay under size limit
    private func performCacheCleanup() async {
        logger.info("🧹 Starting cache cleanup to reduce size from \(self.formattedCacheSize)")
        let startTime = CFAbsoluteTimeGetCurrent()
        let cacheDir = cacheDirectory
        let maxSize = Self.maxCacheSize
        
        await withCheckedContinuation { continuation in
            diskQueue.async { [weak self] in
                do {
                    let contents = try FileManager.default.contentsOfDirectory(
                        at: cacheDir,
                        includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
                    )
                    
                    // Sort by modification date (oldest first)
                    let sortedContents = contents.sorted { url1, url2 in
                        let date1 = try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                        let date2 = try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                        
                        return (date1 ?? Date.distantPast) < (date2 ?? Date.distantPast)
                    }
                    
                    // Get current size from main actor
                    Task { @MainActor in
                        guard let self = self else { 
                            continuation.resume()
                            return 
                        }
                        let currentSize = self.currentCacheSize
                        let cleanupThreshold = AppConstants.Limits.cacheCleanupThreshold
                        
                        // Continue cleanup on background queue
                        Task.detached {
                            var totalSize = currentSize
                            var bytesFreed = 0  // Moved into detached scope
                            var filesDeleted = 0  // Moved into detached scope
                            let targetSize = Int(Double(maxSize) * cleanupThreshold) // Clean to 80% of limit
                            
                            for url in sortedContents {
                                guard totalSize > targetSize else { break }
                                
                                do {
                                    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                                    let fileSize = resourceValues.fileSize ?? 0
                                    
                                    try FileManager.default.removeItem(at: url)
                                    totalSize -= fileSize
                                    bytesFreed += fileSize
                                    filesDeleted += 1
                                } catch {
                                    // Skip this file if we can't delete it
                                    continue
                                }
                            }
                            
                            // Update size on main actor
                            await MainActor.run {
                                self.currentCacheSize = totalSize
                                let duration = CFAbsoluteTimeGetCurrent() - startTime
                                self.logger.info("✅ Cache cleanup completed: deleted \(filesDeleted) files, freed \(ByteCountFormatter.string(fromByteCount: Int64(bytesFreed), countStyle: .file)) in \(duration, format: .fixed(precision: 3))s")
                                self.logger.debug("📊 New cache size: \(self.formattedCacheSize) (\(self.cacheUsagePercentage * 100, format: .fixed(precision: 1))% of limit)")
                            }
                            
                            continuation.resume()
                        }
                    }
                } catch {
                    Task { @MainActor in
                        let duration = CFAbsoluteTimeGetCurrent() - startTime
                        self?.logger.error("❌ Cache cleanup failed after \(duration, format: .fixed(precision: 3))s: \(error.localizedDescription)")
                    }
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Cache Statistics

extension ImageCacheService {
    /// Formatted cache size string
    var formattedCacheSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(currentCacheSize), countStyle: .file)
    }
    
    /// Cache usage percentage
    var cacheUsagePercentage: Double {
        Double(currentCacheSize) / Double(Self.maxCacheSize)
    }
    
    /// Number of files in disk cache
    var diskCacheFileCount: Int {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            return contents.count
        } catch {
            return 0
        }
    }
}

// MARK: - Helper Classes

/// Wrapper class for SwiftUI Image to enable NSCache storage
private final class ImageWrapper {
    let image: Image
    
    init(image: Image) {
        self.image = image
    }
}
