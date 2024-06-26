//
//  MarketsListChartsPreviewProvider.swift
//  Tangem
//
//  Created by skibinalexander on 18.06.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class MarketsListChartsHistoryProvider {
    // MARK: Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: Published Properties

    @Published var items: [String: MarketsChartsHistoryItemModel] = [:]

    // MARK: - Private Properties

    private var selectedCurrencyCode: String {
        AppSettings.shared.selectedCurrencyCode
    }

    // MARK: - Implementation

    func fetch(for coinIds: [String], with interval: MarketsPriceIntervalType) {
        guard !coinIds.isEmpty else {
            return
        }

        runTask(in: self) { provider in
            let response: [String: MarketsChartsHistoryItemModel]

            do {
                // Need for filtered coins already received
                let filteredCoinIds = coinIds.filter { !provider.items.keys.contains($0) }
                response = try await provider.loadItems(for: filteredCoinIds, with: interval)
            } catch {
                AppLog.shared.debug("\(String(describing: provider)) loaded charts history preview list tokens did receive error \(error.localizedDescription)")
                return
            }

            AppLog.shared.debug("\(String(describing: provider)) loaded charts history preview tokens with count = \(response.count)")

            for (key, value) in response {
                self.items[key] = value
            }
        }
    }
}

// MARK: Private

private extension MarketsListChartsHistoryProvider {
    func loadItems(for coinIds: [String], with interval: MarketsPriceIntervalType) async throws -> [String: MarketsChartsHistoryItemModel] {
        let requestModel = MarketsDTO.ChartsHistory.Request(
            currency: selectedCurrencyCode,
            coinIds: coinIds,
            interval: interval
        )

        AppLog.shared.debug("\(String(describing: self)) loading market list tokens with request \(requestModel.parameters.debugDescription)")

        return try await tangemApiService.loadCoinsHistoryPreview(requestModel: requestModel)
    }
}
