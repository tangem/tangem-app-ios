//
//  CommonSwapAvailabilityManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemExpress

class CommonSwapAvailabilityManager: SwapAvailabilityManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    var tokenItemsAvailableToSwapPublisher: AnyPublisher<[TokenItem: Bool], Never> {
        loadedSwapableTokenItems.eraseToAnyPublisher()
    }

    private var loadedSwapableTokenItems: CurrentValueSubject<[TokenItem: Bool], Never> = .init([:])

    func canSwap(tokenItem: TokenItem) -> Bool {
        loadedSwapableTokenItems.value[tokenItem] ?? false
    }

    func loadSwapAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {
        if items.isEmpty {
            return
        }

        let filteredItemsToRequest = items.filter {
            // If `forceReload` flag is true we need to force reload state for all items
            return loadedSwapableTokenItems.value[$0] == nil || forceReload
        }

        // This mean that all requesting items in blockchains that currently not available for swap
        // We can exit without request
        if filteredItemsToRequest.isEmpty {
            return
        }

        loadExpressAssets(for: filteredItemsToRequest, userWalletId: userWalletId)
    }

    private func loadExpressAssets(for items: [TokenItem], userWalletId: String) {
        runTask(in: self, code: { manager in
            var requestedItems = [ExpressCurrency: TokenItem]()
            let expressCurrencies = items.map {
                let currency = $0.expressCurrency
                requestedItems[currency] = $0
                return currency
            }
            let provider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)
            let assets = try await provider.assets(with: expressCurrencies)
            let preparedSwapStates: [TokenItem: Bool] = assets.reduce(into: [:]) { partialResult, asset in
                guard let tokenItem = requestedItems[asset.currency] else {
                    return
                }

                partialResult[tokenItem] = asset.isExchangeable
            }

            manager.saveTokenItemsAvailability(for: preparedSwapStates)
        })
    }

    private func saveTokenItemsAvailability(for tokenStates: [TokenItem: Bool]) {
        var items = loadedSwapableTokenItems.value
        tokenStates.forEach { key, value in
            items.updateValue(value, forKey: key)
        }
        loadedSwapableTokenItems.value = items
    }

    private func convertToRequestItem(_ items: [TokenItem]) -> RequestItem {
        var blockchains = Set<Blockchain>()
        var ids = [String]()

        items.forEach { item in
            blockchains.insert(item.blockchain)
            guard let id = item.id else {
                return
            }

            ids.append(id)
        }
        return .init(blockchains: blockchains, ids: ids)
    }
}

private extension CommonSwapAvailabilityManager {
    struct RequestItem: Hashable {
        let blockchains: Set<Blockchain>
        let ids: [String]
    }
}
