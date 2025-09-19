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
                return CGSize(width: 2048, height: 2048) // Reasonable maximum
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
        case original
        
        /// File extension for this format
        var fileExtension: String {
            switch self {
            case .heic:
                return "heic"
            case .jpeg:
                return "jpg"
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
            case .original:
                return ""
            }
        }
        
        /// Quality value (0.0 to 1.0)
        var quality: Float {
            switch self {
            case .heic(let quality), .jpeg(let quality):
                return quality
            case .original:
                return Float(AppConstants.ImageQuality.maximum)
            }
        }
    }
    
    // MARK: - Properties
    
    /// Whether the device supports HEIC encoding
    private let supportsHEIC: Bool
    
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
        
        // Set preferred format
        if supportsHEIC {
            preferredFormat = .heic(quality: Float(AppConstants.ImageQuality.medium))
            logger.info("🎯 ImageOptimizationService initialized with HEIC support")
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
        
        return await Task.detached(priority: .utility) {
            guard let sourceImage = await self.createUIImage(from: data) else {
                await MainActor.run {
                    self.logger.error("❌ Failed to create UIImage from data")
                }
                return nil
            }
            
            let optimizedImage = await self.resizeImage(sourceImage, for: imageType)
            let optimizedData = await self.convertToFormat(optimizedImage, format: format)
            
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
            return supportsHEIC ? .heic(quality: Float(AppConstants.ImageQuality.standardHEIC)) : .jpeg(quality: Float(AppConstants.ImageQuality.low))
        case .medium:
            return supportsHEIC ? .heic(quality: Float(AppConstants.ImageQuality.medium)) : .jpeg(quality: Float(AppConstants.ImageQuality.standardJPEG))
        case .full:
            return supportsHEIC ? .heic(quality: Float(AppConstants.ImageQuality.high)) : .jpeg(quality: Float(AppConstants.ImageQuality.medium))
        }
    }
    
    // MARK: - Private Helpers
    
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
}

// MARK: - Logger Extension

extension Logger {
    static let imageOptimization = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.brixie",
        category: "ImageOptimization"
    )
}