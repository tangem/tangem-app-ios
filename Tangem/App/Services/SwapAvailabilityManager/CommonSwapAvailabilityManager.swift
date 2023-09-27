//
//  CommonSwapAvailabilityManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemSwapping

class CommonSwapAvailabilityManager: SwapAvailabilityManager {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    var isSwapFeatureAvailable: Bool { FeatureProvider.isAvailable(.exchange) }

    private let supportedBlockchains: Set<Blockchain> = {
        let supported: Set<SwappingBlockchain> = [
            .ethereum,
            .bsc,
            .polygon,
            .optimism,
            .arbitrum,
            .gnosis,
            .avalanche,
            .fantom,
        ]

        let mainnetBlockchains = Blockchain.allMainnetCases
        return supported.compactMap { swappingBlockchain in
            return mainnetBlockchains.first(where: { $0.networkId == swappingBlockchain.networkId })
        }.toSet()
    }()

    private var loadedSwapableTokenItems: Set<TokenItem> = []

    init() {
        loadedSwapableTokenItems = supportedBlockchains.map { .blockchain($0) }.toSet()
    }

    func loadSwapAvailability(for items: [TokenItem]) -> AnyPublisher<Void, Error> {
        guard isSwapFeatureAvailable else {
            return .justWithError(output: ())
        }

        if items.isEmpty {
            return .justWithError(output: ())
        }

        let filteredItemsToRequest = items.filter {
            // We don't need to load exchangeable state for tokens in blockchains that not supported
            // So we filter them
            guard supportedBlockchains.contains($0.blockchain) else {
                return false
            }

            switch $0 {
            case .blockchain:
                // Blockchains will be already added to loaded swappable token list on initialization of the Checker
                return false
            case .token:
                // We need to load exchangeable state for tokens
                return true
            }
        }

        // This mean that all requesting items is blockchains or currently they blockchains not available for swap
        // We can exit without request
        if filteredItemsToRequest.isEmpty {
            return .justWithError(output: ())
        }

        let requestItem = convertToRequestItem(filteredItemsToRequest)
        return tangemApiService
            .loadCoins(requestModel: .init(supportedBlockchains: requestItem.blockchains, ids: requestItem.currencyIds))
            .map { [weak self] models in
                guard let self else {
                    return
                }

                let loadedTokenItems = models.flatMap { $0.items }

                // Filter only available to swap items
                let onlyAvailableToSwapItems = loadedTokenItems.filter {
                    switch $0 {
                    case .token(let token, _):
                        // If exchangeable == nil then swap is available for old users
                        return token.exchangeable ?? true
                    case .blockchain(let blockchain):
                        return self.supportedBlockchains.contains(blockchain)
                    }
                }

                loadedSwapableTokenItems.formUnion(onlyAvailableToSwapItems)
            }
            .eraseError()
    }

    func canSwap(tokenItem: TokenItem) -> Bool {
        guard isSwapFeatureAvailable else { return false }

        return loadedSwapableTokenItems.contains(tokenItem)
    }

    func addTokensIfCanBeSwapped(_ items: [TokenItem]) {
        let filteredItems = items.filter { item in
            guard let token = item.token else {
                return false
            }

            return token.exchangeable ?? true
        }

        loadedSwapableTokenItems.formUnion(filteredItems)
    }

    private func convertToRequestItem(_ items: [TokenItem]) -> RequestItem {
        var blockchains = Set<Blockchain>()
        var currencyIds = [String]()

        items.forEach { item in
            blockchains.insert(item.blockchain)
            guard let currencyId = item.currencyId else {
                return
            }

            currencyIds.append(currencyId)
        }
        return .init(blockchains: blockchains, currencyIds: currencyIds)
    }
}

private extension CommonSwapAvailabilityManager {
    struct RequestItem: Hashable {
        let blockchains: Set<Blockchain>
        let currencyIds: [String]
    }
}
