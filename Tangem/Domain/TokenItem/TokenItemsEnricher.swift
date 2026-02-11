//
//  TokenItemsEnricher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TokenItemsEnricher {
    /// Enriches token items with their blockchain networks.
    /// For each token, its blockchain network is inserted before it (if not already present).
    static func enrichedWithBlockchainNetworksIfNeeded(
        _ tokenItems: [TokenItem],
        filter existingTokenItemsFilter: [TokenItem] = []
    ) -> [TokenItem] {
        var filter = existingTokenItemsFilter.toBlockchainNetworks()
        let inputNetworks = tokenItems.toBlockchainNetworks()

        filter.formUnion(inputNetworks)

        var result: [TokenItem] = []

        for tokenItem in tokenItems {
            if tokenItem.isBlockchain {
                result.append(tokenItem)
                continue
            }

            let network = tokenItem.blockchainNetwork

            if !filter.contains(network) {
                filter.insert(network)
                result.append(.blockchain(network))
            }

            result.append(tokenItem)
        }

        return result
    }
}

// MARK: - Convenience extensions

private extension Array where Element == TokenItem {
    func toBlockchainNetworks() -> Set<BlockchainNetwork> {
        return reduce(into: []) { result, item in
            if item.isBlockchain {
                result.insert(item.blockchainNetwork)
            }
        }
    }
}
