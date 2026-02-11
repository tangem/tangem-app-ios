//
//  EarnAddTokenFlowConfigurationFactory.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemLocalization
import TangemFoundation

enum EarnAddTokenFlowConfigurationFactory {
    static func make(
        earnToken: EarnTokenModel,
        coordinator: EarnAddTokenRoutable
    ) -> AccountsAwareAddTokenFlowConfiguration {
        AccountsAwareAddTokenFlowConfiguration(
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
            isTokenAdded: { tokenItem, account in
                account.userTokensManager.contains(tokenItem, derivationInsensitive: false)
            },
            accountSelectionBehavior: makeCompleteIfTokenIsAddedBehavior(coordinator: coordinator),
            postAddBehavior: .executeAction { [weak coordinator] tokenItem, accountSelectorCell in
                handleTokenAddedSuccessfully(
                    addedToken: tokenItem,
                    accountSelectorCell: accountSelectorCell,
                    coordinator: coordinator
                )
            },
            accountFilter: makeAccountFilter(earnToken: earnToken),
            accountAvailabilityProvider: nil,
            analyticsLogger: NoOpAddTokenFlowAnalyticsLogger()
        )
    }
}

// MARK: - Private

private extension EarnAddTokenFlowConfigurationFactory {
    static func makeCompleteIfTokenIsAddedBehavior(
        coordinator: EarnAddTokenRoutable
    ) -> AccountsAwareAddTokenFlowConfiguration.AccountSelectionBehavior {
        .completeIfTokenIsAdded(executeAction: { [weak coordinator] tokenItem, accountSelectorCell in
            navigateToToken(
                tokenItem: tokenItem,
                accountSelectorCell: accountSelectorCell,
                coordinator: coordinator
            )
        })
    }

    static func navigateToToken(
        tokenItem: TokenItem,
        accountSelectorCell: AccountSelectorCellModel,
        coordinator: EarnAddTokenRoutable?
    ) {
        guard let coordinator else { return }

        let walletModel = accountSelectorCell.cryptoAccountModel.walletModelsManager.walletModels.first {
            $0.tokenItem == tokenItem
        }

        guard let walletModel else {
            coordinator.presentErrorToast(with: Localization.commonSomethingWentWrong)
            coordinator.close()
            return
        }

        let userWalletModel = accountSelectorCell.userWalletModel
        coordinator.close()
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
