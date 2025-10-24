//
//  MarketsTokenAccountNetworkSelectorViewModel.swift
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

protocol MarketsTokenAccountNetworkSelectorRoutable: AnyObject {
    func close()
}

@MainActor
final class MarketsTokenAccountNetworkSelectorFlowViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published var viewState: ViewState

    private let inputData: MarketsTokensNetworkSelectorViewModel.InputData
    private let userWalletDataProvider: MarketsWalletDataProvider
    private weak var coordinator: MarketsTokenAccountNetworkSelectorRoutable?

    /// Navigation stack to track history
    private var navigationStack: [ViewState] = []

    init(
        inputData: MarketsTokensNetworkSelectorViewModel.InputData,
        userWalletDataProvider: MarketsWalletDataProvider,
        coordinator: MarketsTokenAccountNetworkSelectorRoutable?
    ) {
        self.inputData = inputData
        self.userWalletDataProvider = userWalletDataProvider
        self.coordinator = coordinator

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

    private var oneAndOnlyAccount: (any CryptoAccountModel)? {
        let availableUserWalletModels = userWalletDataProvider.userWalletModels.filter { !$0.isUserWalletLocked }

        guard let userWalletModel = availableUserWalletModels.onlyElement else {
            return nil
        }

        switch userWalletModel.accountModelsManager.accountModels.first {
        case .standard(let cryptoAccounts):
            switch cryptoAccounts {
            case .multiple(let cryptoAccountModels):
                return cryptoAccountModels.onlyElement

            case .single(let cryptoAccountModel):
                return cryptoAccountModel
            }

        case nil:
            return nil
        }
    }
}

// MARK: - Setup

private extension MarketsTokenAccountNetworkSelectorFlowViewModel {
    func setupInitialState() {
        if let oneAndOnlyAccount {
            openNetworkSelectionOrAddToken(
                cryptoAccount: oneAndOnlyAccount,
                context: .root
            )
        } else {
            openAccountSelector(
                selectedItem: nil,
                context: .root,
                onSelectAccount: { [weak self] baseAccountModel in
                    guard let cryptoAccount = baseAccountModel as? (any CryptoAccountModel) else {
                        return
                    }

                    self?.openNetworkSelectionOrAddToken(
                        cryptoAccount: cryptoAccount,
                        context: .fromChooseAccount
                    )
                }
            )
        }
    }
}

// MARK: - Routing

extension MarketsTokenAccountNetworkSelectorFlowViewModel {
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

private extension MarketsTokenAccountNetworkSelectorFlowViewModel {
    func pushCurrentState() {
        navigationStack.append(viewState)
    }

    func openNetworkSelectionOrAddToken(
        cryptoAccount: any CryptoAccountModel,
        context: NavigationContext
    ) {
        guard let userWalletModel = findUserWalletModel(for: cryptoAccount) else {
            return
        }

        let networkSelectorViewModel = makeNetworkSelectorViewModel(
            userWalletModel: userWalletModel,
            cryptoAccount: cryptoAccount
        )

        // Skip network selection if there's only one network available
        if let singleTokenItem = networkSelectorViewModel.tokenItemViewModels.onlyElement?.tokenItem {
            openAddToken(tokenItem: singleTokenItem, cryptoAccount: cryptoAccount)
            return
        }

        openNetworkSelection(
            viewModel: networkSelectorViewModel,
            context: context
        )
    }

    func openNetworkSelection(
        viewModel: MarketsNetworkSelectorViewModel,
        context: NavigationContext
    ) {
        pushCurrentState()
        viewState = .networksSelection(viewModel: viewModel, context: context)
    }

    func openAccountSelector(
        selectedItem: AccountSelectorCellModel?,
        context: NavigationContext,
        onSelectAccount: @escaping (any BaseAccountModel) -> Void
    ) {
        // Only push to stack if navigating from addToken screen
        // Don't push if this is the initial entry (context == .root)
        if context == .fromAddToken {
            pushCurrentState()
        }

        viewState = .accountSelector(
            viewModel: AccountSelectorViewModel(
                selectedItem: selectedItem,
                userWalletModels: userWalletDataProvider.userWalletModels,
                onSelect: onSelectAccount
            ),
            context: context
        )
    }

    func openAddToken(
        tokenItem: TokenItem,
        cryptoAccount: any CryptoAccountModel
    ) {
        // From addToken screen, user cannot go back to previous screens
        // Clear the navigation stack
        navigationStack.removeAll()

        let accountWalletDataProvider = makeAccountWalletDataProvider(
            cryptoAccount: cryptoAccount,
            tokenItem: tokenItem
        )

        let networkDataProvider = makeNetworkDataProvider(
            cryptoAccount: cryptoAccount,
            tokenItem: tokenItem
        )

        viewState = .addToken(
            viewModel: MarketsAddTokenViewModel(
                tokenItem: tokenItem,
                tokenItemIconInfoBuilder: TokenIconInfoBuilder(),
                accountWalletDataProvider: accountWalletDataProvider,
                networkDataProvider: networkDataProvider
            )
        )
    }

    // [REDACTED_TODO_COMMENT]
    /*
     func openGetToken() {
         pushCurrentState()
         viewState = .getToken(viewModel: GetTokenViewModel(...))
     }
     */
}

// MARK: - Factory Methods

private extension MarketsTokenAccountNetworkSelectorFlowViewModel {
    func makeNetworkSelectorViewModel(
        userWalletModel: UserWalletModel,
        cryptoAccount: any CryptoAccountModel
    ) -> MarketsNetworkSelectorViewModel {
        MarketsNetworkSelectorViewModel(
            data: inputData,
            selectedUserWalletModel: userWalletModel,
            selectedAccount: cryptoAccount,
            onSelectNetwork: { [weak self] tokenItem in
                self?.openAddToken(
                    tokenItem: tokenItem,
                    cryptoAccount: cryptoAccount
                )
            }
        )
    }

    func makeAccountWalletDataProvider(
        cryptoAccount: any CryptoAccountModel,
        tokenItem: TokenItem
    ) -> MarketsAddTokenAccountWalletSelectorDataProvider {
        let isSelectionAvailable = oneAndOnlyAccount == nil

        return AccountSelectorDataProvider(
            account: cryptoAccount,
            isSelectionAvailable: isSelectionAvailable,
            displayTitle: Localization.accountDetailsTitle,
            handleSelection: { [weak self] in
                self?.handleAccountWalletSelection(
                    cryptoAccount: cryptoAccount,
                    tokenItem: tokenItem
                )
            }
        )
    }

    func makeNetworkDataProvider(
        cryptoAccount: any CryptoAccountModel,
        tokenItem: TokenItem
    ) -> MarketsAddTokenNetworkSelectorDataProvider {
        let isSelectionAvailable = isNetworkSelectionAvailable(for: cryptoAccount)

        return NetworkSelectorDataProvider(
            tokenItem: tokenItem,
            isSelectionAvailable: isSelectionAvailable,
            handleSelection: { [weak self] in
                self?.handleNetworkSelection(cryptoAccount: cryptoAccount)
            }
        )
    }
}

// MARK: - Handlers

private extension MarketsTokenAccountNetworkSelectorFlowViewModel {
    func handleAccountWalletSelection(
        cryptoAccount: any CryptoAccountModel,
        tokenItem: TokenItem
    ) {
        openAccountSelector(
            selectedItem: .account(AccountSelectorAccountItem(account: cryptoAccount)),
            context: .fromAddToken,
            onSelectAccount: { [weak self] baseAccountModel in
                guard let newCryptoAccount = baseAccountModel as? (any CryptoAccountModel) else {
                    return
                }

                self?.openAddToken(tokenItem: tokenItem, cryptoAccount: newCryptoAccount)
            }
        )
    }

    func handleNetworkSelection(cryptoAccount: any CryptoAccountModel) {
        openNetworkSelectionOrAddToken(
            cryptoAccount: cryptoAccount,
            context: .fromAddToken
        )
    }
}

// MARK: - Helpers

private extension MarketsTokenAccountNetworkSelectorFlowViewModel {
    func findUserWalletModel(for cryptoAccount: any CryptoAccountModel) -> UserWalletModel? {
        MarketsUserWalletFinder.findUserWalletModel(
            for: cryptoAccount,
            in: userWalletDataProvider.userWalletModels
        )
    }

    func isNetworkSelectionAvailable(for cryptoAccount: any CryptoAccountModel) -> Bool {
        guard let userWalletModel = findUserWalletModel(for: cryptoAccount) else {
            return false
        }

        let networkSelectorViewModel = makeNetworkSelectorViewModel(
            userWalletModel: userWalletModel,
            cryptoAccount: cryptoAccount
        )

        return networkSelectorViewModel.tokenItemViewModels.count > 1
    }
}

// MARK: - Data Providers

private struct AccountSelectorDataProvider: MarketsAddTokenAccountWalletSelectorDataProvider {
    let account: any CryptoAccountModel
    let isSelectionAvailable: Bool
    let displayTitle: String
    let handleSelection: () -> Void

    var trailingContent: MarketsAddTokenViewModel.AccountWalletTrailingContent {
        .account(
            AccountIconViewBuilder.makeAccountIconViewData(accountModel: account),
            name: account.name
        )
    }
}

private struct NetworkSelectorDataProvider: MarketsAddTokenNetworkSelectorDataProvider {
    let tokenItem: TokenItem
    let isSelectionAvailable: Bool
    let handleSelection: () -> Void

    var displayTitle: String { Localization.wcCommonNetwork }

    var trailingContent: (imageAsset: ImageType, name: String) {
        let iconProvider = NetworkImageProvider()

        return (
            imageAsset: iconProvider.provide(by: tokenItem.blockchain, filled: true),
            name: tokenItem.blockchain.displayName
        )
    }
}
