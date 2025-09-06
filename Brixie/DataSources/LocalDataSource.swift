//
//  LocalDataSource.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation
import SwiftData

protocol LocalDataSource: Sendable {
    func save<T: PersistentModel>(_ items: [T]) async throws
    func fetch<T: PersistentModel>(_ type: T.Type) async throws -> [T]
    func fetch<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?) async throws -> [T]
    func delete<T: PersistentModel>(_ item: T) async throws
    func deleteAll<T: PersistentModel>(_ type: T.Type) async throws
}

@ModelActor
final actor SwiftDataSource: LocalDataSource {
    func save<T: PersistentModel>(_ items: [T]) async throws {
        for item in items {
            modelContext.insert(item)
        }
        
        do {
            try modelContext.save()
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
    
    func fetch<T: PersistentModel>(_ type: T.Type) async throws -> [T] {
        do {
            let descriptor = FetchDescriptor<T>()
            return try modelContext.fetch(descriptor)
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
    
    func fetch<T: PersistentModel>(_ type: T.Type, predicate: Predicate<T>?) async throws -> [T] {
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
    
    func delete<T: PersistentModel>(_ item: T) async throws {
        modelContext.delete(item)
        
        do {
            try modelContext.save()
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
    
    func deleteAll<T: PersistentModel>(_ type: T.Type) async throws {
        do {
            try modelContext.delete(model: type)
            try modelContext.save()
        } catch {
            throw BrixieError.persistenceError(underlying: error)
        }
    }
}