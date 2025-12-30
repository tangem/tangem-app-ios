//
//  MarketsListChartsPreviewProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class MarketsListChartsHistoryProvider {
    typealias TokensChartsHistory = [String: [MarketsPriceIntervalType: MarketsChartModel]]

    private static let maxNumberOfItemsPerRequest = 200

    private let lock = OSAllocatedUnfairLock()
    private let logger = AppLogger.tag("\(MarketsListChartsHistoryProvider.self)")

    private var requestedItemsDictionary: [MarketsPriceIntervalType: Set<String>] = [:]

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private var selectedCurrencyCode: String {
        AppSettings.shared.selectedCurrencyCode
    }

    // MARK: Published Properties

    @MainActor
    @Published private(set) var items: TokensChartsHistory = [:]

    // MARK: - Implementation

    func fetch(for coinIds: [String], with interval: MarketsPriceIntervalType) {
        if coinIds.isEmpty {
            return
        }

        Task(priority: .medium) { [weak self] in
            guard let strongSelf = self else { return }

            let filteredItems = strongSelf.filterItemsToRequest(coinIds, fromItems: await strongSelf.items, interval: interval)

            do {
                if filteredItems.isEmpty {
                    strongSelf.logger.info("Filtered items list to request is empty. Skip loading")
                    return
                }

                strongSelf.logger.info("Filtered items list to request is not empty. Attempting to fetch \(filteredItems.count) items")

                let responses = try await strongSelf.fetchItems(ids: filteredItems, interval: interval)
                var copyItems: TokensChartsHistory = await strongSelf.items

                for response in responses {
                    for (key, value) in response {
                        copyItems[key, default: [:]][interval] = value
                    }
                }

                await MainActor.run { [copyItems] in
                    strongSelf.items = copyItems
                }
            } catch {
                strongSelf.logger.info("Loaded charts history preview list tokens did receive error \(error.localizedDescription)")
            }

            strongSelf.registerLoadedItems(requestedItemsIds: filteredItems, interval: interval)
        }
    }
}

// MARK: Private

private extension MarketsListChartsHistoryProvider {
    func filterItemsToRequest(
        _ newItemsToRequest: [String],
        fromItems items: TokensChartsHistory,
        interval: MarketsPriceIntervalType
    ) -> [String] {
        let notLoadedItems = newItemsToRequest.filter { items[$0]?[interval] == nil }
        return lock {
            guard let alreadyRequestedItemsForInterval = requestedItemsDictionary[interval] else {
                requestedItemsDictionary[interval] = notLoadedItems.toSet()
                return notLoadedItems
            }

            let filteredList = notLoadedItems.filter { tokenId in
                let alreadyRequested = alreadyRequestedItemsForInterval.contains(tokenId)
                return !alreadyRequested
            }
            requestedItemsDictionary[interval] = alreadyRequestedItemsForInterval.union(filteredList)
            return filteredList
        }
    }

    func registerLoadedItems(requestedItemsIds: [String], interval: MarketsPriceIntervalType) {
        lock {
            guard var requestedItems = requestedItemsDictionary[interval] else {
                assertionFailure("Requested items should contains items for provided interval")
                return
            }

            requestedItemsIds.forEach { requestedItems.remove($0) }
            if requestedItems.isEmpty {
                requestedItemsDictionary.removeValue(forKey: interval)
            } else {
                requestedItemsDictionary[interval] = requestedItems
            }
        }
    }

    func fetchItems(ids: [String], interval: MarketsPriceIntervalType) async throws -> [MarketsDTO.ChartsHistory.PreviewResponse] {
        var idsToRequest: [[String]] = []

        var offset = 0
        logger.info("Attempt to fetch items for interval: \(interval.rawValue). Number of items: \(ids.count)")
        while offset < ids.count {
            if ids.count - offset <= Self.maxNumberOfItemsPerRequest {
                logger.info("Number of items is less than or equal to max items per request. Executing one request")
                idsToRequest.append(Array(ids[offset...]))
                break
            } else {
                let lowerBound = offset
                offset += Self.maxNumberOfItemsPerRequest
                let range = lowerBound ..< offset
                idsToRequest.append(Array(ids[range]))
                logger.info("Number of items is more than max per request. Adding to request list range: \(range)")
            }
        }

        return try await withThrowingTaskGroup(of: MarketsDTO.ChartsHistory.PreviewResponse.self, returning: [MarketsDTO.ChartsHistory.PreviewResponse].self) { [weak self] group in
            guard let self else { return [] }

            for idsList in idsToRequest {
                group.addTask { try await self.loadItems(for: idsList, with: interval) }
            }

            var responses = [MarketsDTO.ChartsHistory.PreviewResponse]()
            for try await taskResult in group {
                responses.append(taskResult)
            }
            return responses
        }
    }

    func loadItems(
        for coinIds: [String],
        with interval: MarketsPriceIntervalType
    ) async throws -> MarketsDTO.ChartsHistory.PreviewResponse {
        let requestModel = MarketsDTO.ChartsHistory.PreviewRequest(
            currency: selectedCurrencyCode,
            coinIds: coinIds,
            interval: interval
        )

        logger.info("Loading market list tokens with request \(requestModel.parameters.debugDescription)")

        return try await tangemApiService.loadCoinsHistoryChartPreview(requestModel: requestModel)
    }
}
