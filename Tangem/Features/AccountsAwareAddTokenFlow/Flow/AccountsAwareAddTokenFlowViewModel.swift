//
//  AccountsAwareAddTokenFlowViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemAssets
import TangemLocalization
import TangemAccounts
import TangemFoundation
import BlockchainSdk

@MainActor
final class AccountsAwareAddTokenFlowViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published var viewState: ViewState

    private let userWalletModels: [UserWalletModel]
    /// - Note: `OrderedDictionary` from `OrderedCollections` has quite inconvenient API for this use case
    /// (especially its `values` accessor), so we use a regular dictionary here.
    private let userWalletModelsKeyedById: [UserWalletId: UserWalletModel]
    private let configuration: AccountsAwareAddTokenFlowConfiguration
    private weak var coordinator: AccountsAwareAddTokenFlowRoutable?

    /// Navigation stack to track history
    private var navigationStack: [ViewState] = []

    init(
        userWalletModels: [UserWalletModel],
        configuration: AccountsAwareAddTokenFlowConfiguration,
        coordinator: AccountsAwareAddTokenFlowRoutable?
    ) {
        self.userWalletModels = userWalletModels
        userWalletModelsKeyedById = userWalletModels.toDictionary(keyedBy: \.userWalletId)
        self.configuration = configuration
        self.coordinator = coordinator

        // Initialize with placeholder, will be updated in setupInitialState
        viewState = .accountSelector(
            viewModel: AccountSelectorViewModel(
                selectedItem: nil,
                userWalletModels: [],
                onSelect: { _ in }
            ),
            context: .root
        )

        setupInitialState()
    }

    private var oneAndOnlyAccount: AccountSelectorCellModel? {
        OneAndOnlyAccountFinder.find(in: userWalletModels)
    }
}

// MARK: - Setup

private extension AccountsAwareAddTokenFlowViewModel {
    func setupInitialState() {
        if let oneAndOnlyAccount {
            openNetworkSelectionOrAddToken(
                accountSelectorCell: oneAndOnlyAccount,
                context: .root
            )
        } else {
            openAccountSelector(
                selectedItem: nil,
                context: .root,
                onSelectAccount: { [weak self] result in
                    self?.openNetworkSelectionOrAddToken(
                        accountSelectorCell: result,
                        context: .fromChooseAccount
                    )
                }
            )
        }
    }
}

// MARK: - Routing

extension AccountsAwareAddTokenFlowViewModel {
    func close() {
        coordinator?.close()
    }

    func back() {
        guard navigationStack.isNotEmpty else {
            coordinator?.close()
            return
        }

        viewState = navigationStack.removeLast()
    }
}

// MARK: - Navigation

private extension AccountsAwareAddTokenFlowViewModel {
    func pushCurrentState() {
        navigationStack.append(viewState)
    }

    func openNetworkSelectionOrAddToken(
        accountSelectorCell: AccountSelectorCellModel,
        context: NavigationContext
    ) {
        let availableTokenItems = configuration.getAvailableTokenItems(accountSelectorCell)

        // Skip network selection if there's only one network available
        if let singleTokenItem = availableTokenItems.singleElement {
            openAddToken(
                tokenItem: singleTokenItem,
                accountSelectorCell: accountSelectorCell
            )
            return
        }

        openNetworkSelection(
            tokenItems: availableTokenItems,
            accountSelectorCell: accountSelectorCell,
            context: context
        )
    }

    func openNetworkSelection(
        tokenItems: [TokenItem],
        accountSelectorCell: AccountSelectorCellModel,
        context: NavigationContext
    ) {
        pushCurrentState()

        let viewModel = AccountsAwareNetworkSelectorViewModel(
            tokenItems: tokenItems,
            isTokenAdded: { [configuration] tokenItem in
                configuration.isTokenAdded(tokenItem, accountSelectorCell.cryptoAccountModel)
            },
            onSelectNetwork: { [weak self] tokenItem in
                self?.openAddToken(
                    tokenItem: tokenItem,
                    accountSelectorCell: accountSelectorCell
                )
            }
        )

        viewState = .networkSelector(viewModel: viewModel, context: context)
    }

    func openAccountSelector(
        selectedItem: (any CryptoAccountModel)?,
        context: NavigationContext,
        onSelectAccount: @escaping (AccountSelectorCellModel) -> Void
    ) {
        // Only push to stack if navigating from addToken screen
        // Don't push if this is the initial entry (context == .root)
        if context == .fromAddToken {
            pushCurrentState()
        }

        configuration.analyticsLogger.logAccountSelectorOpened()

        viewState = .accountSelector(
            viewModel: AccountSelectorViewModel(
                selectedItem: selectedItem,
                userWalletModels: userWalletModels,
                cryptoAccountModelsFilter: makeCryptoAccountModelsFilter(),
                availabilityProvider: makeAccountAvailabilityProvider(),
                onSelect: onSelectAccount
            ),
            context: context
        )
    }

    func openAddToken(
        tokenItem: TokenItem,
        accountSelectorCell: AccountSelectorCellModel
    ) {
        // From addToken screen, user cannot go back to previous screens
        // Clear the navigation stack
        navigationStack.removeAll()

        let accountWalletDataProvider = makeAccountWalletDataProvider(
            accountSelectorCell: accountSelectorCell,
            tokenItem: tokenItem
        )

        let networkDataProvider = makeNetworkDataProvider(
            accountSelectorCell: accountSelectorCell,
            tokenItem: tokenItem
        )

        viewState = .addToken(
            viewModel: AccountsAwareAddTokenViewModel(
                tokenItem: tokenItem,
                account: accountSelectorCell.cryptoAccountModel,
                tokenItemIconInfoBuilder: TokenIconInfoBuilder(),
                accountWalletDataProvider: accountWalletDataProvider,
                networkDataProvider: networkDataProvider,
                analyticsLogger: configuration.analyticsLogger,
                onAddTokenTapped: { [weak self] result in
                    switch result {
                    case .success(let addedToken):
                        self?.handleTokenAddedSuccessfully(
                            addedToken: addedToken,
                            accountSelectorCell: accountSelectorCell
                        )

                    case .failure(let error):
                        self?.coordinator?.presentErrorToast(with: error.localizedDescription)
                        FeedbackGenerator.error()
                    }
                }
            )
        )
    }

    func openGetToken(
        tokenItem: TokenItem,
        accountSelectorCell: AccountSelectorCellModel,
        config: AccountsAwareAddTokenFlowConfiguration.GetTokenConfiguration
    ) {
        // From getToken screen, user cannot go back to addToken
        // Clear the navigation stack
        navigationStack.removeAll()

        viewState = .getToken(
            viewModel: AccountsAwareGetTokenViewModel(
                tokenItem: tokenItem,
                tokenItemIconInfoBuilder: TokenIconInfoBuilder(),
                onBuy: { config.onBuy(tokenItem, accountSelectorCell) },
                onExchange: { config.onExchange(tokenItem, accountSelectorCell) },
                onReceive: { config.onReceive(tokenItem, accountSelectorCell) },
                onLater: config.onLater
            )
        )
    }

    private func handleTokenAddedSuccessfully(
        addedToken: TokenItem,
        accountSelectorCell: AccountSelectorCellModel
    ) {
        coordinator?.presentSuccessToast(with: Localization.marketsTokenAdded)
        FeedbackGenerator.success()

        switch configuration.postAddBehavior {
        case .showGetToken(let getTokenConfig):
            openGetToken(
                tokenItem: addedToken,
                accountSelectorCell: accountSelectorCell,
                config: getTokenConfig
            )

        case .executeAction(let action):
            action(addedToken, accountSelectorCell)
        }
    }
}

// MARK: - Factory Methods

private extension AccountsAwareAddTokenFlowViewModel {
    func makeAccountWalletDataProvider(
        accountSelectorCell: AccountSelectorCellModel,
        tokenItem: TokenItem
    ) -> AccountsAwareAddTokenAccountWalletSelectorDataProvider {
        AccountsAwareAddTokenAccountDataProvider(
            isSelectionAvailable: oneAndOnlyAccount == nil,
            accountSelectorCell: accountSelectorCell,
            handleSelection: { [weak self] in
                self?.handleAccountWalletSelection(
                    accountSelectorCell: accountSelectorCell,
                    tokenItem: tokenItem
                )
            }
        )
    }

    func makeNetworkDataProvider(
        accountSelectorCell: AccountSelectorCellModel,
        tokenItem: TokenItem
    ) -> AccountsAwareAddTokenNetworkSelectorDataProvider {
        let availableTokenItems = configuration.getAvailableTokenItems(accountSelectorCell)
        let isSelectionAvailable = availableTokenItems.count > 1

        return AccountsAwareAddTokenNetworkDataProvider(
            tokenItem: tokenItem,
            isSelectionAvailable: isSelectionAvailable,
            handleSelection: { [weak self] in
                self?.handleNetworkSelection(accountSelectorCell: accountSelectorCell)
            }
        )
    }
}

// MARK: - Handlers

private extension AccountsAwareAddTokenFlowViewModel {
    func handleAccountWalletSelection(
        accountSelectorCell: AccountSelectorCellModel,
        tokenItem: TokenItem
    ) {
        openAccountSelector(
            selectedItem: accountSelectorCell.cryptoAccountModel,
            context: .fromAddToken,
            onSelectAccount: { [weak self] result in
                self?.openAddToken(
                    tokenItem: tokenItem,
                    accountSelectorCell: result
                )
            }
        )
    }

    func handleNetworkSelection(accountSelectorCell: AccountSelectorCellModel) {
        openNetworkSelectionOrAddToken(
            accountSelectorCell: accountSelectorCell,
            context: .fromAddToken
        )
    }
}

// MARK: - Helpers

private extension AccountsAwareAddTokenFlowViewModel {
    func userWalletConfig(for accountSelectorItem: AccountSelectorViewModel.AccountSelectorItem) -> UserWalletConfig? {
        userWalletModelsKeyedById[accountSelectorItem.userWalletId]?.config
    }

    func makeCryptoAccountModelsFilter() -> (AccountSelectorViewModel.AccountSelectorItem) -> Bool {
        guard let customFilter = configuration.accountFilter else {
            return { [weak self] accountSelectorItem in
                let config = self?.userWalletConfig(for: accountSelectorItem)
                let hasMultiCurrencySupport = config?.hasFeature(.multiCurrency) ?? false

                // By definition, it is impossible to add tokens to accounts/wallets without multi-currency support
                return hasMultiCurrencySupport
            }
        }

        return { [weak self] accountSelectorItem in
            let config = self?.userWalletConfig(for: accountSelectorItem)
            let hasMultiCurrencySupport = config?.hasFeature(.multiCurrency) ?? false

            if !hasMultiCurrencySupport {
                // By definition, it is impossible to add tokens to accounts/wallets without multi-currency support
                return false
            }

            let supportedBlockchains = config?.supportedBlockchains ?? []
            let context = AccountsAwareAddTokenFlowConfiguration.AccountContext(
                account: accountSelectorItem.cryptoAccountModel,
                supportedBlockchains: supportedBlockchains
            )

            return customFilter(context)
        }
    }

    func makeAccountAvailabilityProvider() -> (AccountSelectorViewModel.AccountSelectorItem) -> AccountAvailability {
        guard let customProvider = configuration.accountAvailabilityProvider else {
            // Default: all accounts available
            return { _ in .available }
        }

        return { [weak self] accountSelectorItem in
            let config = self?.userWalletConfig(for: accountSelectorItem)
            let supportedBlockchains = config?.supportedBlockchains ?? []
            let context = AccountsAwareAddTokenFlowConfiguration.AccountContext(
                account: accountSelectorItem.cryptoAccountModel,
                supportedBlockchains: supportedBlockchains
            )

            return customProvider(context)
        }
    }
}
