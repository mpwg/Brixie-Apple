//
//  AsyncCachedImage.swift
//  Brixie
//
//  Created by GitHub Copilot on 18/09/2025.
//

import SwiftUI

/// Async image view with caching support
/// Pure SwiftUI implementation without UIKit/AppKit dependencies
struct AsyncCachedImage: View {
    /// URL of the image to load
    let url: URL?
    
    /// Image cache service for loading and caching
    private let cacheService = ImageCacheService.shared
    
    /// Current image loading state
    @State private var imageData: Data?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let imageData = imageData {
                // Use SwiftUI's AsyncImage with local data
                AsyncImageFromData(data: imageData)
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .task {
            await loadImage()
        }
        .onChange(of: url) { _, _ in
            imageData = nil
            Task {
                await loadImage()
            }
        }
    }
    
    /// Load image data from cache or network
    private func loadImage() async {
        guard let url = url else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        if let data = await cacheService.imageData(from: url) {
            await MainActor.run {
                imageData = data
            }
        }
    }
}

/// Helper view to create SwiftUI Image from Data
/// This is a pure SwiftUI solution that doesn't rely on platform-specific image types
private struct AsyncImageFromData: View {
    let data: Data
    
    var body: some View {
        // Create a temporary URL from data and use AsyncImage
        if let tempURL = createTempDataURL(from: data) {
            AsyncImage(url: tempURL) { image in
                image
                    .resizable()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .onDisappear {
                // Clean up temp file
                try? FileManager.default.removeItem(at: tempURL)
            }
        } else {
            Color.gray.opacity(0.3)
        }
    }
    
    /// Create temporary URL from image data for AsyncImage
    private func createTempDataURL(from data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent(UUID().uuidString + ".jpg")
        
        do {
            try data.write(to: tempFile)
            return tempFile
        } catch {
            return nil
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
