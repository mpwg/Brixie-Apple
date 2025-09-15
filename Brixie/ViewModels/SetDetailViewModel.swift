import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class SetDetailViewModel {
    var legoSet: LegoSet?
    var isLoading: Bool = false
    var error: BrixieError?

    private let di: DIContainer
    private var setNum: String

    init(di: DIContainer, setNum: String) {
        self.di = di
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
            let repo = di.makeLegoSetRepository()
            let fetched = try await repo.getSetDetails(setNum: setNum)
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
