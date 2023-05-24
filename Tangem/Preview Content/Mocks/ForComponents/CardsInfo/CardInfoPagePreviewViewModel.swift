//
// Copyright © 2023 m3g0byt3
//

import Foundation

final class CardInfoPagePreviewViewModel: ObservableObject {
    @Published
    var cellViewModels: [CardInfoPageCellPreviewViewModel] = []

    init() {
        initializeModels()
    }

    private func initializeModels() {
        let upperBound = Int.random(in: 5 ... 30)
        cellViewModels = (0 ... upperBound).map { _ in
            CardInfoPageCellPreviewViewModel()
        }
    }
}
