//
//  ImageCacheService.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Foundation
import SwiftUI
import UIKit

@Observable
final class ImageCacheService: @unchecked Sendable {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let queue = DispatchQueue(label: "com.brixie.imagecache", qos: .utility)
    
    private init() {
        // Set up cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure memory cache
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func loadImage(from urlString: String) async -> UIImage? {
        // Check memory cache first
        let cachedImage = await withCheckedContinuation { continuation in
            queue.async {
                let image = self.cache.object(forKey: NSString(string: urlString))
                continuation.resume(returning: image)
            }
        }
        
        if let cachedImage = cachedImage {
            return cachedImage
        }
        
        // Check disk cache
        let cacheKey = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? urlString
        let fileURL = cacheDirectory.appendingPathComponent("\(cacheKey).jpg")
        
        if let imageData = try? Data(contentsOf: fileURL),
           let image = UIImage(data: imageData) {
            // Store in memory cache
            await withCheckedContinuation { continuation in
                queue.async {
                    self.cache.setObject(image, forKey: NSString(string: urlString))
                    continuation.resume()
                }
            }
            return image
        }
        
        // Download from network
        return await downloadAndCacheImage(from: urlString)
    }
    
    private func downloadAndCacheImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            
            // Store in memory cache
            await withCheckedContinuation { continuation in
                queue.async {
                    self.cache.setObject(image, forKey: NSString(string: urlString))
                    continuation.resume()
                }
            }
            
            // Store in disk cache
            let cacheKey = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? urlString
            let fileURL = cacheDirectory.appendingPathComponent("\(cacheKey).jpg")
            
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                try jpegData.write(to: fileURL)
            }
            
            return image
            
        } catch {
            print("Failed to download image: \(error)")
            return nil
        }
    }
    
    func clearCache() {
        queue.sync {
            cache.removeAllObjects()
        }
        
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

#Preview {
    Group {
        AsyncCachedImage(urlString: nil)
            .previewDisplayName("Placeholder")
            .frame(width: 100, height: 100)

        AsyncCachedImage(urlString: "https://via.placeholder.com/150")
            .previewDisplayName("Remote Image")
            .frame(width: 150, height: 150)
    }
}

// SwiftUI Image extension for easy async loading
struct AsyncCachedImage: View {
    let urlString: String?
    let placeholder: Image
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    init(urlString: String?, placeholder: Image = Image(systemName: "photo")) {
        self.urlString = urlString
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let urlString = urlString else {
            isLoading = false
            return
        }
        
        image = await ImageCacheService.shared.loadImage(from: urlString)
        isLoading = false
    }
}
