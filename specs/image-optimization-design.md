# Image Optimization Design - HEIC Conversion System

## Overview

The current Brixie app downloads large images from the Rebrickable API, which can be several MBs each. This causes performance issues in list views and consumes excessive memory. This design introduces a HEIC conversion system to optimize image storage and display.

## Analysis

### Current State
- **AsyncCachedImage**: Downloads full-size images and caches them as-is
- **ImageCacheService**: Provides memory/disk caching with no format optimization
- **Usage**: Images used in list views (60x60px), card views (120px height), detail views (larger)
- **Problem**: Large images (sometimes 1-2MB+) used even for small thumbnail displays

### Requirements (EARS Notation)
- **WHEN** an image is downloaded, **THE SYSTEM SHALL** convert it to HEIC format for storage efficiency
- **WHEN** displaying images in lists, **THE SYSTEM SHALL** use optimized thumbnail-sized versions
- **WHEN** displaying images in detail views, **THE SYSTEM SHALL** provide full-quality images
- **WHEN** HEIC conversion fails, **THE SYSTEM SHALL** fallback to original format gracefully
- **WHEN** device doesn't support HEIC, **THE SYSTEM SHALL** use optimized JPEG format instead

## Technical Design

### Architecture Components

#### 1. ImageOptimizationService
```swift
@MainActor
final class ImageOptimizationService {
    enum ImageType {
        case thumbnail(size: CGSize)
        case medium(maxSize: CGSize)
        case full
    }
    
    enum OutputFormat {
        case heic(quality: Float)
        case jpeg(quality: Float)
        case original
    }
}
```

#### 2. Enhanced ImageCacheService
- Add HEIC conversion capabilities
- Support multiple image variants (thumbnail, medium, full)
- Implement smart format selection based on device capabilities

#### 3. Updated AsyncCachedImage
- Support `ImageType` parameter for requesting appropriate image variant
- Maintain backward compatibility

### Image Optimization Strategy

#### Size Variants
1. **Thumbnail**: 120x120px @ 0.8 quality HEIC for list/grid views
2. **Medium**: 400x400px @ 0.9 quality HEIC for card views  
3. **Full**: Original size @ 0.95 quality HEIC for detail views

#### Format Strategy
1. **Primary**: HEIC (iOS 11+, smaller file sizes)
2. **Fallback**: JPEG with optimized quality settings
3. **Cache Keys**: Include format and size in cache key for variants

### Implementation Plan

#### Phase 1: Core Optimization Service
1. Create `ImageOptimizationService` with HEIC conversion
2. Add device capability detection
3. Implement format fallback logic

#### Phase 2: Cache Integration
1. Extend `ImageCacheService` with optimization calls
2. Support variant-based caching
3. Add cache key management for variants

#### Phase 3: Component Updates  
1. Update `AsyncCachedImage` with `ImageType` parameter
2. Update calling components to specify appropriate image types
3. Maintain backward compatibility

#### Phase 4: Migration & Cleanup
1. Add cache migration for existing images
2. Implement cache cleanup for old format images
3. Performance validation

## Expected Benefits

### Performance Improvements
- **File Size**: 40-70% reduction with HEIC format
- **Memory Usage**: Smaller thumbnails reduce memory footprint
- **Loading Speed**: Faster network transfers and cache hits
- **Battery Life**: Reduced data transfer and processing

### User Experience
- **Faster Lists**: Optimized thumbnails load quickly
- **Smooth Scrolling**: Reduced memory pressure
- **Progressive Loading**: Load thumbnails first, full images on demand

## Implementation Details

### Cache Structure
```
ImageCache/
├── thumbnails/
│   ├── set_12345.heic
│   └── set_67890.heic
├── medium/
│   ├── set_12345.heic
│   └── set_67890.heic
└── full/
    ├── set_12345.heic
    └── set_67890.heic
```

### Error Handling
- **HEIC Unavailable**: Fall back to optimized JPEG
- **Conversion Failed**: Use original format with size optimization
- **Network Issues**: Progressive loading from cache variants
- **Storage Full**: Intelligent cache eviction by variant priority

### Testing Strategy
- **Unit Tests**: HEIC conversion, format fallback, size optimization
- **Integration Tests**: Cache behavior, variant management
- **Performance Tests**: Memory usage, loading times, file sizes
- **Device Tests**: HEIC support detection, fallback behavior

## Risk Mitigation

### Technical Risks
- **HEIC Support**: Not all devices support HEIC → Implement JPEG fallback
- **Conversion Performance**: CPU intensive → Use background processing
- **Cache Complexity**: Multiple variants → Careful key management

### Compatibility Risks  
- **iOS Versions**: HEIC iOS 11+ → Graceful degradation
- **Storage Space**: More variants → Intelligent cleanup policies
- **Migration**: Existing cache → Gradual migration strategy

## Success Metrics

### Technical Metrics
- **File Size Reduction**: Target 50% average reduction
- **Memory Usage**: Target 40% reduction in list views
- **Loading Performance**: Target 30% faster list loading
- **Cache Hit Rate**: Maintain >80% hit rate

### User Metrics
- **App Responsiveness**: Improved scroll performance
- **Data Usage**: Reduced cellular data consumption
- **Battery Impact**: Measurable battery life improvement

## Future Enhancements

### Advanced Optimizations
- **WebP Support**: Additional format option for older devices
- **Adaptive Quality**: Dynamic quality based on network conditions
- **Smart Prefetching**: Preload variants based on user behavior
- **Cloud Optimization**: Server-side image variants if API supports it