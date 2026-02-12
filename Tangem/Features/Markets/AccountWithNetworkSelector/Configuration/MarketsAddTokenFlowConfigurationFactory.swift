//
//  MarketsAddTokenFlowConfigurationFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemLocalization

enum MarketsAddTokenFlowConfigurationFactory {
    static func make(
        inputData: MarketsTokensNetworkSelectorViewModel.InputData,
        coordinator: MarketsPortfolioContainerRoutable & AccountsAwareAddTokenFlowRoutable
    ) -> AccountsAwareAddTokenFlowConfiguration {
        let analyticsLogger = MarketsAddTokenFlowAnalyticsLogger(coinSymbol: inputData.coinSymbol)

        return AccountsAwareAddTokenFlowConfiguration(
            getAvailableTokenItems: { accountSelectorCell in
                tokenItems(
                    inputData: inputData,
                    supportedBlockchains: accountSelectorCell.userWalletModel.config.supportedBlockchains,
                    cryptoAccount: accountSelectorCell.cryptoAccountModel
                )
            },
            isTokenAdded: { tokenItem, account in
                account.userTokensManager.contains(tokenItem, derivationInsensitive: false)
            },
            postAddBehavior: .showGetToken(
                makeGetTokenConfiguration(
                    analyticsLogger: analyticsLogger,
                    coordinator: coordinator
                )
            ),
            accountFilter: makeAccountFilter(inputData: inputData),
            accountAvailabilityProvider: makeAccountAvailabilityProvider(inputData: inputData),
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - Private

private extension MarketsAddTokenFlowConfigurationFactory {
    static func makeGetTokenConfiguration(
        analyticsLogger: GetTokenAnalyticsLogger,
        coordinator: MarketsPortfolioContainerRoutable & AccountsAwareAddTokenFlowRoutable
    ) -> AccountsAwareAddTokenFlowConfiguration.GetTokenConfiguration {
        AccountsAwareAddTokenFlowConfiguration.GetTokenConfiguration(
            onBuy: { [weak coordinator] tokenItem, accountSelectorCell in
                handleGetTokenAction(
                    action: .buy,
                    tokenItem: tokenItem,
                    accountSelectorCell: accountSelectorCell,
                    analyticsLogger: analyticsLogger,
                    coordinator: coordinator
                )
            },
            onExchange: { [weak coordinator] tokenItem, accountSelectorCell in
                handleGetTokenAction(
                    action: .exchange,
                    tokenItem: tokenItem,
                    accountSelectorCell: accountSelectorCell,
                    analyticsLogger: analyticsLogger,
                    coordinator: coordinator
                )
            },
            onReceive: { [weak coordinator] tokenItem, accountSelectorCell in
                handleGetTokenAction(
                    action: .receive,
                    tokenItem: tokenItem,
                    accountSelectorCell: accountSelectorCell,
                    analyticsLogger: analyticsLogger,
                    coordinator: coordinator
                )
            },
            onLater: { [weak coordinator] in
                analyticsLogger.logLaterTapped()
                Task { @MainActor in coordinator?.close() }
            }
        )
    }

    static func handleGetTokenAction(
        action: TokenActionType,
        tokenItem: TokenItem,
        accountSelectorCell: AccountSelectorCellModel,
        analyticsLogger: GetTokenAnalyticsLogger,
        coordinator: (MarketsPortfolioContainerRoutable & AccountsAwareAddTokenFlowRoutable)?
    ) {
        guard let coordinator else { return }

        let account = accountSelectorCell.cryptoAccountModel

        let accountTokenItem = account.userTokensManager.userTokens.first { accountToken in
            accountToken == tokenItem
        }

        guard let actualTokenItem = accountTokenItem,
              let walletModel = findWalletModel(for: actualTokenItem, in: account) else {
            Task { @MainActor in coordinator.close() }
            return
        }

        let navigationTokenAction = { @MainActor in
            let userWalletInfo = accountSelectorCell.userWalletModel.userWalletInfo
            switch action {
            case .buy:
                analyticsLogger.logBuyTapped()
                let sendInput = SendInput(userWalletInfo: userWalletInfo, walletModel: walletModel)
                let parameters = PredefinedOnrampParametersBuilder.makeMoonpayPromotionParametersIfActive()
                coordinator.openOnramp(input: sendInput, parameters: parameters)

            case .exchange:
                analyticsLogger.logExchangeTapped()
                let expressInput = ExpressDependenciesInput(
                    userWalletInfo: userWalletInfo,
                    source: ExpressInteractorWalletModelWrapper(
                        userWalletInfo: userWalletInfo,
                        walletModel: walletModel,
                        expressOperationType: .swap
                    ),
                    destination: .loadingAndSet
                )

                coordinator.openExchange(input: expressInput)

            case .receive:
                analyticsLogger.logReceiveTapped()
                coordinator.openReceive(walletModel: walletModel)

            default:
                break
            }
        }

        Task { @MainActor in
            coordinator.close()
            // We have to wait a little bit to while floating sheet is closed
            try await Task.sleep(for: .seconds(0.2))

            navigationTokenAction()
        }
    }

    static func findWalletModel(
        for tokenItem: TokenItem,
        in account: any CryptoAccountModel
    ) -> (any WalletModel)? {
        let walletModelId = WalletModelId(tokenItem: tokenItem)
        return account.walletModelsManager.walletModels.first(where: { $0.id == walletModelId })
    }

    static func makeAccountFilter(
        inputData: MarketsTokensNetworkSelectorViewModel.InputData
    ) -> ((AccountsAwareAddTokenFlowConfiguration.AccountContext) -> Bool)? {
        { context in
            let networkIds = inputData.networks.map(\.networkId)
            let cryptoAccount = context.account
            let supportedBlockchains = context.supportedBlockchains

            let hasManageableNetworks = networkIds.contains { networkId in
                AccountBlockchainManageabilityChecker.canManageNetwork(networkId, for: cryptoAccount, in: supportedBlockchains)
            }

            if hasManageableNetworks {
                return true
            }

            let tokenItems = tokenItems(
                inputData: inputData,
                supportedBlockchains: supportedBlockchains,
                cryptoAccount: cryptoAccount
            )

            return tokenItems.isNotEmpty
        }
    }

    static func makeAccountAvailabilityProvider(
        inputData: MarketsTokensNetworkSelectorViewModel.InputData
    ) -> (AccountsAwareAddTokenFlowConfiguration.AccountContext) -> AccountAvailability {
        { context in
            let isAddedOnAll = TokenAdditionChecker.isTokenAddedOnNetworks(
                account: context.account,
                coinId: inputData.coinId,
                availableNetworks: inputData.networks,
                supportedBlockchains: context.supportedBlockchains
            )

            return isAddedOnAll
                ? .unavailable(reason: Localization.marketsTokenAdded)
                : .available
        }
    }

    static func tokenItems(
        inputData: MarketsTokensNetworkSelectorViewModel.InputData,
        supportedBlockchains: Set<Blockchain>,
        cryptoAccount: any CryptoAccountModel
    ) -> [TokenItem] {
        MarketsTokenItemsProvider.calculateTokenItems(
            coinId: inputData.coinId,
            coinName: inputData.coinName,
            coinSymbol: inputData.coinSymbol,
            networks: inputData.networks,
            supportedBlockchains: supportedBlockchains,
            cryptoAccount: cryptoAccount
        )
    }
}
