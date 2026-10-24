//
//  MarketsTokenItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum MarketsTokenItemsProvider {
    static func calculateTokenItems(
        coinId: String,
        coinName: String,
        coinSymbol: String,
        networks: [NetworkModel],
        supportedBlockchains: Set<Blockchain>,
        cryptoAccount: any CryptoAccountModel
    ) -> [TokenItem] {
        let filteredBlockchains = supportedBlockchains.filter {
            AccountBlockchainManageabilityChecker.canManageBlockchain($0, for: cryptoAccount)
        }

        let tokenItemMapper = TokenItemMapper(supportedBlockchains: filteredBlockchains)

        let tokenItems = networks
            .compactMap {
                tokenItemMapper.mapToTokenItem(id: coinId, name: coinName, symbol: coinSymbol, network: $0)
            }
            .sorted { lhs, rhs in
                // Main networks must be up list networks
                lhs.isBlockchain && lhs.isBlockchain != rhs.isBlockchain
            }

        return tokenItems
    }
}
