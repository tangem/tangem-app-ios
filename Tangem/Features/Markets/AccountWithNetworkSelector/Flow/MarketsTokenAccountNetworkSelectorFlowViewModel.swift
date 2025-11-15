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
import TangemFoundation

protocol MarketsTokenAccountNetworkSelectorRoutable: AnyObject, MarketsPortfolioContainerRoutable {
    func close()
    func presentSuccessToast(with text: String)
    func presentErrorToast(with text: String)
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

    private var oneAndOnlyAccount: AccountSelectorCellModel? {
        let availableUserWalletModels = userWalletDataProvider.userWalletModels.filter { !$0.isUserWalletLocked }

        guard let userWalletModel = availableUserWalletModels.singleElement else {
            return nil
        }

        let cryptoAccountModel: (any CryptoAccountModel)?
        switch userWalletModel.accountModelsManager.accountModels.first {
        case .standard(let cryptoAccounts):
            switch cryptoAccounts {
            case .multiple(let cryptoAccountModels):
                cryptoAccountModel = cryptoAccountModels.singleElement

            case .single(let model):
                cryptoAccountModel = model
            }

        case nil:
            cryptoAccountModel = nil
        }

        guard let cryptoAccountModel else {
            return nil
        }

        // Create wallet item since we have exactly one wallet
        let walletItem = AccountSelectorWalletItem(
            userWallet: userWalletModel,
            cryptoAccountModel: cryptoAccountModel,
            isLocked: false
        )

        return .wallet(walletItem)
    }
}

// MARK: - Setup

private extension MarketsTokenAccountNetworkSelectorFlowViewModel {
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
        accountSelectorCell: AccountSelectorCellModel,
        context: NavigationContext
    ) {
        let networkSelectorViewModel = makeNetworkSelectorViewModel(
            userWalletModel: accountSelectorCell.cryptoAccountModel.userWalletModel,
            cryptoAccount: accountSelectorCell.cryptoAccountModel,
            accountSelectorCell: accountSelectorCell
        )

        // Skip network selection if there's only one network available
        if let singleTokenItem = networkSelectorViewModel.tokenItemViewModels.singleElement?.tokenItem {
            openAddToken(
                tokenItem: singleTokenItem,
                accountSelectorCell: accountSelectorCell
            )
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
        selectedItem: (any CryptoAccountModel)?,
        context: NavigationContext,
        onSelectAccount: @escaping (AccountSelectorCellModel) -> Void
    ) {
        // Only push to stack if navigating from addToken screen
        // Don't push if this is the initial entry (context == .root)
        if context == .fromAddToken {
            pushCurrentState()
        }

        let filter = makeCryptoAccountModelsFilter()

        viewState = .accountSelector(
            viewModel: AccountSelectorViewModel(
                selectedItem: selectedItem,
                userWalletModels: userWalletDataProvider.userWalletModels,
                cryptoAccountModelsFilter: filter,
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
            viewModel: MarketsAddTokenViewModel(
                tokenItem: tokenItem,
                account: accountSelectorCell.cryptoAccountModel,
                tokenItemIconInfoBuilder: TokenIconInfoBuilder(),
                accountWalletDataProvider: accountWalletDataProvider,
                networkDataProvider: networkDataProvider,
                onAddTokenTapped: { [weak self] result in
                    switch result {
                    case .success(let tokenItemAndAccount):
                        self?.coordinator?.presentSuccessToast(with: Localization.marketsTokenAdded)
                        self?.openGetToken(tokenItem: tokenItemAndAccount.tokenItem, account: tokenItemAndAccount.cryptoAccount)
                        FeedbackGenerator.success()

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
        account: any CryptoAccountModel
    ) {
        // From getToken screen, user cannot go back to addToken
        // Clear the navigation stack
        navigationStack.removeAll()

        viewState = .getToken(
            viewModel: MarketsGetTokenViewModel(
                tokenItem: tokenItem,
                tokenItemIconInfoBuilder: TokenIconInfoBuilder(),
                onBuy: { [weak self] in
                    self?.handleGetTokenAction(action: .buy, tokenItem: tokenItem, account: account)
                },
                onExchange: { [weak self] in
                    self?.handleGetTokenAction(action: .exchange, tokenItem: tokenItem, account: account)
                },
                onReceive: { [weak self] in
                    self?.handleGetTokenAction(action: .receive, tokenItem: tokenItem, account: account)
                },
                onLater: { [weak self] in
                    self?.coordinator?.close()
                }
            )
        )
    }

    private func handleGetTokenAction(
        action: TokenActionType,
        tokenItem: TokenItem,
        account: any CryptoAccountModel
    ) {
        let accountTokenItem = account.userTokensManager.userTokens.first { accountToken in
            accountToken == tokenItem
        }

        guard
            let actualTokenItem = accountTokenItem,
            let walletModel = findWalletModel(for: actualTokenItem, in: account)
        else {
            coordinator?.close()
            return
        }

        let analyticsParams: [Analytics.ParameterKey: String] = [
            .source: Analytics.ParameterValue.market.rawValue,
            .token: actualTokenItem.currencySymbol.uppercased(),
            .blockchain: actualTokenItem.blockchain.displayName,
        ]

        coordinator?.close()

        let userWalletModel = account.userWalletModel
        switch action {
        case .buy:
            Analytics.log(event: .marketsChartButtonBuy, params: analyticsParams)
            let sendInput = SendInput(userWalletInfo: userWalletModel.userWalletInfo, walletModel: walletModel)
            coordinator?.openOnramp(input: sendInput)

        case .exchange:
            Analytics.log(event: .marketsChartButtonSwap, params: analyticsParams)
            let expressInput = ExpressDependenciesInput(
                userWalletInfo: userWalletModel.userWalletInfo,
                source: walletModel.asExpressInteractorWallet,
                destination: .loadingAndSet
            )

            coordinator?.openExchange(input: expressInput)

        case .receive:
            Analytics.log(event: .marketsChartButtonReceive, params: analyticsParams)
            coordinator?.openReceive(walletModel: walletModel)

        default:
            break
        }
    }

    private func findWalletModel(for tokenItem: TokenItem, in account: any CryptoAccountModel) -> (any WalletModel)? {
        let walletModelId = WalletModelId(tokenItem: tokenItem)
        return account.walletModelsManager.walletModels.first(where: { $0.id == walletModelId })
    }
}

// MARK: - Factory Methods

private extension MarketsTokenAccountNetworkSelectorFlowViewModel {
    func makeNetworkSelectorViewModel(
        userWalletModel: UserWalletModel,
        cryptoAccount: any CryptoAccountModel,
        accountSelectorCell: AccountSelectorCellModel
    ) -> MarketsNetworkSelectorViewModel {
        MarketsNetworkSelectorViewModel(
            data: inputData,
            selectedUserWalletModel: userWalletModel,
            selectedAccount: cryptoAccount,
            onSelectNetwork: { [weak self] tokenItem in
                self?.openAddToken(
                    tokenItem: tokenItem,
                    accountSelectorCell: accountSelectorCell
                )
            }
        )
    }

    func makeAccountWalletDataProvider(
        accountSelectorCell: AccountSelectorCellModel,
        tokenItem: TokenItem
    ) -> MarketsAddTokenAccountWalletSelectorDataProvider {
        let isSelectionAvailable = oneAndOnlyAccount == nil

        let displayTitle: String = switch accountSelectorCell {
        case .account: Localization.accountDetailsTitle
        case .wallet: Localization.wcCommonWallet
        }

        return AccountSelectorDataProvider(
            isSelectionAvailable: isSelectionAvailable,
            displayTitle: displayTitle,
            accountSelectorCell: accountSelectorCell,
            handleSelection: { [weak self] in
                self?.handleAccountWalletSelection(
                    cryptoAccount: accountSelectorCell.cryptoAccountModel,
                    tokenItem: tokenItem
                )
            }
        )
    }

    func makeNetworkDataProvider(
        accountSelectorCell: AccountSelectorCellModel,
        tokenItem: TokenItem
    ) -> MarketsAddTokenNetworkSelectorDataProvider {
        let cryptoAccount = accountSelectorCell.cryptoAccountModel
        let isSelectionAvailable = isNetworkSelectionAvailable(for: cryptoAccount)

        return NetworkSelectorDataProvider(
            tokenItem: tokenItem,
            isSelectionAvailable: isSelectionAvailable,
            handleSelection: { [weak self] in
                self?.handleNetworkSelection(accountSelectorCell: accountSelectorCell)
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
            selectedItem: cryptoAccount,
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

private extension MarketsTokenAccountNetworkSelectorFlowViewModel {
    func isNetworkSelectionAvailable(for cryptoAccount: any CryptoAccountModel) -> Bool {
        return countAvailableNetworks(userWalletModel: cryptoAccount.userWalletModel, cryptoAccount: cryptoAccount) > 1
    }

    func countAvailableNetworks(userWalletModel: UserWalletModel, cryptoAccount: any CryptoAccountModel) -> Int {
        let tokenItems = MarketsTokenItemsProvider.calculateTokenItems(
            coinId: inputData.coinId,
            coinName: inputData.coinName,
            coinSymbol: inputData.coinSymbol,
            networks: inputData.networks,
            userWalletModel: userWalletModel,
            cryptoAccount: cryptoAccount
        )

        return tokenItems.count
    }

    func makeCryptoAccountModelsFilter() -> (any CryptoAccountModel) -> Bool {
        let networks = inputData.networks

        return { cryptoAccount in
            let allSupportedBlockchains = cryptoAccount.userWalletModel.config.supportedBlockchains

            let areAccountsUnavailableForAllNetworks = networks.allSatisfy { network in
                !AccountDerivationPathHelper.supportsAccounts(networkId: network.networkId, in: allSupportedBlockchains)
            }

            return cryptoAccount.isMainAccount || !areAccountsUnavailableForAllNetworks
        }
    }
}

// MARK: - Data Providers

private struct AccountSelectorDataProvider: MarketsAddTokenAccountWalletSelectorDataProvider {
    let account: any CryptoAccountModel
    let isSelectionAvailable: Bool
    let displayTitle: String
    let handleSelection: () -> Void
    let trailingContent: MarketsAddTokenViewModel.AccountWalletTrailingContent

    init(
        isSelectionAvailable: Bool,
        displayTitle: String,
        accountSelectorCell: AccountSelectorCellModel,
        handleSelection: @escaping () -> Void
    ) {
        self.isSelectionAvailable = isSelectionAvailable
        self.displayTitle = displayTitle
        self.handleSelection = handleSelection

        switch accountSelectorCell {
        case .account(let accountItem):
            account = accountItem.domainModel
            trailingContent = .account(
                AccountIconViewBuilder.makeAccountIconViewData(accountModel: account),
                name: account.name
            )

        case .wallet(let walletItem):
            account = walletItem.mainAccount
            trailingContent = .walletName(walletItem.name)
        }
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
