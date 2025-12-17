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
import BlockchainSdk

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
            // Use union of all supported blockchains from all wallets
            let allSupportedBlockchains = Set(userWalletDataProvider.userWalletModels.flatMap { $0.config.supportedBlockchains })

            openAccountSelector(
                selectedItem: nil,
                supportedBlockchains: allSupportedBlockchains,
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
        supportedBlockchains: Set<Blockchain>,
        context: NavigationContext,
        onSelectAccount: @escaping (AccountSelectorCellModel) -> Void
    ) {
        // Only push to stack if navigating from addToken screen
        // Don't push if this is the initial entry (context == .root)
        if context == .fromAddToken {
            pushCurrentState()
        }

        let filter = makeCryptoAccountModelsFilter(with: supportedBlockchains)
        let availabilityProvider = makeAccountAvailabilityProvider(supportedBlockchains: supportedBlockchains)

        viewState = .accountSelector(
            viewModel: AccountSelectorViewModel(
                selectedItem: selectedItem,
                userWalletModels: userWalletDataProvider.userWalletModels,
                cryptoAccountModelsFilter: filter,
                availabilityProvider: availabilityProvider,
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
                    case .success(let tokenItem):
                        self?.coordinator?.presentSuccessToast(with: Localization.marketsTokenAdded)
                        self?.openGetToken(tokenItem: tokenItem, accountSelectorCell: accountSelectorCell)
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
        accountSelectorCell: AccountSelectorCellModel
    ) {
        // From getToken screen, user cannot go back to addToken
        // Clear the navigation stack
        navigationStack.removeAll()

        viewState = .getToken(
            viewModel: MarketsGetTokenViewModel(
                tokenItem: tokenItem,
                tokenItemIconInfoBuilder: TokenIconInfoBuilder(),
                onBuy: { [weak self] in
                    self?.handleGetTokenAction(
                        action: .buy,
                        tokenItem: tokenItem,
                        accountSelectorCell: accountSelectorCell
                    )
                },
                onExchange: { [weak self] in
                    self?.handleGetTokenAction(
                        action: .exchange,
                        tokenItem: tokenItem,
                        accountSelectorCell: accountSelectorCell
                    )
                },
                onReceive: { [weak self] in
                    self?.handleGetTokenAction(
                        action: .receive,
                        tokenItem: tokenItem,
                        accountSelectorCell: accountSelectorCell
                    )
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
        accountSelectorCell: AccountSelectorCellModel
    ) {
        let account = accountSelectorCell.cryptoAccountModel

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

        let userWalletInfo = accountSelectorCell.userWalletModel.userWalletInfo
        switch action {
        case .buy:
            Analytics.log(event: .marketsChartButtonBuy, params: analyticsParams)
            let sendInput = SendInput(userWalletInfo: userWalletInfo, walletModel: walletModel)
            let parameters = PredefinedOnrampParametersBuilder.makeMoonpayPromotionParametersIfActive()
            coordinator?.openOnramp(input: sendInput, parameters: parameters)

        case .exchange:
            Analytics.log(event: .marketsChartButtonSwap, params: analyticsParams)
            let expressInput = ExpressDependenciesInput(
                userWalletInfo: userWalletInfo,
                source: ExpressInteractorWalletModelWrapper(userWalletInfo: userWalletInfo, walletModel: walletModel),
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

    private func findWalletModel(
        for tokenItem: TokenItem,
        in account: any CryptoAccountModel
    ) -> (any WalletModel)? {
        let walletModelId = WalletModelId(tokenItem: tokenItem)
        return account.walletModelsManager.walletModels.first(where: { $0.id == walletModelId })
    }
}

// MARK: - Factory Methods

private extension MarketsTokenAccountNetworkSelectorFlowViewModel {
    func makeNetworkSelectorViewModel(
        accountSelectorCell: AccountSelectorCellModel
    ) -> MarketsNetworkSelectorViewModel {
        MarketsNetworkSelectorViewModel(
            data: inputData,
            selectedUserWalletConfig: accountSelectorCell.userWalletModel.config,
            selectedAccount: accountSelectorCell.cryptoAccountModel,
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
                    accountSelectorCell: accountSelectorCell,
                    tokenItem: tokenItem
                )
            }
        )
    }

    func makeNetworkDataProvider(
        accountSelectorCell: AccountSelectorCellModel,
        tokenItem: TokenItem
    ) -> MarketsAddTokenNetworkSelectorDataProvider {
        let isSelectionAvailable = isNetworkSelectionAvailable(for: accountSelectorCell)

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
        accountSelectorCell: AccountSelectorCellModel,
        tokenItem: TokenItem
    ) {
        openAccountSelector(
            selectedItem: accountSelectorCell.cryptoAccountModel,
            supportedBlockchains: accountSelectorCell.userWalletModel.config.supportedBlockchains,
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
    func isNetworkSelectionAvailable(for accountSelectorCell: AccountSelectorCellModel) -> Bool {
        return countAvailableNetworks(for: accountSelectorCell) > 1
    }

    func countAvailableNetworks(for accountSelectorCell: AccountSelectorCellModel) -> Int {
        let tokenItems = MarketsTokenItemsProvider.calculateTokenItems(
            coinId: inputData.coinId,
            coinName: inputData.coinName,
            coinSymbol: inputData.coinSymbol,
            networks: inputData.networks,
            supportedBlockchains: accountSelectorCell.userWalletModel.config.supportedBlockchains,
            cryptoAccount: accountSelectorCell.cryptoAccountModel
        )

        return tokenItems.count
    }

    func makeCryptoAccountModelsFilter(with supportedBlockchains: Set<Blockchain>) -> (any CryptoAccountModel) -> Bool {
        let networkIds = inputData.networks.map(\.networkId)
        return { account in
            networkIds.contains { networkId in
                AccountBlockchainManageabilityChecker.canManageNetwork(networkId, for: account, in: supportedBlockchains)
            }
        }
    }

    func makeAccountAvailabilityProvider(
        supportedBlockchains: Set<Blockchain>
    ) -> (any CryptoAccountModel) -> AccountAvailability {
        let inputData = inputData

        return { cryptoAccount in
            let isAddedOnAll = MarketsTokenNetworkChecker.isTokenAddedOnNetworks(
                account: cryptoAccount,
                coinId: inputData.coinId,
                availableNetworks: inputData.networks,
                supportedBlockchains: supportedBlockchains
            )

            return isAddedOnAll
                ? .unavailable(reason: Localization.marketsTokenAdded)
                : .available
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
                AccountModelUtils.UI.iconViewData(accountModel: account),
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
