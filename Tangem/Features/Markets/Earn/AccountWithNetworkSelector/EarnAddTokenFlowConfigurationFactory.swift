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
            postAddBehavior: .executeAction { [weak coordinator] tokenItem, accountSelectorCell in
                handleTokenAddedSuccessfully(
                    addedToken: tokenItem,
                    accountSelectorCell: accountSelectorCell,
                    coordinator: coordinator
                )
            },
            accountFilter: makeAccountFilter(earnToken: earnToken),
            accountAvailabilityProvider: makeAccountAvailabilityProvider(earnToken: earnToken),
            analyticsLogger: NoOpAddTokenFlowAnalyticsLogger()
        )
    }
}

// MARK: - Private

private extension EarnAddTokenFlowConfigurationFactory {
    static func handleTokenAddedSuccessfully(
        addedToken: TokenItem,
        accountSelectorCell: AccountSelectorCellModel,
        coordinator: EarnAddTokenRoutable?
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

        let userWalletModel = accountSelectorCell.userWalletModel
        coordinator.close()
        coordinator.presentTokenDetails(by: walletModel, with: userWalletModel)
    }

    static func makeAccountFilter(
        earnToken: EarnTokenModel
    ) -> ((AccountsAwareAddTokenFlowConfiguration.AccountFiltrationContext) -> Bool)? {
        let networkId = earnToken.networkId
        return { context in
            AccountBlockchainManageabilityChecker.canManageNetwork(networkId, for: context.account, in: context.supportedBlockchains)
        }
    }

    static func makeAccountAvailabilityProvider(
        earnToken: EarnTokenModel
    ) -> ((AccountsAwareAddTokenFlowConfiguration.AccountFiltrationContext) -> AccountAvailability)? {
        let networkModel = NetworkModel(
            networkId: earnToken.networkId,
            contractAddress: earnToken.contractAddress,
            decimalCount: earnToken.decimalCount
        )

        return { context in
            let tokenItemMapper = TokenItemMapper(supportedBlockchains: context.supportedBlockchains)
            guard let tokenItem = tokenItemMapper.mapToTokenItem(
                id: earnToken.id,
                name: earnToken.name,
                symbol: earnToken.symbol,
                network: networkModel
            ) else {
                return .unavailable(reason: nil)
            }

            let alreadyAdded = context.account.userTokensManager.contains(tokenItem, derivationInsensitive: false)
            return alreadyAdded
                ? .unavailable(reason: Localization.marketsTokenAdded)
                : .available
        }
    }
}
