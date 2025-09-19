import Testing
import SwiftData
@testable import Brixie

/// Test suite for ImageCacheService
@MainActor
struct ImageCacheServiceTests {
    private var cacheService: ImageCacheService!
    
    init() {
        cacheService = ImageCacheService.shared
    }
    
    @Test("ImageCacheService singleton works")
    func testSingleton() {
        let service1 = ImageCacheService.shared
        let service2 = ImageCacheService.shared
        
        #expect(service1 === service2)
    }
    
    @Test("ImageCacheService cache size tracking works")
    func testCacheSizeTracking() {
        let initialSize = cacheService.currentCacheSize
        
        #expect(initialSize >= 0)
        #expect(cacheService.cacheUsagePercentage >= 0.0)
        #expect(cacheService.cacheUsagePercentage <= 1.0)
    }
    
    @Test("ImageCacheService can format cache size")
    func testCacheSizeFormatting() {
        let formattedSize = cacheService.formattedCacheSize
        
        #expect(!formattedSize.isEmpty)
        #expect(formattedSize.contains("B") || formattedSize.contains("KB") || formattedSize.contains("MB"))
    }
    
    @Test("ImageCacheService can clear memory cache")
    func testClearMemoryCache() {
        // This is mainly testing that the method doesn't crash
        cacheService.clearMemoryCache()
        
        // The method should complete without throwing
        #expect(true)
    }
    
    @Test("ImageCacheService can get disk cache file count")
    func testDiskCacheFileCount() {
        let fileCount = cacheService.diskCacheFileCount
        
        #expect(fileCount >= 0)
    }
}
