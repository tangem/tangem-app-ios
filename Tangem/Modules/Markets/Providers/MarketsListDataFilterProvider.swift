//
//  MarketsListDataFilterProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsListDataFilterProvider {
    // MARK: - Private Properties

    private var _intervalTypeValue: CurrentValueSubject<MarketsPriceIntervalType, Never> = .init(.day)
    private var _orderTypeValue: CurrentValueSubject<MarketsListOrderType, Never> = .init(.rating)

    // MARK: - Public Properties

    var filterPublisher: some Publisher<MarketsListDataProvider.Filter, Never> {
        Publishers.CombineLatest(_intervalTypeValue, _orderTypeValue)
            .map { interval, order in
                MarketsListDataProvider.Filter(interval: interval, order: order)
            }
    }

    // It is necessary to obtain initial values in consumers in order to avoid optionals
    var currentFilterValue: MarketsListDataProvider.Filter {
        .init(interval: _intervalTypeValue.value, order: _orderTypeValue.value)
    }

    // This is necessary to determine the supported values in case of expansion
    var supportedOrderTypes: [MarketsListOrderType] {
        MarketsListOrderType.allCases
    }

    // This is necessary to determine the supported values in case of expansion
    var supportedPriceIntervalTypes: [MarketsPriceIntervalType] {
        [.day, .week, .month]
    }

    func didSelectMarketPriceInterval(_ interval: MarketsPriceIntervalType) {
        sendAnalytics()
        _intervalTypeValue.send(interval)
    }

    func didSelectMarketOrder(_ option: MarketsListOrderType) {
        sendAnalytics()
        _orderTypeValue.send(option)
    }

    // MARK: - Private Implementation

    private func sendAnalytics() {
        Analytics.log(
            event: .marketsTokensSort,
            params: [
                .type: _orderTypeValue.value.rawValue.capitalizingFirstLetter(),
                .period: _intervalTypeValue.value.rawValue,
            ]
        )
    }
}
