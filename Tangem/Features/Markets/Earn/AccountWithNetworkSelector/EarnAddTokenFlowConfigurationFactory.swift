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
    ) -> AddTokenFlowConfiguration {
        let isTokenAdded: (TokenItem, any CryptoAccountModel) -> Bool = { tokenItem, account in
            account.userTokensManager.contains(tokenItem, derivationInsensitive: false)
        }
        return AddTokenFlowConfiguration(
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
    ) -> AddTokenFlowConfiguration.AccountSelectionBehavior {
        .customExecuteAction { [weak coordinator] tokenItem, accountSelectorCell, continueToNetworkSelection in
            if isTokenAdded(tokenItem, accountSelectorCell.cryptoAccountModel) {
                navigateToToken(
                    tokenItem: tokenItem,
                    accountSelectorCell: accountSelectorCell,
                    coordinator: coordinator,
                    present: { coordinator, walletModel, userWalletModel in
                        coordinator.presentTokenDetails(by: walletModel, with: userWalletModel)
                    }
                )
            } else {
                continueToNetworkSelection()
            }
        }
    }

    static func navigateToToken(
        tokenItem: TokenItem,
        accountSelectorCell: AccountSelectorCellModel,
        coordinator: EarnAddTokenRoutable?,
        present: @escaping @MainActor (EarnAddTokenRoutable, any WalletModel, UserWalletModel) -> Void
    ) {
        guard let coordinator else { return }

        let account = accountSelectorCell.cryptoAccountModel
        guard let walletModel = EarnWalletModelFinder.findWalletModel(
            for: tokenItem,
            in: account
        ) else {
            Task { @MainActor in
                coordinator.presentErrorToast(with: Localization.commonSomethingWentWrong)
                coordinator.close()
            }
            return
        }

        let userWalletModel = accountSelectorCell.userWalletModel

        Task { @MainActor in
            coordinator.close()
            // Wait for the floating sheet dismissal animation to finish before presenting the next screen.
            // `try?` swallows the CancellationError; the guard then skips presentation when the task was
            // cancelled, so we never present on top of an already-dismissed flow.
            try? await Task.sleep(for: .seconds(0.2))
            guard !Task.isCancelled else { return }
            present(coordinator, walletModel, userWalletModel)
        }
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
            coordinator: coordinator,
            present: { coordinator, walletModel, userWalletModel in
                coordinator.presentAfterAdd(by: walletModel, with: userWalletModel)
            }
        )
    }

    static func makeAccountFilter(
        earnToken: EarnTokenModel
    ) -> ((AddTokenFlowConfiguration.AccountContext) -> Bool) {
        let networkId = earnToken.networkId
        return { context in
            AccountBlockchainManageabilityChecker.canManageNetwork(networkId, for: context.account, in: context.supportedBlockchains)
        }
    }
}
