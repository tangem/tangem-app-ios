//
//  EarnAddTokenFlowConfigurationFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemLocalization
import TangemFoundation

enum EarnAddTokenFlowConfigurationFactory {
    static func make(
        earnToken: EarnTokenModel,
        coordinator: EarnAddTokenRoutable,
        analyticsProvider: EarnAnalyticsProvider
    ) -> AccountsAwareAddTokenFlowConfiguration {
        let isTokenAdded: (TokenItem, any CryptoAccountModel) -> Bool = { tokenItem, account in
            account.userTokensManager.contains(tokenItem, derivationInsensitive: false)
        }
        return AccountsAwareAddTokenFlowConfiguration(
            getAvailableTokenItems: { accountSelectorCell in
                let networkModel = NetworkModel(
                    networkId: earnToken.networkId,
                    contractAddress: earnToken.contractAddress,
                    decimalCount: earnToken.decimalCount
                )
                let supportedBlockchains = accountSelectorCell.userWalletModel.config.supportedBlockchains
                let tokenItemMapper = TokenItemMapper(supportedBlockchains: supportedBlockchains)
                guard let tokenItem = tokenItemMapper.mapToTokenItem(
                    id: earnToken.id,
                    name: earnToken.name,
                    symbol: earnToken.symbol,
                    network: networkModel
                ) else {
                    return []
                }
                return [tokenItem]
            },
            isTokenAdded: isTokenAdded,
            accountSelectionBehavior: makeCustomExecuteActionBehavior(
                coordinator: coordinator,
                isTokenAdded: isTokenAdded
            ),
            postAddBehavior: .executeAction { [weak coordinator] tokenItem, accountSelectorCell in
                handleTokenAddedSuccessfully(
                    addedToken: tokenItem,
                    accountSelectorCell: accountSelectorCell,
                    coordinator: coordinator
                )
            },
            accountFilter: makeAccountFilter(earnToken: earnToken),
            accountAvailabilityProvider: nil,
            analyticsLogger: analyticsProvider
        )
    }
}

// MARK: - Private

private extension EarnAddTokenFlowConfigurationFactory {
    static func makeCustomExecuteActionBehavior(
        coordinator: EarnAddTokenRoutable,
        isTokenAdded: @escaping (TokenItem, any CryptoAccountModel) -> Bool
    ) -> AccountsAwareAddTokenFlowConfiguration.AccountSelectionBehavior {
        .customExecuteAction { [weak coordinator] tokenItem, accountSelectorCell, continueToNetworkSelection in
            if isTokenAdded(tokenItem, accountSelectorCell.cryptoAccountModel) {
                navigateToToken(
                    tokenItem: tokenItem,
                    accountSelectorCell: accountSelectorCell,
                    coordinator: coordinator
                )
            } else {
                continueToNetworkSelection()
            }
        }
    }

    static func navigateToToken(
        tokenItem: TokenItem,
        accountSelectorCell: AccountSelectorCellModel,
        coordinator: EarnAddTokenRoutable?
    ) {
        guard let coordinator else { return }

        let account = accountSelectorCell.cryptoAccountModel
        guard let walletModel = EarnWalletModelFinder.findWalletModel(
            for: tokenItem,
            in: account
        ) else {
            coordinator.presentErrorToast(with: Localization.commonSomethingWentWrong)
            Task { @MainActor in coordinator.close() }
            return
        }

        let userWalletModel = accountSelectorCell.userWalletModel
        Task { @MainActor in coordinator.close() }
        coordinator.presentTokenDetails(by: walletModel, with: userWalletModel)
    }

    static func handleTokenAddedSuccessfully(
        addedToken: TokenItem,
        accountSelectorCell: AccountSelectorCellModel,
        coordinator: EarnAddTokenRoutable?
    ) {
        FeedbackGenerator.success()
        navigateToToken(
            tokenItem: addedToken,
            accountSelectorCell: accountSelectorCell,
            coordinator: coordinator
        )
    }

    static func makeAccountFilter(
        earnToken: EarnTokenModel
    ) -> ((any CryptoAccountModel, Set<Blockchain>) -> Bool)? {
        let networkId = earnToken.networkId
        return { account, supportedBlockchains in
            AccountBlockchainManageabilityChecker.canManageNetwork(networkId, for: account, in: supportedBlockchains)
        }
    }
}
