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

    var tokenItemsAvailableToSwapPublisher: AnyPublisher<[TokenItem: TokenItemSwapState], Never> {
        tokenItemsSwapState.eraseToAnyPublisher()
    }

    private var tokenItemsSwapState: CurrentValueSubject<[TokenItem: TokenItemSwapState], Never> = .init([:])

    func swapState(for tokenItem: TokenItem) -> TokenItemSwapState {
        tokenItemsSwapState.value[tokenItem] ?? .notLoaded
    }

    func canSwap(tokenItem: TokenItem) -> Bool {
        swapState(for: tokenItem) == .available
    }

    func loadSwapAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {
        if items.isEmpty {
            return
        }

        var notSupportedTokens = [TokenItem]()
        let filteredItemsToRequest = items.filter {
            if $0.isCustom {
                notSupportedTokens.append($0)
                return false
            }

            // If `forceReload` flag is true we need to force reload state for all items
            return tokenItemsSwapState.value[$0] == nil || forceReload
        }

        saveTokenItemsStates(for: buildStates(for: notSupportedTokens, state: .unavailable))

        // This mean that all requesting items in blockchains that currently not available for swap
        // We can exit without request
        if filteredItemsToRequest.isEmpty {
            return
        }

        saveTokenItemsStates(for: buildStates(for: filteredItemsToRequest, state: .loading))
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

            do {
                let provider = ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)
                let assets = try await provider.assets(with: expressCurrencies)
                var loadedSwapStates: [TokenItem: TokenItemSwapState] = assets.reduce(into: [:]) { partialResult, asset in
                    guard let tokenItem = requestedItems[asset.currency] else {
                        return
                    }

                    partialResult[tokenItem] = asset.isExchangeable ? .available : .unavailable
                }

                if loadedSwapStates.count != items.count {
                    items.forEach {
                        guard loadedSwapStates[$0] == nil else {
                            return
                        }

                        loadedSwapStates[$0] = .unavailable
                    }
                }

                manager.saveTokenItemsStates(for: loadedSwapStates)
            } catch {
                let failedToLoadTokensState = manager.buildStates(for: items, state: .failedToLoadInfo(error))
                manager.saveTokenItemsStates(for: failedToLoadTokensState)
            }
        })
    }

    private func buildStates(for items: [TokenItem], state: TokenItemSwapState) -> [TokenItem: TokenItemSwapState] {
        var dictionary = [TokenItem: TokenItemSwapState]()
        items.forEach {
            dictionary[$0] = state
        }
        return dictionary
    }

    private func saveTokenItemsStates(for states: [TokenItem: TokenItemSwapState]) {
        var items = tokenItemsSwapState.value
        states.forEach { key, value in
            items.updateValue(value, forKey: key)
        }
        tokenItemsSwapState.value = items
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
