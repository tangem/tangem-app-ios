//
//  CardsInfoPagerPreviewProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class CardsInfoPagerPreviewProvider: ObservableObject {
    @Published var pages: [CardInfoPagePreviewViewModel] = []

    private lazy var headerPreviewProvider = FakeCardHeaderPreviewProvider()

    init() {
        initializeModels()
    }

    private func initializeModels() {
        pages = headerPreviewProvider.models.map(CardInfoPagePreviewViewModel.init)
    }
}
