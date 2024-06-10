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

//    private lazy var filter: MarketsListDataProvider.Filter = .init(interval: _intervalTypeValue.value, order: _orderTypeValue.value)

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
        MarketsPriceIntervalType.allCases
    }

    // Since the sorting selection is made in a separate screen, a closure is required
    var onUpdateOrderAction: (() -> Void)?
}

// MARK: - MarketRaitingHeaderViewModelDelegate

extension MarketsListDataFilterProvider: MarketRaitingHeaderViewModelDelegate {
    func marketOrderActionButtonDidTap() {
        onUpdateOrderAction?()
    }

    func marketPriceIntervalButtonDidTap(_ interval: MarketsPriceIntervalType) {
        _intervalTypeValue.send(interval)
    }
}

// MARK: - MarketsListOrderBottonSheetViewModelDelegate

extension MarketsListDataFilterProvider: MarketsListOrderBottonSheetViewModelDelegate {
    func didSelect(option: MarketsListOrderType) {
        _orderTypeValue.send(option)
    }
}
