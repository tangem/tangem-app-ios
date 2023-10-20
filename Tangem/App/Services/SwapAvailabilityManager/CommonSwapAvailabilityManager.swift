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

    var tokenItemsAvailableToSwapPublisher: AnyPublisher<[TokenItem: Bool], Never> {
        loadedSwapableTokenItems.eraseToAnyPublisher()
    }

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

    private var loadedSwapableTokenItems: CurrentValueSubject<[TokenItem: Bool], Never> = .init([:])

    init() {
        loadedSwapableTokenItems = .init(supportedBlockchains.reduce(into: [TokenItem: Bool]()) { $0[.blockchain($1)] = true })
    }

    func loadSwapAvailability(for items: [TokenItem], forceReload: Bool) {
        if items.isEmpty {
            return
        }

        let filteredItemsToRequest = items.filter {
            // We don't need to load exchangeable state for tokens in blockchains that not supported
            // So we filter them
            guard supportedBlockchains.contains($0.blockchain) else {
                return false
            }

            // If `forceReload` flag is true we need to force reload state for all items
            return loadedSwapableTokenItems.value[$0] == nil || forceReload
        }

        // This mean that all requesting items in blockchains that currently not available for swap
        // We can exit without request
        if filteredItemsToRequest.isEmpty {
            return
        }

        let requestItem = convertToRequestItem(filteredItemsToRequest)
        var loadSubscription: AnyCancellable?
        loadSubscription = tangemApiService
            .loadCoins(requestModel: .init(supportedBlockchains: requestItem.blockchains, ids: requestItem.currencyIds))
            .sink(receiveCompletion: { _ in
                withExtendedLifetime(loadSubscription) {}
            }, receiveValue: { [weak self] models in
                guard let self else {
                    return
                }

                let loadedTokenItems = models.flatMap { $0.items }

                let preparedSwapStates = Dictionary(uniqueKeysWithValues: loadedTokenItems.map {
                    switch $0 {
                    case .token(let token, _):
                        return ($0, token.exchangeable ?? false)
                    case .blockchain(let blockchain):
                        return ($0, self.supportedBlockchains.contains(blockchain))
                    }
                })

                loadedSwapableTokenItems.value.merge(preparedSwapStates, uniquingKeysWith: { $1 })
            })
    }

    func canSwap(tokenItem: TokenItem) -> Bool {
        loadedSwapableTokenItems.value[tokenItem] ?? false
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
