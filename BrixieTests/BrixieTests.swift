//
//  BrixieTests.swift
//  BrixieTests
//
//  Created by Matthias Wallner-Géhri on 01.09.25.
//

import Testing
import Foundation
@testable import Brixie

struct BrixieTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}

// MARK: - API Configuration Tests

struct APIConfigurationTests {
    
    @Test("API Configuration Service initialization")
    @MainActor
    func testAPIConfigurationServiceInitialization() async throws {
        let service = APIConfigurationService()
        
        // Service should initialize without errors
        #expect(service != nil)
    }
    
    @Test("API key validation")
    @MainActor
    func testAPIKeyValidation() async throws {
        let service = APIConfigurationService()
        
        // Valid API key format
        let validKey = "abcdef1234567890abcdef1234567890abcdef12"
        #expect(service.isValidAPIKeyFormat(validKey))
        
        // Invalid - too short
        let shortKey = "abc123"
        #expect(!service.isValidAPIKeyFormat(shortKey))
        
        // Invalid - contains special characters
        let invalidKey = "abcdef123456-invalid-key-format!"
        #expect(!service.isValidAPIKeyFormat(invalidKey))
        
        // Invalid - empty
        #expect(!service.isValidAPIKeyFormat(""))
        
        // Invalid - only whitespace
        #expect(!service.isValidAPIKeyFormat("   "))
    }
    
    @Test("User API key override")
    @MainActor
    func testUserAPIKeyOverride() async throws {
        let service = APIConfigurationService()
        let testKey = "abcdef1234567890abcdef1234567890abcdef12"
        
        // Initially no user override
        #expect(!service.hasUserOverride)
        
        // Set user API key
        service.userApiKey = testKey
        #expect(service.hasUserOverride)
        #expect(service.currentAPIKey == testKey)
        
        // Clear user override
        service.clearUserOverride()
        #expect(!service.hasUserOverride)
        #expect(service.userApiKey.isEmpty)
    }
    
    @Test("Configuration status messages")
    @MainActor
    func testConfigurationStatus() async throws {
        let service = APIConfigurationService()
        
        // Initially should show embedded or no key status
        let initialStatus = service.configurationStatus
        #expect(initialStatus.contains("embedded") || initialStatus.contains("No API key"))
        
        // After setting user key
        service.userApiKey = "abcdef1234567890abcdef1234567890abcdef12"
        #expect(service.configurationStatus.contains("custom"))
    }
    
    @Test("Valid API key detection")
    @MainActor
    func testValidAPIKeyDetection() async throws {
        let service = APIConfigurationService()
        
        // Test with valid user key
        service.userApiKey = "abcdef1234567890abcdef1234567890abcdef12"
        #expect(service.hasValidAPIKey)
        
        // Test with empty user key (falls back to embedded)
        service.clearUserOverride()
        // hasValidAPIKey depends on GeneratedConfiguration which may or may not have embedded key
        // This is expected behavior
    }
}

// MARK: - DI Container Tests

struct DIContainerTests {
    
    @Test("DI Container provides API Configuration Service")
    @MainActor
    func testDIContainerProvidesAPIConfiguration() async throws {
        let container = DIContainer.shared
        
        #expect(container.apiConfigurationService != nil)
        #expect(container.apiConfigurationService is APIConfigurationService)
    }
    
    @Test("Remote data sources receive API configuration")
    @MainActor
    func testRemoteDataSourcesReceiveAPIConfiguration() async throws {
        let container = DIContainer.shared
        
        let legoSetDataSource = container.makeLegoSetRemoteDataSource()
        let legoThemeDataSource = container.makeLegoThemeRemoteDataSource()
        
        // Data sources should be created successfully
        #expect(legoSetDataSource != nil)
        #expect(legoThemeDataSource != nil)
        
        // They should be implementation types that accept API configuration
        #expect(legoSetDataSource is LegoSetRemoteDataSourceImpl)
        #expect(legoThemeDataSource is LegoThemeRemoteDataSourceImpl)
    }
    
    @Test("Repositories are properly constructed")
    @MainActor
    func testRepositoryConstruction() async throws {
        let container = DIContainer.shared
        
        let legoSetRepo = container.makeLegoSetRepository()
        let legoThemeRepo = container.makeLegoThemeRepository()
        
        #expect(legoSetRepo != nil)
        #expect(legoThemeRepo != nil)
        #expect(legoSetRepo is LegoSetRepositoryImpl)
        #expect(legoThemeRepo is LegoThemeRepositoryImpl)
    }
    
    @Test("ViewModels are properly constructed")
    @MainActor
    func testViewModelConstruction() async throws {
        let container = DIContainer.shared
        
        let setsListVM = container.makeSetsListViewModel()
        let categoriesVM = container.makeCategoriesViewModel()
        let searchVM = container.makeSearchViewModel()
        
        #expect(setsListVM != nil)
        #expect(categoriesVM != nil)
        #expect(searchVM != nil)
    }
}

// MARK: - Remote Data Source Tests

struct RemoteDataSourceTests {
    
    @Test("LegoSetRemoteDataSource handles missing API key")
    @MainActor
    func testLegoSetRemoteDataSourceMissingAPIKey() async throws {
        // Create service with no API key
        let apiConfig = APIConfigurationService()
        apiConfig.clearUserOverride() // Ensure no user key
        
        let dataSource = LegoSetRemoteDataSourceImpl(apiConfiguration: apiConfig)
        
        // Calls should throw API key missing error when no valid key
        if !apiConfig.hasValidAPIKey {
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.fetchSets(page: 1, pageSize: 20)
            }
            
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.searchSets(query: "test", page: 1, pageSize: 20)
            }
            
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.getSetDetails(setNum: "10001-1")
            }
        }
    }
    
    @Test("LegoThemeRemoteDataSource handles missing API key")
    @MainActor
    func testLegoThemeRemoteDataSourceMissingAPIKey() async throws {
        // Create service with no API key
        let apiConfig = APIConfigurationService()
        apiConfig.clearUserOverride() // Ensure no user key
        
        let dataSource = LegoThemeRemoteDataSourceImpl(apiConfiguration: apiConfig)
        
        // Calls should throw API key missing error when no valid key
        if !apiConfig.hasValidAPIKey {
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.fetchThemes(page: 1, pageSize: 20)
            }
            
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.searchThemes(query: "test", page: 1, pageSize: 20)
            }
            
            await #expect(throws: BrixieError.apiKeyMissing) {
                try await dataSource.getThemeDetails(id: 1)
            }
        }
    }
}
