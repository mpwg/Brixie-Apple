//
//  ImageCacheService.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import Foundation
import SwiftUI

/// Image caching service with memory and disk storage
@Observable @MainActor
final class ImageCacheService {
    /// Singleton instance
    static let shared = ImageCacheService()
    
    /// Maximum cache size in bytes (50MB)
    static let maxCacheSize: Int = 50 * 1_024 * 1_024
    
    /// Memory cache for quick access to image data
    private let memoryCache = NSCache<NSString, NSData>()
    
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
        // Set up cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        
        // Create cache directory if needed
        createCacheDirectoryIfNeeded()
        
        // Configure memory cache
        memoryCache.totalCostLimit = 20 * 1_024 * 1_024 // 20MB memory limit
        memoryCache.countLimit = 100 // Max 100 images in memory
        
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
                self?.clearMemoryCache()
            }
        }
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Get image data from cache or download if needed
    func imageData(from url: URL) async -> Data? {
        // Check memory cache first
        let cacheKey = NSString(string: url.absoluteString)
        if let cachedData = memoryCache.object(forKey: cacheKey) as Data? {
            return cachedData
        }
        
        // Check if download is already in progress
        if let existingTask = downloadTasks[url] {
            return await existingTask.value
        }
        
        // Check disk cache
        if let diskData = await loadImageDataFromDisk(url: url) {
            // Store in memory cache for quick access
            memoryCache.setObject(diskData as NSData, forKey: cacheKey)
            return diskData
        }
        
        // Download image
        let downloadTask = Task<Data?, Never> {
            await downloadImageData(from: url)
        }
        
        downloadTasks[url] = downloadTask
        let data = await downloadTask.value
        downloadTasks.removeValue(forKey: url)
        
        return data
    }
    
    /// Preload image into cache without returning it
    func preloadImage(from url: URL) {
        Task {
            _ = await imageData(from: url)
        }
    }
    
    /// Clear all caches
    func clearAllCaches() {
        clearMemoryCache()
        clearDiskCache()
    }
    
    /// Clear memory cache only
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    /// Clear disk cache
    func clearDiskCache() {
        Task {
            let cacheDir = cacheDirectory
            
            await withCheckedContinuation { continuation in
                diskQueue.async { [weak self] in
                    guard let self = self else {
                        continuation.resume()
                        return
                    }
                    
                    do {
                        let contents = try FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil)
                        for url in contents {
                            try FileManager.default.removeItem(at: url)
                        }
                        
                        Task { @MainActor in
                            self.currentCacheSize = 0
                        }
                    } catch {
                        print("❌ Failed to clear disk cache: \(error)")
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    /// Clean up old cache files to maintain size limit
    func cleanupCacheIfNeeded() {
        guard currentCacheSize > Self.maxCacheSize else { return }
        
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
            } catch {
                print("❌ Failed to create cache directory: \(error)")
            }
        }
    }
    
    /// Download image data from URL
    private func downloadImageData(from url: URL) async -> Data? {
        do {
            let (data, response) = try await urlSession.data(from: url)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Invalid response for image: \(url)")
                return nil
            }
            
            // Store in memory cache
            let cacheKey = NSString(string: url.absoluteString)
            memoryCache.setObject(data as NSData, forKey: cacheKey, cost: data.count)
            
            // Store in disk cache
            await saveImageDataToDisk(data: data, url: url)
            
            return data
        } catch {
            print("❌ Failed to download image: \(error)")
            return nil
        }
    }
    
    /// Load image data from disk cache
    private func loadImageDataFromDisk(url: URL) async -> Data? {
        let cacheDir = cacheDirectory
        return await withCheckedContinuation { continuation in
            diskQueue.async {
                let fileName = Self.fileName(for: url)
                let fileURL = cacheDir.appendingPathComponent(fileName)
                
                guard let data = try? Data(contentsOf: fileURL) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: data)
            }
        }
    }
    
    /// Save image data to disk cache
    private func saveImageDataToDisk(data: Data, url: URL) async {
        let cacheDir = cacheDirectory
        await withCheckedContinuation { continuation in
            diskQueue.async { [weak self] in
                let fileName = Self.fileName(for: url)
                let fileURL = cacheDir.appendingPathComponent(fileName)
                
                do {
                    try data.write(to: fileURL)
                    
                    Task { @MainActor in
                        guard let self = self else { return }
                        self.currentCacheSize += data.count
                        self.cleanupCacheIfNeeded()
                    }
                } catch {
                    print("❌ Failed to save image to disk: \(error)")
                }
                
                continuation.resume()
            }
        }
    }
    
    /// Generate filename for cached image
    nonisolated private static func fileName(for url: URL) -> String {
        let hash = url.absoluteString.hash
        let pathExtension = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
        return "\(abs(hash)).\(pathExtension)"
    }
    
    /// Calculate current disk cache size
    private func calculateDiskCacheSize() {
        Task {
            let cacheDir = cacheDirectory
            
            await withCheckedContinuation { continuation in
                diskQueue.async { [weak self] in
                    var totalSize = 0
                    
                    do {
                        let contents = try FileManager.default.contentsOfDirectory(
                            at: cacheDir,
                            includingPropertiesForKeys: [.fileSizeKey]
                        )
                        
                        for url in contents {
                            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                            totalSize += resourceValues.fileSize ?? 0
                        }
                    } catch {
                        print("❌ Failed to calculate cache size: \(error)")
                    }
                    
                    Task { @MainActor in
                        guard let self = self else { return }
                        self.currentCacheSize = totalSize
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    /// Perform cache cleanup to stay under size limit
    private func performCacheCleanup() async {
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
                        guard let self = self else { return }
                        let currentSize = self.currentCacheSize
                        
                        // Continue cleanup on background queue
                        Task.detached {
                            var totalSize = currentSize
                            let targetSize = Int(Double(maxSize) * 0.8) // Clean to 80% of limit
                            
                            for url in sortedContents {
                                guard totalSize > targetSize else { break }
                                
                                let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                                let fileSize = resourceValues.fileSize ?? 0
                                
                                try FileManager.default.removeItem(at: url)
                                totalSize -= fileSize
                            }
                            
                            // Update size on main actor
                            await MainActor.run {
                                self.currentCacheSize = totalSize
                            }
                        }
                    }
                } catch {
                    print("❌ Cache cleanup failed: \(error)")
                }
                
                continuation.resume()
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
