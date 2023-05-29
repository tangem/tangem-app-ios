//
//  CardInfoPagePreviewViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class CardInfoPagePreviewViewModel: ObservableObject {
    @Published var cellViewModels: [CardInfoPageCellPreviewViewModel] = []

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
