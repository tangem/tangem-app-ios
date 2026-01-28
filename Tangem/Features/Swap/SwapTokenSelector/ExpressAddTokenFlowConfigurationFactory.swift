//
//  ExpressAddTokenFlowConfigurationFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemAccounts

enum ExpressAddTokenFlowConfigurationFactory {
    static func make(
        coinId: String,
        coinName: String,
        coinSymbol: String,
        networks: [NetworkModel],
        onTokenAdded: @escaping (TokenItem, UserWalletInfo, any CryptoAccountModel) -> Void
    ) -> AccountsAwareAddTokenFlowConfiguration {
        let analyticsLogger = ExpressAddTokenAnalyticsLogger(coinSymbol: coinSymbol)

        return AccountsAwareAddTokenFlowConfiguration(
            getAvailableTokenItems: { accountSelectorCell in
                MarketsTokenItemsProvider.calculateTokenItems(
                    coinId: coinId,
                    coinName: coinName,
                    coinSymbol: coinSymbol,
                    networks: networks,
                    supportedBlockchains: accountSelectorCell.userWalletModel.config.supportedBlockchains,
                    cryptoAccount: accountSelectorCell.cryptoAccountModel
                )
            },
            isTokenAdded: { tokenItem, account in
                account.userTokensManager.contains(tokenItem, derivationInsensitive: false)
            },
            postAddBehavior: .executeAction { tokenItem, accountSelectorCell in
                let userWalletInfo = accountSelectorCell.userWalletModel.userWalletInfo
                onTokenAdded(tokenItem, userWalletInfo, accountSelectorCell.cryptoAccountModel)
            },
            accountFilter: { account, supportedBlockchains in
                let networkIds = networks.map(\.networkId)
                return networkIds.contains { networkId in
                    AccountBlockchainManageabilityChecker.canManageNetwork(
                        networkId,
                        for: account,
                        in: supportedBlockchains
                    )
                }
            },
            analyticsLogger: analyticsLogger
        )
    }
}
