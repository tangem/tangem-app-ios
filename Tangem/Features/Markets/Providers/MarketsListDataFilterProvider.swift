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
    private let analyticsSection: Analytics.MarketsSection?

    // MARK: - Initialization

    init(
        initialOrderType: MarketsListOrderType? = nil,
        initialIntervalType: MarketsPriceIntervalType? = nil,
        supportedOrderTypes: [MarketsListOrderType] = MarketsListOrderType.allCases,
        analyticsSection: Analytics.MarketsSection? = nil
    ) {
        _intervalTypeValue = .init(initialIntervalType ?? .day)
        _orderTypeValue = .init(initialOrderType ?? .rating)
        self.supportedOrderTypes = supportedOrderTypes
        self.analyticsSection = analyticsSection
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
        let hasChanged = _intervalTypeValue.value != interval
        _intervalTypeValue.send(interval)

        if hasChanged {
            sendAnalytics()
        }
    }

    /// Pass `isUserInitiated: false` when the order is changed by the app itself, e.g. a filter that dropped
    /// the current sort; the sort analytics event must only reflect the user's taps.
    func didSelectMarketOrder(_ option: MarketsListOrderType, isUserInitiated: Bool = true) {
        let hasChanged = _orderTypeValue.value != option
        _orderTypeValue.send(option)

        if hasChanged, isUserInitiated {
            sendAnalytics()
        }
    }

    func didSelectCategory(_ selection: CategorySelection?) {
        _categorySelectionValue.send(selection)
    }

    // MARK: - Private Implementation

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
            geckoCategoryId: categorySelection?.geckoCategoryId,
            country: categorySelection?.country
        )
    }

    private func sendAnalytics() {
        var params: [Analytics.ParameterKey: String] = [
            .type: _orderTypeValue.value.analyticsValue.capitalizingFirstLetter(),
            .period: _intervalTypeValue.value.rawValue,
        ]

        if let analyticsSection {
            params[.section] = analyticsSection.rawValue
        }

        Analytics.log(event: .marketsTokensSort, params: params)
    }
}

extension MarketsListDataFilterProvider {
    /// Either a curated coin category (with an optional sector) or a CoinGecko category; the list endpoint
    /// rejects the two together, so a selection carries exactly one of them.
    struct CategorySelection: Hashable {
        let categoryId: Int?
        let sectorId: Int?
        let geckoCategoryId: String?
        let country: String?

        init(categoryId: Int, sectorId: Int?, country: String?) {
            self.categoryId = categoryId
            self.sectorId = sectorId
            geckoCategoryId = nil
            self.country = country
        }

        init(geckoCategoryId: String, country: String?) {
            categoryId = nil
            sectorId = nil
            self.geckoCategoryId = geckoCategoryId
            self.country = country
        }
    }
}
