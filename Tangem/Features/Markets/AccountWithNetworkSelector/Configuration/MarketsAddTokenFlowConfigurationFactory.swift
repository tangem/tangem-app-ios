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
    struct InputData {
        let coinId: String
        let coinName: String
        let coinSymbol: String
        let networks: [NetworkModel]
    }

    static func make(
        inputData: InputData,
        coordinator: MarketsPortfolioContainerRoutable & AddTokenFlowRoutable
    ) -> AddTokenFlowConfiguration {
        let analyticsLogger = MarketsAddTokenFlowAnalyticsLogger(coinSymbol: inputData.coinSymbol)

        return AddTokenFlowConfiguration(
            getAvailableTokenItems: { accountSelectorCell in
                makeTokenItems(
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
            accountAvailabilityProvider: TokenAdditionChecker.makeAccountAvailabilityProvider(
                coinId: inputData.coinId,
                coinName: inputData.coinName,
                coinSymbol: inputData.coinSymbol,
                availableNetworks: inputData.networks
            ),
            analyticsLogger: analyticsLogger
        )
    }
}

// MARK: - Private

private extension MarketsAddTokenFlowConfigurationFactory {
    static func makeGetTokenConfiguration(
        analyticsLogger: GetTokenAnalyticsLogger,
        coordinator: MarketsPortfolioContainerRoutable & AddTokenFlowRoutable
    ) -> AddTokenFlowConfiguration.GetTokenConfiguration {
        let expressAvailabilityProvider: ExpressAvailabilityProvider = InjectedValues[\.expressAvailabilityProvider]

        return AddTokenFlowConfiguration.GetTokenConfiguration(
            isBuyAvailable: { tokenItem, accountSelectorCell in
                let config = accountSelectorCell.userWalletModel.config
                guard config.isFeatureVisible(.exchange) else { return false }
                return expressAvailabilityProvider.canOnramp(tokenItem: tokenItem)
            },
            isExchangeAvailable: { tokenItem, accountSelectorCell in
                let config = accountSelectorCell.userWalletModel.config
                guard config.isFeatureVisible(.swapping) else { return false }
                return expressAvailabilityProvider.canSwap(tokenItem: tokenItem)
            },
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
        coordinator: (MarketsPortfolioContainerRoutable & AddTokenFlowRoutable)?
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
                coordinator.openOnramp(input: sendInput, parameters: .none)

            case .exchange:
                analyticsLogger.logExchangeTapped()
                let helper = SwapPredefinedParametersHelper()
                guard let parameters = helper.makeParameters(
                    origin: .markets(walletModel: walletModel),
                    userWalletInfo: userWalletInfo
                ) else {
                    break
                }

                coordinator.openSwap(input: parameters, destination: walletModel.tokenItem)

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
        inputData: InputData
    ) -> ((AddTokenFlowConfiguration.AccountContext) -> Bool) {
        { context in
            let networkIds = inputData.networks.map(\.networkId)
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
                let tokenItems = makeTokenItems(
                    inputData: inputData,
                    supportedBlockchains: supportedBlockchains,
                    cryptoAccount: cryptoAccount
                )

                return tokenItems.isNotEmpty
            }

            return hasManageableNetworks() && hasNotEmptyTokenItems()
        }
    }

    static func makeTokenItems(
        inputData: InputData,
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

    private static func candidateWalletAccounts(
        in userWalletModels: [any UserWalletModel]
    ) -> [AddTokenEligibleAccountsResolver.EligibleAccount] {
        if let oneAndOnly = OneAndOnlyAccountFinder.find(in: userWalletModels) {
            return [(oneAndOnly.userWalletModel, oneAndOnly.cryptoAccountModel)]
        }
        return AddTokenEligibleAccountsResolver.resolveAll(in: userWalletModels)
    }
}

// MARK: - Preselected token

extension MarketsAddTokenFlowConfigurationFactory {
    /// Prefers the first not-yet-added network in the wallet/account that
    /// `AddTokenFlowRedesignedViewModel` will pick as its initial — so the user lands on a
    /// network they can actually add, and the preselected token stays consistent with the
    /// chosen account. Falls back to the first available network when every supported one
    /// is already added. `isTokenAdded` should match the predicate used by the surrounding
    /// flow's configuration so preselect and confirm agree on what's addable.
    static func makePreselectedTokenItem(
        inputData: InputData,
        userWalletModels: [any UserWalletModel],
        isTokenAdded: (TokenItem, any CryptoAccountModel) -> Bool
    ) -> TokenItem? {
        guard let (userWallet, cryptoAccount) = candidateWalletAccounts(in: userWalletModels).first else {
            return nil
        }

        let tokenItems = makeTokenItems(
            inputData: inputData,
            supportedBlockchains: userWallet.config.supportedBlockchains,
            cryptoAccount: cryptoAccount
        )

        let firstNotAdded = tokenItems.first { !isTokenAdded($0, cryptoAccount) }
        return firstNotAdded ?? tokenItems.first
    }
}
