//
//  LocalDataSource.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation
import SwiftData

protocol LocalDataSource {
    func save<T: PersistentModel>(_ items: [T]) throws
    func fetch<T: PersistentModel>(_ type: T.Type) throws -> [T]
    func fetch<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?) throws -> [T]
    func delete<T: PersistentModel>(_ item: T) throws
    func deleteAll<T: PersistentModel>(_ type: T.Type) throws
    
    // Sync timestamp methods
    func saveSyncTimestamp(_ timestamp: SyncTimestamp) throws
    func getLastSyncTimestamp(for syncType: SyncType) throws -> SyncTimestamp?
    func getAllSyncTimestamps() throws -> [SyncTimestamp]
}

final class SwiftDataSource: LocalDataSource {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save<T: PersistentModel>(_ items: [T]) throws {
        for item in items {
            modelContext.insert(item)
        }
        
        do {
            try modelContext.save()
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
    
    func fetch<T: PersistentModel>(_ type: T.Type) throws -> [T] {
        do {
            let descriptor = FetchDescriptor<T>()
            return try modelContext.fetch(descriptor)
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
    
    func fetch<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?) throws -> [T] {
        do {
            var descriptor = FetchDescriptor<T>()
            if let predicate = predicate {
                descriptor.predicate = predicate
            }
            return try modelContext.fetch(descriptor)
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
    
    func delete<T: PersistentModel>(_ item: T) throws {
        modelContext.delete(item)
        
        do {
            try modelContext.save()
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
    
    func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        do {
            try modelContext.delete(model: type)
            try modelContext.save()
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
    
    // MARK: - Sync Timestamp Methods
    
    func saveSyncTimestamp(_ timestamp: SyncTimestamp) throws {
        // Update existing or insert new
        if let existingTimestamp = try? getLastSyncTimestamp(for: timestamp.syncType) {
            existingTimestamp.lastSync = timestamp.lastSync
            existingTimestamp.isSuccessful = timestamp.isSuccessful
            existingTimestamp.itemCount = timestamp.itemCount
        } else {
            modelContext.insert(timestamp)
        }
        
        do {
            try modelContext.save()
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
    
    func getLastSyncTimestamp(for syncType: SyncType) throws -> SyncTimestamp? {
        do {
            let predicate = #Predicate<SyncTimestamp> { $0.syncType == syncType }
            var descriptor = FetchDescriptor<SyncTimestamp>(predicate: predicate)
            descriptor.sortBy = [SortDescriptor(\.lastSync, order: .reverse)]
            descriptor.fetchLimit = 1
            
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
    
    func getAllSyncTimestamps() throws -> [SyncTimestamp] {
        do {
            var descriptor = FetchDescriptor<SyncTimestamp>()
            descriptor.sortBy = [SortDescriptor(\.lastSync, order: .reverse)]
            return try modelContext.fetch(descriptor)
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
}
