//
//  MarketsListDataFilterProvider.swift
//  Tangem
//
//  Created by skibinalexander on 04.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class MarketsListDataFilterProvider {
    // MARK: - Private Properties

    private var _intervalTypeValue: CurrentValueSubject<MarketsPriceIntervalType, Never> = .init(.day)
    private var _orderTypeValue: CurrentValueSubject<MarketsListOrderType, Never> = .init(.rating)

    // MARK: - Public Properties

    var intervalType: MarketsPriceIntervalType { _intervalTypeValue.value }
    var orderType: MarketsListOrderType { _orderTypeValue.value }

    var filterPublisher: some Publisher<MarketsListDataProvider.Filter, Never> {
        Publishers.CombineLatest(_intervalTypeValue, _orderTypeValue)
            .map { interval, order in
                MarketsListDataProvider.Filter(interval: interval, order: order)
            }
    }

    var supportedOrderTypes: [MarketsListOrderType] {
        MarketsListOrderType.allCases
    }

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
