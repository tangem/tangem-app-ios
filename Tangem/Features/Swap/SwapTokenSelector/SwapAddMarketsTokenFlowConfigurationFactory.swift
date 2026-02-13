//
//  SwapAddMarketsTokenFlowConfigurationFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemAccounts

enum SwapAddMarketsTokenFlowConfigurationFactory {
    static func make(
        coinId: String,
        coinName: String,
        coinSymbol: String,
        networks: [NetworkModel],
        additionRoutable: SwapMarketsTokenAdditionRoutable
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
            postAddBehavior: .executeAction { [weak additionRoutable] tokenItem, accountSelectorCell in
                guard let additionRoutable else { return }

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

                Task { @MainActor in
                    additionRoutable.didAddMarketToken(item: item)
                }
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
