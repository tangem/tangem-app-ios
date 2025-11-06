//
//  MarketsTokenItemsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

enum MarketsTokenItemsProvider {
    static func calculateTokenItems(
        coinId: String,
        coinName: String,
        coinSymbol: String,
        networks: [NetworkModel],
        userWalletModel: UserWalletModel?,
        cryptoAccount: any CryptoAccountModel
    ) -> [TokenItem] {
        guard let userWalletModel else {
            return []
        }

        let supportedBlockchains = if !cryptoAccount.isMainAccount {
            userWalletModel.config.supportedBlockchains
                .filter { AccountDerivationPathHelper(blockchain: $0).areAccountsAvailableForBlockchain() }
        } else {
            userWalletModel.config.supportedBlockchains
        }

        let tokenItemMapper = TokenItemMapper(supportedBlockchains: supportedBlockchains)

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
