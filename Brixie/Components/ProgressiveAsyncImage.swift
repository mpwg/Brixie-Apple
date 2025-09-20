//
//  ProgressiveAsyncImage.swift
//  Brixie
//
//  Created by GitHub Copilot on 20/09/2025.
//

import SwiftUI
import OSLog

/// Progressive image loading component that starts with low-quality and enhances to full quality
/// Reduces initial memory pressure and provides faster perceived loading
struct ProgressiveAsyncImage: View {
    /// URL of the image to load
    let url: URL?
    /// Content mode for image scaling
    let contentMode: ContentMode
    /// Whether to show loading placeholder
    let showPlaceholder: Bool
    /// Image type for optimization
    let imageType: ImageOptimizationService.ImageType
    
    @State private var lowQualityImage: Image?
    @State private var highQualityImage: Image?
    @State private var isLoadingLowQuality = false
    @State private var isLoadingHighQuality = false
    @State private var loadingError: (any Error)?
    
    private let logger = Logger(subsystem: "com.brixie", category: "ProgressiveImage")
    private let cacheService = ImageCacheService.shared
    
    init(
        url: URL?,
        contentMode: ContentMode = .fit,
        showPlaceholder: Bool = true,
        imageType: ImageOptimizationService.ImageType = .medium
    ) {
        self.url = url
        self.contentMode = contentMode
        self.showPlaceholder = showPlaceholder
        self.imageType = imageType
    }
    
    var body: some View {
        ZStack {
            // Background placeholder
            if showPlaceholder && lowQualityImage == nil && highQualityImage == nil && !isLoadingLowQuality {
                placeholderView
            }
            
            // Low quality image (loads first)
            if let lowQualityImage = lowQualityImage {
                lowQualityImage
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .opacity(highQualityImage == nil ? 1.0 : 0.3)
                    .transition(.opacity)
            }
            
            // High quality image (loads second)
            if let highQualityImage = highQualityImage {
                highQualityImage
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
            
            // Error state
            if loadingError != nil && lowQualityImage == nil && highQualityImage == nil {
                errorView
            }
            
            // Loading indicator (only show if no images loaded yet)
            if isLoadingLowQuality && lowQualityImage == nil && highQualityImage == nil {
                loadingIndicator
            }
        }
        .id(url) // Preserve view identity
        .task(id: url) {
            await loadProgressiveImage()
        }
    }
    
    // MARK: - Progressive Loading Logic
    
    @MainActor
    private func loadProgressiveImage() async {
        guard let url = url else { return }
        
        // Reset state
        lowQualityImage = nil
        highQualityImage = nil
        loadingError = nil
        isLoadingLowQuality = true
        isLoadingHighQuality = false
        
        // Check if we have a cached high-quality image first
        if let cachedImage = await cacheService.getCachedImage(from: url) {
            highQualityImage = cachedImage
            isLoadingLowQuality = false
            logger.debug("✅ Loaded cached high-quality image for \(url.lastPathComponent)")
            return
        }
        
        // Phase 1: Load low-quality version
        await loadLowQualityImage(from: url)
        
        // Phase 2: Load high-quality version (with slight delay to show low-quality first)
        if lowQualityImage != nil {
            try? await Task.sleep(for: .milliseconds(100))
        }
        
        await loadHighQualityImage(from: url)
    }
    
    @MainActor
    private func loadLowQualityImage(from url: URL) async {
        // Generate low-quality URL or use thumbnail optimization
        let lowQualityType: ImageOptimizationService.ImageType = switch imageType {
        case .thumbnail:
            .thumbnail
        case .medium:
            .thumbnail
        case .full:
            .medium
        }
        
        if let imageData = await cacheService.optimizedImageData(from: url, imageType: lowQualityType) {
            if let uiImage = ImageOptimizationService.createOptimizedImage(from: imageData) {
                lowQualityImage = Image(uiImage: uiImage)
                logger.debug("📉 Loaded low-quality image for \(url.lastPathComponent)")
            }
        }
        
        isLoadingLowQuality = false
    }
    
    @MainActor
    private func loadHighQualityImage(from url: URL) async {
        isLoadingHighQuality = true
        
        if let imageData = await cacheService.optimizedImageData(from: url, imageType: imageType) {
            if let uiImage = ImageOptimizationService.createOptimizedImage(from: imageData) {
                let swiftUIImage = Image(uiImage: uiImage)
                highQualityImage = swiftUIImage
                
                // Cache the SwiftUI image for future use
                await cacheService.cacheImage(swiftUIImage, for: url)
                
                logger.debug("📈 Loaded high-quality image for \(url.lastPathComponent)")
            }
        }
        
        isLoadingHighQuality = false
    }
    
    // MARK: - View Components
    
    private var placeholderView: some View {
        ZStack {
            Color(.systemGray6)
            
            VStack(spacing: 4) {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .opacity(0.6)
            }
        }
        .opacity(0.5)
    }
    
    private var loadingIndicator: some View {
        ZStack {
            Color(.systemGray6)
            
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("Loading...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .opacity(0.8)
    }
    
    private var errorView: some View {
        ZStack {
            Color(.systemGray6)
            
            VStack(spacing: 4) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.title3)
                    .foregroundColor(.red.opacity(0.7))
                
                Text("Load failed")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .opacity(0.8)
    }
}

// MARK: - Convenience Initializers

extension ProgressiveAsyncImage {
    /// Convenience initializer for thumbnail images
    init(thumbnailURL url: URL?, contentMode: ContentMode = .fit, showPlaceholder: Bool = true) {
        self.init(url: url, contentMode: contentMode, showPlaceholder: showPlaceholder, imageType: .thumbnail)
    }
    
    /// Convenience initializer for full-size images
    init(fullSizeURL url: URL?, contentMode: ContentMode = .fit, showPlaceholder: Bool = true) {
        self.init(url: url, contentMode: contentMode, showPlaceholder: showPlaceholder, imageType: .full)
    }
}

// MARK: - Preview Support

#if DEBUG
struct ProgressiveAsyncImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            ProgressiveAsyncImage(url: URL(string: "https://example.com/large-image.jpg"))
                .frame(width: 300, height: 200)
                .border(Color.gray.opacity(0.3))
                .cornerRadius(8)
            
            ProgressiveAsyncImage(thumbnailURL: URL(string: "https://example.com/thumbnail.jpg"))
                .frame(width: 120, height: 120)
                .border(Color.gray.opacity(0.3))
                .cornerRadius(8)
        }
        .padding()
    }
}
#endif