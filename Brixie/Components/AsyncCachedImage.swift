//
//  AsyncCachedImage.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI

/// High-performance async image view with caching and memory management
/// Optimized for performance with view identity preservation and simplified animations
struct AsyncCachedImage: View {
    /// URL of the image to load
    let url: URL?
    /// Content mode for image scaling
    let contentMode: ContentMode
    /// Whether to show loading placeholder
    let showPlaceholder: Bool
    /// Image type for optimization (determines size and quality)
    let imageType: ImageOptimizationService.ImageType
    
    init(
        url: URL?,
        contentMode: ContentMode = .fit,
        maxSize: CGSize? = nil, // Kept for API compatibility but ignored
        showPlaceholder: Bool = true,
        imageType: ImageOptimizationService.ImageType = .medium
    ) {
        self.url = url
        self.contentMode = contentMode
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
        // Use progressive loading for larger images, simple loading for thumbnails
        if imageType == .full || imageType == .medium {
            ProgressiveAsyncImage(url: url, contentMode: contentMode, showPlaceholder: showPlaceholder, imageType: imageType)
        } else {
            // Use native AsyncImage for thumbnails - they're small enough for direct loading
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    if showPlaceholder {
                        placeholderView
                    } else {
                        Color.clear
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                case .failure:
                    if showPlaceholder {
                        errorView
                    } else {
                        Color.clear
                    }
                @unknown default:
                    Color.clear
                }
            }
        }
    }
    
    // Use integrated progressive loading with background processing
    private var optimizedBody: some View {
        Group {
            if let url = url {
                ProgressiveAsyncImage(
                    url: url, 
                    contentMode: contentMode, 
                    showPlaceholder: showPlaceholder, 
                    imageType: imageType
                )
                .onAppear {
                    // Trigger background processing for upcoming images
                    BackgroundImageProcessor.shared.scheduleProcessing([url], imageType: imageType, delay: 0.5)
                }
            } else {
                if showPlaceholder {
                    placeholderView
                } else {
                    Color.clear
                }
            }
        }
        .id(url) // Preserve view identity for performance
        .animation(.easeOut(duration: 0.2), value: url) // Simple, fast animation
    }
    
    // MARK: - Placeholder Views
    
    private var placeholderView: some View {
        ZStack {
            Color(.systemGray6)
            
            VStack(spacing: 4) {
                Image(systemName: "photo")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                ProgressView()
                    .scaleEffect(0.8)
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

// MARK: - Cached URLSession

/// URLSession configured with caching for AsyncImage
@MainActor
final class CachedURLSession {
    static let shared = CachedURLSession()
    
    lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        
        // Configure caching
        config.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024, // 20MB memory cache
            diskCapacity: 100 * 1024 * 1024   // 100MB disk cache
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        // Optimize for performance
        config.httpMaximumConnectionsPerHost = 4
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        
        return URLSession(configuration: config)
    }()
    
    private init() {}
}

// MARK: - Preview Support

#if DEBUG
struct AsyncCachedImage_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            AsyncCachedImage(url: URL(string: "https://example.com/image.jpg"))
                .frame(width: 200, height: 150)
                .border(Color.gray.opacity(0.3))
            
            AsyncCachedImage(thumbnailURL: URL(string: "https://example.com/thumb.jpg"))
                .frame(width: 120, height: 120)
                .border(Color.gray.opacity(0.3))
        }
        .padding()
    }
}
#endif
