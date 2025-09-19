//
//  AsyncCachedImage.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI
import UIKit

/// High-performance async image view with advanced caching and memory management
struct AsyncCachedImage: View {
    /// URL of the image to load
    let url: URL?
    /// Content mode for image scaling
    let contentMode: ContentMode
    /// Maximum image size for memory efficiency (deprecated - use imageType instead)
    let maxSize: CGSize?
    /// Whether to show loading placeholder
    let showPlaceholder: Bool
    /// Image type for optimization (determines size and quality)
    let imageType: ImageOptimizationService.ImageType
    
    /// Image cache service for loading and caching
    private let cacheService = ImageCacheService.shared
    
    /// Current image loading state
    @State private var image: Image?
    @State private var isLoading = false
    @State private var loadingError: (any Error)?
    @State private var imageTask: Task<Void, Never>?
    
    init(
        url: URL?,
        contentMode: ContentMode = .fit,
        maxSize: CGSize? = nil,
        showPlaceholder: Bool = true,
        imageType: ImageOptimizationService.ImageType = .medium
    ) {
        self.url = url
        self.contentMode = contentMode
        self.maxSize = maxSize
        self.showPlaceholder = showPlaceholder
        self.imageType = imageType
    }
    
    /// Convenience initializer for thumbnail images (small lists/grids)
    init(
        thumbnailURL url: URL?,
        contentMode: ContentMode = .fit,
        showPlaceholder: Bool = true
    ) {
        self.init(url: url, contentMode: contentMode, showPlaceholder: showPlaceholder, imageType: .thumbnail)
    }
    
    /// Convenience initializer for full-size images (detail views)
    init(
        fullSizeURL url: URL?,
        contentMode: ContentMode = .fit,
        showPlaceholder: Bool = true
    ) {
        self.init(url: url, contentMode: contentMode, showPlaceholder: showPlaceholder, imageType: .full)
    }
    
    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.combined(with: .scale))
            } else if isLoading && showPlaceholder {
                placeholderView
                    .transition(.opacity.combined(with: .scale))
            } else if loadingError != nil && showPlaceholder {
                errorView
                    .transition(.opacity.combined(with: .scale))
            } else {
                Color.clear
            }
        }
        .task(id: url) {
            await loadImage()
        }
        .onDisappear {
            cancelImageLoading()
        }
    }
    
    // MARK: - Placeholder Views
    
    private var placeholderView: some View {
        ZStack {
            Color(.systemGray6)
            
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .opacity(0.8)
        .background(LinearGradient(
            colors: [Color.clear, Color(.systemGray6).opacity(0.3), Color.clear],
            startPoint: .leading,
            endPoint: .trailing
        ))
    }
    
    private var errorView: some View {
        ZStack {
            Color(.systemGray6)
            
            VStack(spacing: 4) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("Failed to load")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Image Loading
    
    @MainActor
    private func loadImage() async {
        guard let url = url else {
            clearImageState()
            return
        }
        
        // Cancel any existing loading task
        cancelImageLoading()
        
        // Check if already loaded
        if image != nil && !isLoading {
            return
        }
        
        isLoading = true
        loadingError = nil
        
        // Create new loading task
        imageTask = Task {
            // First check memory cache for immediate response
            if let cachedImage = await cacheService.getCachedImage(from: url) {
                await MainActor.run {
                    self.image = cachedImage
                    self.isLoading = false
                }
                return
            }
            
            // Load optimized image data from cache service
            if let imageData = await cacheService.optimizedImageData(from: url, imageType: imageType) {
                let loadedImage = await createOptimizedImage(from: imageData)
                
                await MainActor.run {
                    // Check if task was cancelled
                    guard !Task.isCancelled else { return }
                    
                    self.image = loadedImage
                    self.isLoading = false
                    
                    // Cache the SwiftUI Image for faster future access
                    if let loadedImage = loadedImage {
                        Task {
                            await cacheService.cacheImage(loadedImage, for: url)
                        }
                    }
                }
            } else {
                await MainActor.run {
                    self.loadingError = ImageLoadingError.failedToLoad
                    self.isLoading = false
                }
            }
        }
    }
    
    private func cancelImageLoading() {
        imageTask?.cancel()
        imageTask = nil
    }
    
    private func clearImageState() {
        image = nil
        isLoading = false
        loadingError = nil
    }
    
    // MARK: - Image Processing
    
    private func createOptimizedImage(from data: Data) async -> Image? {
        return await Task.detached(priority: .utility) {
            guard let uiImage = UIImage(data: data) else { return nil }
            
            // The image data is already optimized by ImageOptimizationService
            // so we just need to create the SwiftUI Image
            // Legacy maxSize support for backward compatibility
            if let maxSize = maxSize, 
               uiImage.size.width > maxSize.width || uiImage.size.height > maxSize.height {
                let processedImage = await uiImage.resized(to: maxSize) ?? uiImage
                return Image(uiImage: processedImage)
            } else {
                return Image(uiImage: uiImage)
            }
        }.value
    }
}

// MARK: - Image Loading Error

enum ImageLoadingError: LocalizedError {
    case failedToLoad
    case invalidData
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .failedToLoad:
            return "Failed to load image"
        case .invalidData:
            return "Invalid image data"
        case .cancelled:
            return "Image loading cancelled"
        }
    }
}

// MARK: - UIImage Extensions for Performance

extension UIImage {
    /// Resize image while maintaining aspect ratio and quality
    @MainActor
    func resized(to maxSize: CGSize) -> UIImage? {
        let aspectRatio = size.width / size.height
        let targetSize: CGSize
        
        if size.width > size.height {
            targetSize = CGSize(width: min(maxSize.width, size.width), 
                              height: min(maxSize.width, size.width) / aspectRatio)
        } else {
            targetSize = CGSize(width: min(maxSize.height, size.height) * aspectRatio,
                              height: min(maxSize.height, size.height))
        }
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
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
