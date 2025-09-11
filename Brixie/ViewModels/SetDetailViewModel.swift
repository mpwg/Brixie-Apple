//
//  SetDetailViewModel.swift
//  Brixie
//
//  Created by Claude on 06.09.25.
//

import Foundation

@Observable
@MainActor
final class SetDetailViewModel: ViewModelErrorHandling {
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
        } catch {
            handleError(error)
        }
    }
    
    func toggleFavorite() async {
        do {
            try await toggleFavoriteOnRepository(set: set, repository: legoSetRepository)
            set.isFavorite.toggle()
        } catch {
            handleError(error)
        }
    }
    
    var formattedYear: String {
        String(set.year)
    }
    
    var formattedParts: String {
        Strings.piecesCount(set.numParts).localized
    }
    
    var setNumber: String {
        Strings.setNumber(set.setNum).localized
    }
}
