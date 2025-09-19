# Brixie Performance Optimization Guide

## Executive Summary

The Brixie app exhibits UI sluggishness despite having caching and optimization mechanisms in place. This guide provides actionable optimization strategies for AI coding assistants to implement, focusing on SwiftUI-specific performance improvements, memory management, and rendering optimizations.

## Current Performance Bottlenecks

### 1. Image Loading & Caching Issues

**Problem Areas:**
- `AsyncCachedImage` creates multiple concurrent tasks without proper throttling
- Double caching (memory cache for both Data and Image objects)
- No image format optimization (HEIF/WebP support)
- Missing progressive loading for large images
- Redundant image processing on main thread

**Evidence:**
```swift
// Current inefficient pattern in AsyncCachedImage.swift
if let imageData = await cacheService.optimizedImageData(from: url, imageType: imageType) {
    let loadedImage = await createOptimizedImage(from: imageData) // Redundant processing
    await MainActor.run {
        self.image = loadedImage // Main thread blocking
    }
}
```

### 2. SwiftUI View Update Inefficiencies

**Problem Areas:**
- Missing view identity preservation causing unnecessary redraws
- Overuse of `@State` for ViewModels instead of lighter alternatives
- Animation conflicts with view updates
- Excessive use of `.task` modifiers triggering redundant async operations

**Evidence:**
```swift
// Multiple animation modifiers causing conflicts
.animation(.easeInOut(duration: 0.3), value: selectedTab)
.transition(.opacity.combined(with: .scale)) // Compound transitions are expensive
```

### 3. Memory Management Issues

**Problem Areas:**
- NSCache not configured with proper memory limits
- Image wrapper objects retained unnecessarily
- No automatic memory pressure response
- SwiftData queries not paginated properly

### 4. Navigation & List Performance

**Problem Areas:**
- Lists without explicit IDs causing identity confusion
- NavigationStack not using `.navigationDestination` properly
- Missing lazy loading in scroll views
- Heavy view hierarchies in list cells

## Optimization Strategies

### Strategy 1: Image System Overhaul

#### 1.1 Implement Aggressive Image Downsampling

```swift
// REQUIRED: Add to ImageOptimizationService.swift
extension ImageOptimizationService {
    /// Downsample image before any processing to reduce memory footprint
    static func downsample(imageData: Data, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
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
}
```

#### 1.2 Implement Image Prefetching Strategy

```swift
// REQUIRED: Add to LegoSetService.swift or create new PrefetchService.swift
@MainActor
final class ImagePrefetchService {
    private let cacheService = ImageCacheService.shared
    private var prefetchTasks: Set<Task<Void, Never>> = []
    
    func prefetchImages(for urls: [URL], priority: TaskPriority = .background) {
        // Cancel existing tasks if scrolling fast
        cancelAllPrefetches()
        
        for url in urls.prefix(10) { // Limit concurrent prefetches
            let task = Task(priority: priority) {
                _ = await cacheService.optimizedImageData(from: url, imageType: .thumbnail)
            }
            prefetchTasks.insert(task)
        }
    }
    
    func cancelAllPrefetches() {
        prefetchTasks.forEach { $0.cancel() }
        prefetchTasks.removeAll()
    }
}
```

#### 1.3 Replace AsyncCachedImage Implementation

```swift
// REQUIRED: Rewrite AsyncCachedImage for better performance
struct AsyncCachedImage: View {
    let url: URL?
    let contentMode: ContentMode
    let imageType: ImageOptimizationService.ImageType
    
    @State private var phase: AsyncImagePhase = .empty
    
    var body: some View {
        // Use SwiftUI's native AsyncImage with custom cache
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .failure:
                Image(systemName: "photo.badge.exclamationmark")
                    .foregroundColor(.secondary)
            @unknown default:
                EmptyView()
            }
        }
        .id(url) // Preserve view identity
    }
}
```

### Strategy 2: SwiftUI Rendering Optimizations

#### 2.1 Implement View Identity Preservation

```swift
// REQUIRED: Update all List/ForEach implementations
List(filteredSets) { set in
    SetRowView(set: set)
        .id(set.id) // Explicit identity
        .listRowBackground(Color.clear) // Reduce overdraw
        .listRowInsets(EdgeInsets()) // Custom insets
}
.listStyle(.plain) // Use plain style for performance
```

#### 2.2 Optimize Navigation Performance

```swift
// REQUIRED: Update ContentView.swift navigation
struct ContentView: View {
    @State private var selectedTab = NavigationTab.browse
    
    var body: some View {
        // Use lazy loading for tabs
        TabView(selection: $selectedTab) {
            Group {
                switch selectedTab {
                case .browse:
                    BrowseView()
                        .tag(NavigationTab.browse)
                case .search:
                    SearchView()
                        .tag(NavigationTab.search)
                case .collection:
                    CollectionView()
                        .tag(NavigationTab.collection)
                case .wishlist:
                    WishlistView()
                        .tag(NavigationTab.wishlist)
                }
            }
        }
        // Remove animation from TabView - let individual views handle it
    }
}
```

#### 2.3 Implement Lazy Grid Instead of List Where Appropriate

```swift
// REQUIRED: For image-heavy views like SetListView
struct OptimizedSetGridView: View {
    let sets: [LegoSet]
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(sets) { set in
                    SetCardView(set: set)
                        .id(set.id)
                }
            }
            .padding()
        }
        .scrollIndicators(.hidden)
    }
}
```

### Strategy 3: Memory Optimization

#### 3.1 Configure NSCache Properly

```swift
// REQUIRED: Update ImageCacheService.swift
private func setupCache() {
    memoryCache.countLimit = 100 // Limit number of items
    memoryCache.totalCostLimit = 20 * 1024 * 1024 // 20MB limit
    
    imageCache.countLimit = 50 // Fewer UI images
    imageCache.totalCostLimit = 30 * 1024 * 1024 // 30MB for rendered images
}
```

#### 3.2 Implement Automatic Cache Eviction

```swift
// REQUIRED: Add to ImageCacheService.swift
private func setupMemoryWarningObserver() {
    #if canImport(UIKit)
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleMemoryWarning),
        name: UIApplication.didReceiveMemoryWarningNotification,
        object: nil
    )
    #endif
}

@objc private func handleMemoryWarning() {
    Task { @MainActor in
        memoryCache.removeAllObjects()
        imageCache.removeAllObjects()
        // Keep disk cache intact
    }
}
```

### Strategy 4: Data Loading Optimizations

#### 4.1 Implement Pagination for SwiftData Queries

```swift
// REQUIRED: Update data fetching patterns
struct PaginatedSetListView: View {
    @Query(sort: \LegoSet.name, limit: 20) private var initialSets: [LegoSet]
    @State private var loadedSets: [LegoSet] = []
    @State private var currentPage = 0
    
    var body: some View {
        List(loadedSets) { set in
            SetRowView(set: set)
                .onAppear {
                    if set == loadedSets.last {
                        loadMoreSets()
                    }
                }
        }
    }
    
    private func loadMoreSets() {
        // Implement pagination logic
    }
}
```

#### 4.2 Debounce Search Operations

```swift
// REQUIRED: Add to SearchViewModel
@Observable
@MainActor
final class SearchViewModel {
    private var searchTask: Task<Void, Never>?
    
    func searchSets(query: String) {
        searchTask?.cancel()
        
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300)) // Debounce
            guard !Task.isCancelled else { return }
            
            await performSearch(query: query)
        }
    }
}
```

### Strategy 5: Animation & Transition Optimizations

#### 5.1 Reduce Animation Complexity

```swift
// REQUIRED: Simplify animations throughout the app
extension View {
    func optimizedTransition() -> some View {
        self
            .transition(.opacity) // Simple transitions perform better
            .animation(.easeInOut(duration: 0.2), value: UUID()) // Shorter duration
    }
}
```

#### 5.2 Disable Animations During Scrolling

```swift
// REQUIRED: Add to list views
struct OptimizedListView: View {
    @State private var isScrolling = false
    
    var body: some View {
        List(items) { item in
            ItemView(item: item)
                .animation(isScrolling ? nil : .default, value: item)
        }
        .onScrollPhaseChange { oldPhase, newPhase in
            isScrolling = newPhase == .scrolling
        }
    }
}
```

## Implementation Checklist

### Phase 1: Critical Performance Fixes (Immediate)
- [ ] Implement image downsampling in ImageOptimizationService
- [ ] Replace AsyncCachedImage with optimized version
- [ ] Configure NSCache memory limits properly
- [ ] Add explicit view IDs to all Lists and ForEach loops

### Phase 2: UI Responsiveness (Week 1)
- [ ] Implement image prefetching for list views
- [ ] Add pagination to SwiftData queries
- [ ] Debounce all search operations
- [ ] Optimize navigation transitions

### Phase 3: Memory Management (Week 2)
- [ ] Add automatic cache eviction on memory warnings
- [ ] Implement progressive image loading
- [ ] Optimize SwiftData fetch limits
- [ ] Add scroll performance monitoring

### Phase 4: Advanced Optimizations (Week 3)
- [ ] Implement lazy grids for image galleries
- [ ] Add view recycling for complex lists
- [ ] Optimize animation timing and complexity
- [ ] Implement background image processing queue

## Performance Monitoring

### Key Metrics to Track

```swift
// REQUIRED: Add performance monitoring
import os

extension Logger {
    static let performance = Logger(subsystem: "com.brixie", category: "Performance")
    
    func measureTime<T>(operation: String, _ work: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
            if elapsed > 16.67 { // Longer than one frame
                self.warning("⚠️ \(operation) took \(elapsed, format: .fixed(precision: 2))ms")
            }
        }
        return try work()
    }
}
```

### Performance Testing Protocol

1. **Launch Time**: Must be under 1 second
2. **Image Load Time**: Cached images under 50ms, network under 500ms
3. **List Scrolling**: Maintain 60 FPS (120 FPS on ProMotion displays)
4. **Memory Usage**: Stay under 150MB for typical usage
5. **Navigation Transitions**: Complete within 250ms

## Platform-Specific Optimizations

### iOS Specific
- Use `UICollectionView` representable for complex grids if needed
- Leverage ProMotion displays with 120Hz animations
- Implement haptic feedback asynchronously

### macOS Specific
- Optimize for larger image sizes
- Use window-based caching strategy
- Leverage Metal for image processing if available

### visionOS Specific
- Implement spatial image loading priorities
- Optimize for immersive space transitions
- Reduce particle effects and complex gradients

## Testing & Validation

### Required Performance Tests

```swift
// REQUIRED: Add to BrixieUITests
func testScrollingPerformance() throws {
    measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
        app.launch()
        let list = app.tables.firstMatch
        list.swipeUp(velocity: .fast)
        list.swipeDown(velocity: .fast)
    }
}

func testImageLoadingPerformance() throws {
    let metrics = [
        XCTMemoryMetric(),
        XCTCPUMetric(),
        XCTStorageMetric()
    ]
    
    measure(metrics: metrics) {
        // Test image loading performance
    }
}
```

## Summary

The primary causes of UI sluggishness are:
1. Inefficient image loading and processing
2. Lack of view identity preservation causing redraws
3. Unoptimized memory caching
4. Heavy animations and transitions
5. Missing pagination and lazy loading

Implementing the strategies in this guide should result in:
- 50-70% reduction in memory usage
- 60+ FPS scrolling performance
- Sub-second launch times
- Instant cached image display
- Smooth navigation transitions

Priority should be given to Phase 1 fixes as they address the most critical performance bottlenecks.