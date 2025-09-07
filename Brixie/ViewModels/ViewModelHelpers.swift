//
//  ViewModelHelpers.swift
//  Brixie
//
//  Shared helpers for view models: centralized error handling and favorite toggle logic
//

import Foundation

@MainActor
protocol ViewModelErrorHandling: AnyObject {
    var error: BrixieError? { get set }
}

@MainActor
extension ViewModelErrorHandling {
    func handleError(_ error: Error) {
        if let brixieError = error as? BrixieError {
            self.error = brixieError
        } else {
            self.error = BrixieError.networkError(underlying: error)
        }
    }
}

@MainActor
func toggleFavoriteOnRepository(set: LegoSet, repository: LegoSetRepository) async throws {
    if set.isFavorite {
        try await repository.removeFromFavorites(set)
    } else {
        try await repository.markAsFavorite(set)
    }
}
