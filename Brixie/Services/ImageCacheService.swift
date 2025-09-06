//
//  ImageCacheService.swift
//  Brixie
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Foundation
import SwiftUI

#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif

// Cross-platform image extensions
#if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
extension UIImage {
    func imageData() -> Data? {
        return self.jpegData(compressionQuality: 0.8)
    }
}
#elseif os(macOS)
extension NSImage {
    func imageData() -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImageRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapImageRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
    }
}
#endif

@Observable
class ImageCacheService {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, PlatformImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
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
    
    func loadImage(from urlString: String) async -> PlatformImage? {
        // Check memory cache first
        if let cachedImage = cache.object(forKey: NSString(string: urlString)) {
            return cachedImage
        }
        
        // Check disk cache
        let cacheKey = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? urlString
        let fileURL = cacheDirectory.appendingPathComponent("\(cacheKey).jpg")
        
        if let imageData = try? Data(contentsOf: fileURL),
           let image = PlatformImage(data: imageData) {
            // Store in memory cache
            cache.setObject(image, forKey: NSString(string: urlString))
            return image
        }
        
        // Download from network
        return await downloadAndCacheImage(from: urlString)
    }
    
    private func downloadAndCacheImage(from urlString: String) async -> PlatformImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = PlatformImage(data: data) else { return nil }
            
            // Store in memory cache
            cache.setObject(image, forKey: NSString(string: urlString))
            
            // Store in disk cache
            let cacheKey = urlString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? urlString
            let fileURL = cacheDirectory.appendingPathComponent("\(cacheKey).jpg")
            
            // Cross-platform image data conversion
            if let imageData = image.imageData() {
                try imageData.write(to: fileURL)
            }
            
            return image
            
        } catch {
            print("Failed to download image: \(error)")
            return nil
        }
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
    
    @State private var image: PlatformImage?
    @State private var isLoading = true
    
    init(urlString: String?, placeholder: Image = Image(systemName: "photo")) {
        self.urlString = urlString
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                #if os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
                Image(uiImage: image)
                    .resizable()
                #elseif os(macOS)
                Image(nsImage: image)
                    .resizable()
                #endif
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
