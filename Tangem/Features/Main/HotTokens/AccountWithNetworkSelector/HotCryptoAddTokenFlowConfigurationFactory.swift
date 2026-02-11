//
//  HotCryptoAddTokenFlowConfigurationFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemLocalization
import TangemFoundation

enum HotCryptoAddTokenFlowConfigurationFactory {
    static func make(
        hotToken: HotCryptoToken,
        coordinator: HotCryptoAddTokenRoutable
    ) -> AccountsAwareAddTokenFlowConfiguration {
        AccountsAwareAddTokenFlowConfiguration(
            getAvailableTokenItems: { _ in
                // HotTokens always have single network
                // Additionaly, availability to add hot token is controlled by parent.
                // Those that are already added wont show up in the list thus
                // Will not get to this method at all
                guard let tokenItem = hotToken.tokenItem else {
                    return []
                }
                return [tokenItem]
            },
            isTokenAdded: { tokenItem, account in
                account.userTokensManager.contains(tokenItem, derivationInsensitive: false)
            },
            postAddBehavior: .executeAction { [weak coordinator] tokenItem, accountSelectorCell in
                handleTokenAddedSuccessfully(
                    addedToken: tokenItem,
                    accountSelectorCell: accountSelectorCell,
                    coordinator: coordinator
                )
            },
            accountFilter: makeAccountFilter(hotToken: hotToken),
            accountAvailabilityProvider: makeAccountAvailabilityProvider(hotToken: hotToken),
            // We do not track analytics for Hot Crypto in add token flow
            analyticsLogger: NoOpAddTokenFlowAnalyticsLogger()
        )
    }
}

// MARK: - Private

private extension HotCryptoAddTokenFlowConfigurationFactory {
    static func handleTokenAddedSuccessfully(
        addedToken: TokenItem,
        accountSelectorCell: AccountSelectorCellModel,
        coordinator: HotCryptoAddTokenRoutable?
    ) {
        guard let coordinator else { return }

        FeedbackGenerator.success()

        // Find the wallet model for the added token
        let walletModel = accountSelectorCell.cryptoAccountModel.walletModelsManager.walletModels.first {
            $0.tokenItem == addedToken
        }

        guard let walletModel else {
            coordinator.presentErrorToast(with: Localization.commonSomethingWentWrong)
            coordinator.close()
            return
        }

        let userWalletInfo = accountSelectorCell.userWalletModel.userWalletInfo
        let sendInput = SendInput(userWalletInfo: userWalletInfo, walletModel: walletModel)
        let parameters = PredefinedOnrampParametersBuilder.makeMoonpayPromotionParametersIfActive()

        coordinator.close()
        coordinator.openOnramp(input: sendInput, parameters: parameters)
    }

    static func makeAccountFilter(
        hotToken: HotCryptoToken
    ) -> ((any CryptoAccountModel, Set<Blockchain>) -> Bool)? {
        guard let tokenItem = hotToken.tokenItem else {
            return { _, _ in false }
        }

        let blockchain = tokenItem.blockchain
        return { account, _ in
            AccountBlockchainManageabilityChecker.canManageBlockchain(blockchain, for: account)
        }
    }

    static func makeAccountAvailabilityProvider(
        hotToken: HotCryptoToken
    ) -> ((AccountsAwareAddTokenFlowConfiguration.AccountFiltrationContext) -> AccountAvailability)? {
        guard let tokenItem = hotToken.tokenItem else {
            return { _ in .unavailable(reason: nil) }
        }

        return { context in
            let alreadyAdded = context.account.userTokensManager.contains(tokenItem, derivationInsensitive: false)
            return alreadyAdded
                ? .unavailable(reason: Localization.marketsTokenAdded)
                : .available
        }
    }
}
