//
//  SetDetailViewModel.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@Observable
@MainActor
final class SetDetailViewModel {
    private let legoSetRepository: LegoSetRepository
    
    var set: LegoSet
    var isLoadingDetails = false
    var error: BrixieError?
    
    init(set: LegoSet, legoSetRepository: LegoSetRepository) {
        self.set = set
        self.legoSetRepository = legoSetRepository
    }
    
    func loadSetDetails() async {
        isLoadingDetails = true
        error = nil
        
        defer { isLoadingDetails = false }
        
        do {
            if let detailedSet = try await legoSetRepository.getSetDetails(setNum: set.setNum) {
                set = detailedSet
            }
        } catch let brixieError as BrixieError {
            error = brixieError
        } catch {
            self.error = BrixieError.networkError(underlying: error)
        }
    }
    
    func toggleFavorite() async {
        do {
            if set.isFavorite {
                try await legoSetRepository.removeFromFavorites(set)
            } else {
                try await legoSetRepository.markAsFavorite(set)
            }
            
            set.isFavorite.toggle()
        } catch let brixieError as BrixieError {
            error = brixieError
        } catch {
            self.error = BrixieError.networkError(underlying: error)
        }
    }
    
    var formattedYear: String {
        String(set.year)
    }
    
    var formattedParts: String {
        String(format: NSLocalizedString("%d pieces", comment: "Number of pieces"), set.numParts)
    }
    
    var setNumber: String {
        String(format: NSLocalizedString("Set #%@", comment: "Set number display"), set.setNum)
    }
}