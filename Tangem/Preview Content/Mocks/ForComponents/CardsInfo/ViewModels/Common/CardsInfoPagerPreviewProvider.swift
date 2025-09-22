//
//  CardsInfoPagerPreviewProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemFoundation
import QuartzCore

final class CardsInfoPagerPreviewProvider: ObservableObject {
    @Published var pages: [CardInfoPagePreviewViewModel] = []
    @Published var isHorizontalScrollDisabled = false

    lazy var refreshScrollViewStateObject: RefreshScrollViewStateObject = .init(refreshable: {
        AppLogger.info("\(self) Starting pull to refresh at \(CACurrentMediaTime())")
        await runOnMain { self.isHorizontalScrollDisabled = true }
        try? await Task.sleep(nanoseconds: 5 * NSEC_PER_SEC)

        AppLogger.info("\(self) Finishing pull to refresh at \(CACurrentMediaTime())")
        await runOnMain { self.isHorizontalScrollDisabled = false }
    })

    private lazy var headerPreviewProvider = FakeCardHeaderPreviewProvider()

    init() {
        initializeModels()
    }

    private func initializeModels() {
        pages = headerPreviewProvider.models.map(CardInfoPagePreviewViewModel.init)
    }
}
