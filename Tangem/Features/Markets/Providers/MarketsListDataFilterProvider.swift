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

    private var _intervalTypeValue: CurrentValueSubject<MarketsPriceIntervalType, Never>
    private var _orderTypeValue: CurrentValueSubject<MarketsListOrderType, Never>
    private var _categorySelectionValue: CurrentValueSubject<CategorySelection?, Never> = .init(nil)

    private var bag = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        initialOrderType: MarketsListOrderType? = nil,
        initialIntervalType: MarketsPriceIntervalType? = nil,
        supportedOrderTypes: [MarketsListOrderType] = MarketsListOrderType.allCases
    ) {
        _intervalTypeValue = .init(initialIntervalType ?? .day)
        _orderTypeValue = .init(initialOrderType ?? .rating)
        self.supportedOrderTypes = supportedOrderTypes

        bind()
    }

    // MARK: - Public Properties

    var filterPublisher: some Publisher<MarketsListDataProvider.Filter, Never> {
        Publishers.CombineLatest3(_intervalTypeValue, _orderTypeValue, _categorySelectionValue)
            .map { interval, order, categorySelection in
                Self.makeFilter(interval: interval, order: order, categorySelection: categorySelection)
            }
    }

    /// It is necessary to obtain initial values in consumers in order to avoid optionals
    var currentFilterValue: MarketsListDataProvider.Filter {
        Self.makeFilter(
            interval: _intervalTypeValue.value,
            order: _orderTypeValue.value,
            categorySelection: _categorySelectionValue.value
        )
    }

    /// This is necessary to determine the supported values in case of expansion
    let supportedOrderTypes: [MarketsListOrderType]

    /// This is necessary to determine the supported values in case of expansion
    var supportedPriceIntervalTypes: [MarketsPriceIntervalType] {
        [.day, .week, .month]
    }

    func didSelectMarketPriceInterval(_ interval: MarketsPriceIntervalType) {
        _intervalTypeValue.send(interval)
    }

    func didSelectMarketOrder(_ option: MarketsListOrderType) {
        _orderTypeValue.send(option)
    }

    func didSelectCategory(_ selection: CategorySelection?) {
        _categorySelectionValue.send(selection)
    }

    // MARK: - Private Implementation

    private func bind() {
        Publishers.Merge(
            _orderTypeValue.removeDuplicates().dropFirst().map { _ in () },
            _intervalTypeValue.removeDuplicates().dropFirst().map { _ in () }
        )
        .withWeakCaptureOf(self)
        .sink { provider, _ in
            provider.sendAnalytics()
        }
        .store(in: &bag)
    }

    private static func makeFilter(
        interval: MarketsPriceIntervalType,
        order: MarketsListOrderType,
        categorySelection: CategorySelection?
    ) -> MarketsListDataProvider.Filter {
        MarketsListDataProvider.Filter(
            interval: interval,
            order: order,
            categoryId: categorySelection?.categoryId,
            sectorId: categorySelection?.sectorId,
            country: categorySelection?.country
        )
    }

    private func sendAnalytics() {
        Analytics.log(
            event: .marketsTokensSort,
            params: [
                .type: _orderTypeValue.value.analyticsValue.capitalizingFirstLetter(),
                .period: _intervalTypeValue.value.rawValue,
            ]
        )
    }
}

extension MarketsListDataFilterProvider {
    struct CategorySelection: Hashable {
        let categoryId: Int
        let sectorId: Int?
        let country: String?
    }
}
