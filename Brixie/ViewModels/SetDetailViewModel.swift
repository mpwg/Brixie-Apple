import Foundation
import SwiftData
import SwiftUI


@Observable
@MainActor
final class SetDetailViewModel {
    var legoSet: LegoSet?
    var isLoading: Bool = false
    var error: BrixieError?

    private let repository: LegoSetRepository
    private var setNum: String

    init(repository: LegoSetRepository, setNum: String) {
        self.repository = repository
        self.setNum = setNum
    }

    func updateForSetNum(_ newSetNum: String) async {
        guard newSetNum != setNum else { return }
        setNum = newSetNum
        await loadDetails()
    }

    func loadDetails() async {
        isLoading = true
        error = nil
        legoSet = nil

        do {
            let fetched = try await repository.getSetDetails(setNum: setNum)
            legoSet = fetched
        } catch {
            if let brixieError = error as? BrixieError {
                self.error = brixieError
            } else {
                self.error = .networkError(underlying: error)
            }
        }

        isLoading = false
    }

    func retry() async {
        await loadDetails()
    }
}
