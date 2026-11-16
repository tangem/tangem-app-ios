//
//  PolymarketFastTradingBannerMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemPolymarket

struct PolymarketFastTradingBannerMapper {
    let includesForeignSigners: Bool
    var now: () -> Date = { InjectedValues[\.polymarketServerClock].now }

    func mapToBannerPublisher(
        states: AnyPublisher<PolymarketFastTradingState, Never>,
        dismissals: AnyPublisher<PolymarketFastTradingBanner.DismissalDates, Never>
    ) -> AnyPublisher<PolymarketFastTradingBanner?, Never> {
        states
            .combineLatest(dismissals)
            .map { state, dismissals in mapToBanner(state: state, dismissals: dismissals) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func mapToBanner(state: PolymarketFastTradingState, dismissals: PolymarketFastTradingBanner.DismissalDates) -> PolymarketFastTradingBanner? {
        let date = now()

        return PolymarketFastTradingBanner(state: state, includingForeignSigners: includesForeignSigners) { kind in
            kind.isDismissed(dismissedAt: dismissals[kind], now: date)
        }
    }
}
