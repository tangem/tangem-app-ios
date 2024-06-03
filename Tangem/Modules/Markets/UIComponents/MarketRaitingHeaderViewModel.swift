//
//  MarketRaitingHeaderViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketRaitingHeaderViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var marketListOrderType: MarketsListOrderType
    @Published var marketPriceIntervalType: MarketsPriceIntervalType

    var marketOrderActionButtonDidTap: (() -> Void)?
    var marketPriceIntervalButtonDidTap: ((MarketsPriceIntervalType) -> Void)?

    // MARK: - Private Properties

    private var subscription: AnyCancellable?

    // MARK: - Init

    init(
        from filter: MarketsListDataProvider.Filter,
        marketOrderActionButtonDidTap: (() -> Void)?,
        marketPriceIntervalButtonDidTap: ((MarketsPriceIntervalType) -> Void)?
    ) {
        marketListOrderType = filter.order
        marketPriceIntervalType = filter.interval

        self.marketOrderActionButtonDidTap = marketOrderActionButtonDidTap
        self.marketPriceIntervalButtonDidTap = marketPriceIntervalButtonDidTap

        bind()
    }

    func bind() {
        subscription = $marketPriceIntervalType
            .removeDuplicates()
            .sink { [weak self] in
                self?.marketPriceIntervalButtonDidTap?($0)
            }
    }
}
