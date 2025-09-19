//
//  AsyncCachedImage.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

/// Async image view with caching support
struct AsyncCachedImage: View {
    /// URL of the image to load
    let url: URL?
    
    /// Image cache service for loading and caching
    private let cacheService = ImageCacheService.shared
    
    /// Current image loading state
    @State private var loadedImage: Image?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = loadedImage {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .task {
            await loadImage()
        }
        .onChange(of: url) { _, _ in
            loadedImage = nil
            Task {
                await loadImage()
            }
        }
    }
    
    /// Load image from cache or network
    private func loadImage() async {
        guard let url = url else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        if let imageData = await cacheService.imageData(from: url),
           let platformImage = createImage(from: imageData) {
            await MainActor.run {
                #if canImport(UIKit)
                loadedImage = Image(uiImage: platformImage)
                #elseif canImport(AppKit)
                loadedImage = Image(nsImage: platformImage)
                #endif
            }
        }
    }
    
    /// Create platform image from data
    private func createImage(from data: Data) -> PlatformImage? {
        #if canImport(UIKit)
        return PlatformImage(data: data)
        #elseif canImport(AppKit)
        return PlatformImage(data: data)
        #else
        return nil
        #endif
    }
}

// MARK: - Preview Support

#if DEBUG
struct AsyncCachedImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AsyncCachedImage(url: URL(string: "https://example.com/image.jpg"))
                .frame(width: 200, height: 200)
        }
        .padding()
    }
}
#endif