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
                MarketsTokenItemsProvider.calculateTokenItems(
                    coinId: inputData.coinId,
                    coinName: inputData.coinName,
                    coinSymbol: inputData.coinSymbol,
                    networks: inputData.networks,
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
            accountFilter: { account, supportedBlockchains in
                let networkIds = inputData.networks.map(\.networkId)
                return networkIds.contains { networkId in
                    AccountBlockchainManageabilityChecker.canManageNetwork(networkId, for: account, in: supportedBlockchains)
                }
            },
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
                coordinator?.close()
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

        guard
            let actualTokenItem = accountTokenItem,
            let walletModel = findWalletModel(for: actualTokenItem, in: account)
        else {
            coordinator.close()
            return
        }

        coordinator.close()

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

    static func findWalletModel(
        for tokenItem: TokenItem,
        in account: any CryptoAccountModel
    ) -> (any WalletModel)? {
        let walletModelId = WalletModelId(tokenItem: tokenItem)
        return account.walletModelsManager.walletModels.first(where: { $0.id == walletModelId })
    }

    static func makeAccountAvailabilityProvider(
        inputData: MarketsTokensNetworkSelectorViewModel.InputData
    ) -> (AccountsAwareAddTokenFlowConfiguration.AccountAvailabilityContext) -> AccountAvailability {
        { context in
            let tokenItems = MarketsTokenItemsProvider.calculateTokenItems(
                coinId: inputData.coinId,
                coinName: inputData.coinName,
                coinSymbol: inputData.coinSymbol,
                networks: inputData.networks,
                supportedBlockchains: context.supportedBlockchains,
                cryptoAccount: context.account
            )

            guard tokenItems.isNotEmpty else {
                return .unavailable(reason: nil)
            }

            let allAdded = TokenAdditionChecker.areTokenItemsAdded(
                in: context.account,
                tokenItems: tokenItems,
                supportedBlockchains: context.supportedBlockchains
            )

            return allAdded
                ? .unavailable(reason: Localization.marketsTokenAdded)
                : .available
        }
    }
}
