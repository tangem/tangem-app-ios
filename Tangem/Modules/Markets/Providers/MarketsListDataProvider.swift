//
//  MarketsListDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemSdk
import BlockchainSdk

final class MarketsListDataProvider {
    // MARK: Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: Published Properties

    @Published var items: [MarketsTokenModel] = []
    @Published var isLoading: Bool = false

    // MARK: - Public Properties

    var lastSearchTextValue: String? {
        return lastSearchText
    }

    var lastFilterValue: Filter? {
        return lastFilter
    }

    // Tells if all items have been loaded
    var canFetchMore: Bool {
        if isLoading {
            return false
        }

        guard let totalTokensCount else {
            return true
        }

        let countPages = totalTokensCount / limitPerPage
        return currentOffset < countPages
    }

    // MARK: Private Properties

    // Tracks last page ofsset loaded. Used to load next page (current + 1)
    private var currentOffset: Int = 0

    // Limit of records per page
    private let limitPerPage: Int = 20

    // Total tokens value by pages
    private var totalTokensCount: Int?

    private var lastSearchText: String?
    private var lastFilter: Filter?

    private var selectedCurrencyCode: String {
        AppSettings.shared.selectedCurrencyCode
    }

    // MARK: - Implementation

    func reset(_ searchText: String?, with filter: Filter?) {
        AppLog.shared.debug("\(String(describing: self)) reset market list tokens")

        lastSearchText = searchText
        lastFilter = filter

        items = []
        currentOffset = 0
        totalTokensCount = nil

        isLoading = false
    }

    func fetch(_ searchText: String, with filter: Filter, generalCoins: Bool = false) {
        if lastSearchText != searchText || filter != lastFilter {
            reset(searchText, with: filter)
        }

        isLoading = true

        runTask(in: self) { provider in
            let response: MarketsDTO.General.Response

            do {
                response = try await provider.loadItems(searchText, with: filter, generalCoins: generalCoins)
            } catch {
                AppLog.shared.debug("\(String(describing: provider)) loaded market list tokens did receive error \(error.localizedDescription)")
                provider.isLoading = false
                return
            }

            await runOnMain {
                AppLog.shared.debug("\(String(describing: provider)) loaded market list tokens with count = \(response.tokens.count)")

                provider.currentOffset = response.offset + response.limit
                provider.totalTokensCount = response.total

                provider.isLoading = false

                self.items.append(contentsOf: response.tokens)
            }
        }
    }

    func fetchMore() {
        if let lastSearchText, let lastFilter {
            fetch(lastSearchText, with: lastFilter)
        } else {
            AppLog.shared.debug("\(String(describing: self)) error optional parameter lastSearchText or lastFilter")
        }
    }
}

// MARK: Private

private extension MarketsListDataProvider {
    func loadItems(_ searchText: String, with filter: Filter, generalCoins: Bool) async throws -> MarketsDTO.General.Response {
        let searchText = searchText.trimmed()

        let requestModel = MarketsDTO.General.Request(
            currency: selectedCurrencyCode,
            offset: currentOffset,
            limit: limitPerPage,
            interval: filter.interval,
            order: filter.order,
            generalCoins: generalCoins,
            search: searchText
        )

        AppLog.shared.debug("\(String(describing: self)) loading market list tokens with request \(requestModel.parameters.debugDescription)")

        return try await tangemApiService.loadMarkets(requestModel: requestModel)
    }
}

extension MarketsListDataProvider {
    final class Filter: Hashable, Equatable {
        var interval: MarketsPriceIntervalType = .day
        var order: MarketsListOrderType = .rating

        init(interval: MarketsPriceIntervalType, order: MarketsListOrderType) {
            self.interval = interval
            self.order = order
        }

        // MARK: - Hashable

        func hash(into hasher: inout Hasher) {
            hasher.combine(interval.id)
            hasher.combine(order.rawValue)
        }

        // MARK: - Equatable

        static func == (lhs: MarketsListDataProvider.Filter, rhs: MarketsListDataProvider.Filter) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
}
