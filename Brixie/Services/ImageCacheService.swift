//
//  ImageCacheService.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Foundation
import SwiftUI

// Wrapper class for Data to use with NSCache
final class CachedImageData: Sendable {
    let data: Data
    
    init(data: Data) {
        self.data = data
    }
}

@Observable
final class ImageCacheService: @unchecked Sendable {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, CachedImageData>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Set up cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure memory cache for image data
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1_024 * 1_024 // 50MB
    }
    
    func loadImageData(from urlString: String) async -> Data? {
        // Check memory cache first
        if let cachedData = cache.object(forKey: NSString(string: urlString)) {
            return cachedData.data
        }
        
        // Check disk cache
        let cacheKey = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? urlString
        let fileURL = cacheDirectory.appendingPathComponent("\(cacheKey).jpg")
        
        if let imageData = try? Data(contentsOf: fileURL) {
            // Store in memory cache
            cache.setObject(CachedImageData(data: imageData), forKey: NSString(string: urlString))
            return imageData
        }
        
        // Download from network
        return await downloadAndCacheImageData(from: urlString)
    }
    
    private func downloadAndCacheImageData(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Validate that this is actually image data
            guard isValidImageData(data) else { return nil }
            
            // Store in memory cache
            cache.setObject(CachedImageData(data: data), forKey: NSString(string: urlString))
            
            // Store in disk cache
            let cacheKey = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? urlString
            let fileURL = cacheDirectory.appendingPathComponent("\(cacheKey).jpg")
            
            try data.write(to: fileURL)
            
            return data
        } catch {
            print("Failed to download image: \(error)")
            return nil
        }
    }
    
    private func isValidImageData(_ data: Data) -> Bool {
        // Check for common image format headers
        guard data.count > 4 else { return false }
        
        let bytes = [UInt8](data.prefix(4))
        
        // JPEG header: FF D8 FF
        if bytes.prefix(3) == [0xFF, 0xD8, 0xFF] {
            return true
        }
        
        // PNG header: 89 50 4E 47
        if bytes == [0x89, 0x50, 0x4E, 0x47] {
            return true
        }
        
        // GIF header: 47 49 46 38
        if bytes == [0x47, 0x49, 0x46, 0x38] {
            return true
        }
        
        // WebP header: 52 49 46 46 (RIFF)
        if bytes == [0x52, 0x49, 0x46, 0x46] {
            return true
        }
        
        return false
    }
    
    func clearCache() {
        cache.removeAllObjects()
        
        // Clear disk cache
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Failed to clear disk cache: \(error)")
        }
    }
    
    func getCacheSize() -> String {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            let totalSize = files.compactMap { url -> Int64? in
                let resources = try? url.resourceValues(forKeys: [.fileSizeKey])
                return Int64(resources?.fileSize ?? 0)
            }.reduce(0, +)
            
            return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        } catch {
            return "Unknown"
        }
    }
}

#Preview("Placeholder") {
    AsyncCachedImage(urlString: nil)
        .frame(width: 100, height: 100)
}

#Preview("Remote Image") {
    AsyncCachedImage(urlString: "https://via.placeholder.com/150")
        .frame(width: 150, height: 150)
}

// Pure SwiftUI AsyncCachedImage component using Data
struct AsyncCachedImage: View {
    let urlString: String?
    let placeholder: Image
    
    @State private var imageData: Data?
    @State private var isLoading = true
    
    init(urlString: String?, placeholder: Image = Image(systemName: "photo")) {
        self.urlString = urlString
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let imageData = imageData {
                // Use the data to create a temporary file for Image to display
                CachedImageView(data: imageData)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await loadImageData()
        }
    }
    
    private func loadImageData() async {
        guard let urlString = urlString else {
            isLoading = false
            return
        }
        
        imageData = await ImageCacheService.shared.loadImageData(from: urlString)
        isLoading = false
    }
}

// Helper view to display cached image data
struct CachedImageView: View {
    let data: Data
    @State private var tempURL: URL?
    
    var body: some View {
        Group {
            if let tempURL = tempURL {
                AsyncImage(url: tempURL) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            createTempFile()
        }
        .onDisappear {
            cleanupTempFile()
        }
    }
    
    private func createTempFile() {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("cached_image_\(UUID().uuidString).jpg")
        
        do {
            try data.write(to: tempFile)
            tempURL = tempFile
        } catch {
            print("Failed to create temp file: \(error)")
        }
    }
    
    private func cleanupTempFile() {
        guard let tempURL = tempURL else { return }
        try? FileManager.default.removeItem(at: tempURL)
    }
}
