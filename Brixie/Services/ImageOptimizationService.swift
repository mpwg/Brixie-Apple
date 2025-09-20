//
//  ImageOptimizationService.swift
//  Brixie
//
//  Created by GitHub Copilot on 19/09/2025.
//

import Foundation
import SwiftUI
import ImageIO
import OSLog

/// Service for optimizing images with HEIC conversion and size variants
@MainActor
final class ImageOptimizationService {
    /// Singleton instance
    static let shared = ImageOptimizationService()
    
    /// Logger for image optimization operations
    private let logger = Logger.imageOptimization
    
    // MARK: - Types
    
    /// Image variant types for different use cases
    enum ImageType: CaseIterable, CustomStringConvertible {
        case thumbnail  // 120x120px for lists and grids
        case medium     // 400x400px for cards
        case full       // Original size for detail views
        
        var description: String {
            switch self {
            case .thumbnail:
                return "thumbnail"
            case .medium:
                return "medium"
            case .full:
                return "full"
            }
        }
        
        /// Maximum size for this image type
        var maxSize: CGSize {
            switch self {
            case .thumbnail:
                return CGSize(width: 120, height: 120)
            case .medium:
                return CGSize(width: 400, height: 400)
            case .full:
                return CGSize(width: 2_048, height: 2_048) // Reasonable maximum
            }
        }
        
        /// Directory name for caching
        var directoryName: String {
            switch self {
            case .thumbnail:
                return "thumbnails"
            case .medium:
                return "medium"
            case .full:
                return "full"
            }
        }
    }
    
    /// Output format options
    enum OutputFormat {
        case heic(quality: Float)
        case jpeg(quality: Float)
        case webp(quality: Float)
        case original
        
        /// File extension for this format
        var fileExtension: String {
            switch self {
            case .heic:
                return "heic"
            case .jpeg:
                return "jpg"
            case .webp:
                return "webp"
            case .original:
                return "original"
            }
        }
        
        /// UTType identifier
        var utType: String {
            switch self {
            case .heic:
                return "public.heic"
            case .jpeg:
                return "public.jpeg"
            case .webp:
                return "org.webmproject.webp"
            case .original:
                return ""
            }
        }
        
        /// Quality value (0.0 to 1.0)
        var quality: Float {
            switch self {
            case .heic(let quality), .jpeg(let quality), .webp(let quality):
                return quality
            case .original:
                return Float(AppConstants.ImageQuality.maximum)
            }
        }
    }
    
    // MARK: - Properties
    
    /// Whether the device supports HEIC encoding
    private let supportsHEIC: Bool
    
    /// Whether the device supports WebP encoding
    private let supportsWebP: Bool
    
    /// Preferred format based on device capabilities
    private let preferredFormat: OutputFormat
    
    // MARK: - Initialization
    
    private init() {
        // Check HEIC support (iOS 11+ and macOS 10.13+)
        supportsHEIC = CGImageDestinationCreateWithData(
            NSMutableData(),
            "public.heic" as CFString,
            1,
            nil
        ) != nil
        
        // Check WebP support (iOS 14+ and macOS 11+)
        supportsWebP = CGImageDestinationCreateWithData(
            NSMutableData(),
            "org.webmproject.webp" as CFString,
            1,
            nil
        ) != nil
        
        // Set preferred format (prioritize HEIC > WebP > JPEG)
        if supportsHEIC {
            preferredFormat = .heic(quality: Float(AppConstants.ImageQuality.medium))
            logger.info("🎯 ImageOptimizationService initialized with HEIC support")
        } else if supportsWebP {
            preferredFormat = .webp(quality: Float(AppConstants.ImageQuality.medium))
            logger.info("🎯 ImageOptimizationService initialized with WebP support")
        } else {
            preferredFormat = .jpeg(quality: Float(AppConstants.ImageQuality.standardJPEG))
            logger.info("🎯 ImageOptimizationService initialized with JPEG fallback")
        }
    }
    
    // MARK: - Public API
    
    /// Optimize an image for a specific type and format
    /// - Parameters:
    ///   - data: Original image data
    ///   - imageType: Target image type (thumbnail, medium, full)
    ///   - customFormat: Optional custom format (uses preferred if nil)
    /// - Returns: Optimized image data or nil if optimization failed
    func optimizeImage(
        data: Data,
        for imageType: ImageType,
        format customFormat: OutputFormat? = nil
    ) async -> Data? {
        let startTime = CFAbsoluteTimeGetCurrent()
        let format = customFormat ?? getOptimalFormat(for: imageType)
        
        logger.debug("🔄 Starting optimization: type=\(imageType), format=\(format.fileExtension)")
        
        // Get target size before entering background task
        let targetSize = imageType.maxSize
        
        return await Task.detached(priority: .utility) {
            // Use aggressive downsampling for better memory performance
            guard let downsampledImage = Self.downsample(imageData: data, to: targetSize) else {
                await MainActor.run {
                    self.logger.error("❌ Failed to downsample image from data")
                }
                return nil
            }
            
            // Image is already downsampled, so we can convert directly
            let optimizedData = await self.convertToFormat(downsampledImage, format: format)
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            let originalSize = data.count
            let optimizedSize = optimizedData?.count ?? 0
            let compressionRatio = optimizedSize > 0 ? Double(originalSize) / Double(optimizedSize) : 0
            
            await MainActor.run {
                self.logger.info("✅ Optimization complete: \(originalSize) → \(optimizedSize) bytes (\(compressionRatio, format: .fixed(precision: 1))x compression) in \(duration, format: .fixed(precision: 3))s")
            }
            
            return optimizedData
        }.value
    }
    
    /// Generate cache key for optimized image
    /// - Parameters:
    ///   - url: Original image URL
    ///   - imageType: Image type
    ///   - format: Output format
    /// - Returns: Cache key string
    func cacheKey(for url: URL, imageType: ImageType, format: OutputFormat? = nil) -> String {
        let actualFormat = format ?? getOptimalFormat(for: imageType)
        let urlHash = url.absoluteString.hash
        return "\(imageType.directoryName)/\(abs(urlHash)).\(actualFormat.fileExtension)"
    }
    
    /// Get optimal format for image type
    /// - Parameter imageType: Target image type
    /// - Returns: Optimal output format
    func getOptimalFormat(for imageType: ImageType) -> OutputFormat {
        switch imageType {
        case .thumbnail:
            if supportsHEIC {
                return .heic(quality: Float(AppConstants.ImageQuality.standardHEIC))
            } else if supportsWebP {
                return .webp(quality: Float(AppConstants.ImageQuality.standardHEIC))
            } else {
                return .jpeg(quality: Float(AppConstants.ImageQuality.low))
            }
        case .medium:
            if supportsHEIC {
                return .heic(quality: Float(AppConstants.ImageQuality.medium))
            } else if supportsWebP {
                return .webp(quality: Float(AppConstants.ImageQuality.medium))
            } else {
                return .jpeg(quality: Float(AppConstants.ImageQuality.standardJPEG))
            }
        case .full:
            if supportsHEIC {
                return .heic(quality: Float(AppConstants.ImageQuality.high))
            } else if supportsWebP {
                return .webp(quality: Float(AppConstants.ImageQuality.high))
            } else {
                return .jpeg(quality: Float(AppConstants.ImageQuality.medium))
            }
        }
    }
    
    /// Get disk cache URL for optimized image
    /// - Parameters:
    ///   - url: Original image URL
    ///   - imageType: Image type
    ///   - cacheDirectory: Base cache directory
    /// - Returns: URL for cached file on disk
    func diskCacheURL(for url: URL, imageType: ImageType, in cacheDirectory: URL) -> URL {
        let cacheKey = self.cacheKey(for: url, imageType: imageType)
        return cacheDirectory.appendingPathComponent(cacheKey)
    }
    
    // MARK: - Private Helpers
    
    /// Downsample image before any processing to reduce memory footprint
    nonisolated static func downsample(imageData: Data, to pointSize: CGSize, scale: CGFloat = 3.0) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOptions) else {
            return nil
        }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    /// Create UIImage from image data (static method for use in other components)
    nonisolated static func createOptimizedImage(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    /// Create UIImage from data
    private func createUIImage(from data: Data) async -> UIImage? {
        return UIImage(data: data)
    }
    
    /// Resize image to fit within type constraints
    private func resizeImage(_ image: UIImage, for imageType: ImageType) async -> UIImage {
        let maxSize = imageType.maxSize
        let currentSize = image.size
        
        // If image is already smaller than or equal to target, return as-is
        if currentSize.width <= maxSize.width && currentSize.height <= maxSize.height {
            return image
        }
        
        // Calculate aspect ratio and target size
        let aspectRatio = currentSize.width / currentSize.height
        let targetSize: CGSize
        
        if aspectRatio > 1 {
            // Landscape: constrain by width
            targetSize = CGSize(
                width: min(maxSize.width, currentSize.width),
                height: min(maxSize.width, currentSize.width) / aspectRatio
            )
        } else {
            // Portrait or square: constrain by height
            targetSize = CGSize(
                width: min(maxSize.height, currentSize.height) * aspectRatio,
                height: min(maxSize.height, currentSize.height)
            )
        }
        
        // Create resized image
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// Convert image to specified format
    private func convertToFormat(_ image: UIImage, format: OutputFormat) async -> Data? {
        return await Task.detached {
            switch format {
            case .heic(let quality):
                return await self.convertToHEIC(image, quality: quality)
            case .jpeg(let quality):
                return image.jpegData(compressionQuality: CGFloat(quality))
            case .webp(let quality):
                return await self.convertToWebP(image, quality: quality)
            case .original:
                // Return PNG data as "original" fallback
                return image.pngData()
            }
        }.value
    }
    
    /// Convert image to HEIC format
    private func convertToHEIC(_ image: UIImage, quality: Float) async -> Data? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            "public.heic" as CFString,
            1,
            nil
        ) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return data as Data
    }
    
    /// Convert image to WebP format
    private func convertToWebP(_ image: UIImage, quality: Float) async -> Data? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            "org.webmproject.webp" as CFString,
            1,
            nil
        ) else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return data as Data
    }
}
