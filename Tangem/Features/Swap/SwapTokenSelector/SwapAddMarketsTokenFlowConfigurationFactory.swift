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
        source: SwapSelectTokenAnalyticsLogger.SwapTokenSource,
        userHasSearchedDuringThisSession: Bool,
        additionRoutable: SwapMarketsTokenAdditionRoutable
    ) -> AccountsAwareAddTokenFlowConfiguration {
        let analyticsLogger = SwapSelectTokenAnalyticsLogger(
            source: source,
            userHasSearchedDuringThisSession: userHasSearchedDuringThisSession
        )

        analyticsLogger.logTokenSelected(coinSymbol: coinSymbol)

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
            postAddBehavior: .executeAction { [weak additionRoutable] tokenItem, accountSelectorCell in
                guard let additionRoutable else { return }

                Task {
                    await handleTokenAdded(
                        tokenItem: tokenItem,
                        accountSelectorCell: accountSelectorCell,
                        additionRoutable: additionRoutable
                    )
                }
            },
            accountFilter: makeAccountFilter(
                coinId: coinId,
                coinName: coinName,
                coinSymbol: coinSymbol,
                networks: networks
            ),
            accountAvailabilityProvider: TokenAdditionChecker.makeAccountAvailabilityProvider(
                coinId: coinId,
                coinName: coinName,
                coinSymbol: coinSymbol,
                availableNetworks: networks
            ),
            analyticsLogger: analyticsLogger
        )
    }

    @MainActor
    private static func handleTokenAdded(
        tokenItem: TokenItem,
        accountSelectorCell: AccountSelectorCellModel,
        additionRoutable: SwapMarketsTokenAdditionRoutable,
        retryCount: Int = 0
    ) async {
        let walletModel = accountSelectorCell.cryptoAccountModel.walletModelsManager.walletModels.first {
            $0.tokenItem == tokenItem
        }

        if let walletModel {
            let item = AccountsAwareTokenSelectorItem(
                userWalletInfo: accountSelectorCell.userWalletModel.userWalletInfo,
                account: accountSelectorCell.cryptoAccountModel,
                walletModel: walletModel
            )
            await additionRoutable.didAddMarketToken(item: item)
            return
        }

        guard retryCount < Constants.maxWalletModelRetries else {
            AppLogger.debug("Failed to find wallet model for \(tokenItem) after \(retryCount) retries")
            return
        }

        try? await Task.sleep(for: Constants.walletModelRetryDelay)

        await handleTokenAdded(
            tokenItem: tokenItem,
            accountSelectorCell: accountSelectorCell,
            additionRoutable: additionRoutable,
            retryCount: retryCount + 1
        )
    }

    private static func makeAccountFilter(
        coinId: String,
        coinName: String,
        coinSymbol: String,
        networks: [NetworkModel]
    ) -> ((AccountsAwareAddTokenFlowConfiguration.AccountContext) -> Bool) {
        { context in
            let networkIds = networks.map(\.networkId)
            let cryptoAccount = context.account
            let supportedBlockchains = context.supportedBlockchains

            func hasManageableNetworks() -> Bool {
                return networkIds.contains { networkId in
                    AccountBlockchainManageabilityChecker.canManageNetwork(
                        networkId,
                        for: cryptoAccount,
                        in: supportedBlockchains
                    )
                }
            }

            func hasNotEmptyTokenItems() -> Bool {
                let tokenItems = MarketsTokenItemsProvider.calculateTokenItems(
                    coinId: coinId,
                    coinName: coinName,
                    coinSymbol: coinSymbol,
                    networks: networks,
                    supportedBlockchains: supportedBlockchains,
                    cryptoAccount: cryptoAccount
                )

                return tokenItems.isNotEmpty
            }

            return hasManageableNetworks() && hasNotEmptyTokenItems()
        }
    }
}

// MARK: - Constants

private extension SwapAddMarketsTokenFlowConfigurationFactory {
    enum Constants {
        static let walletModelRetryDelay: Duration = .milliseconds(100)
        static let maxWalletModelRetries = 20
    }
}
