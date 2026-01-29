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
        coordinator: SwapTokenSelectorRoutable
    ) -> AccountsAwareAddTokenFlowConfiguration {
        AccountsAwareAddTokenFlowConfiguration(
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
            postAddBehavior: .executeAction { [weak coordinator] tokenItem, accountSelectorCell in
                guard let coordinator else { return }

                let walletModel = accountSelectorCell.cryptoAccountModel.walletModelsManager.walletModels.first {
                    $0.tokenItem == tokenItem
                }

                guard let walletModel else {
                    return
                }

                let item = AccountsAwareTokenSelectorItem(
                    userWalletInfo: accountSelectorCell.userWalletModel.userWalletInfo,
                    account: accountSelectorCell.cryptoAccountModel,
                    walletModel: walletModel
                )
                coordinator.onTokenAdded(item: item)
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
            analyticsLogger: NoOpAddTokenFlowAnalyticsLogger()
        )
    }
}
