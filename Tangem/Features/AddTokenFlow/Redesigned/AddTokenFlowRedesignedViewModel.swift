//
//  AddTokenFlowRedesignedViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemLocalization
import TangemAccounts
import TangemFoundation

@MainActor
final class AddTokenFlowRedesignedViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Published

    @Published var viewState: ViewState

    // MARK: - Private

    private let tokenItem: TokenItem
    private let oneAndOnlyAccount: AccountSelectorCellModel?
    private let userWalletModels: [any UserWalletModel]
    private let userWalletModelsKeyedById: [UserWalletId: any UserWalletModel]
    private let configuration: AddTokenFlowConfiguration
    private weak var coordinator: AddTokenFlowRedesignedRoutable?

    private var navigationStack: [ViewState] = []

    // MARK: - Init

    /// Returns `nil` when no wallet is eligible to receive the token; the caller is
    /// expected to surface an error to the user in that case.
    init?(
        tokenItem: TokenItem,
        userWalletModels: [any UserWalletModel],
        configuration: AddTokenFlowConfiguration,
        coordinator: AddTokenFlowRedesignedRoutable?
    ) {
        let oneAndOnly = OneAndOnlyAccountFinder.find(in: userWalletModels)
        let firstEligible = AddTokenEligibleAccountsResolver.resolveAll(in: userWalletModels).first.map {
            AccountSelectorCellModel.wallet(
                AccountSelectorWalletItem(userWallet: $0.userWallet, cryptoAccountModel: $0.cryptoAccount, isLocked: false)
            )
        }
        guard let resolvedInitialAccount = oneAndOnly ?? firstEligible else {
            return nil
        }

        self.tokenItem = tokenItem
        oneAndOnlyAccount = oneAndOnly
        self.userWalletModels = userWalletModels
        userWalletModelsKeyedById = userWalletModels.toDictionary(keyedBy: \.userWalletId)
        self.configuration = configuration
        self.coordinator = coordinator

        viewState = Self.makeConfirmViewState(
            tokenItem: tokenItem,
            accountSelectorCell: resolvedInitialAccount,
            userWalletModels: userWalletModels,
            configuration: configuration,
            isAccountSelectionAvailable: oneAndOnly == nil,
            onAccountTapped: {},
            onNetworkTapped: {},
            onConfirmTapped: { _ in }
        )

        openConfirm(tokenItem: tokenItem, accountSelectorCell: resolvedInitialAccount)
    }

    convenience init?(
        tokenItem: TokenItem,
        userWalletModels: [any UserWalletModel],
        getAvailableTokenItems: @escaping (AccountSelectorCellModel) -> [TokenItem],
        postAddBehavior: AddTokenFlowConfiguration.PostAddBehavior,
        coordinator: AddTokenFlowRedesignedRoutable?
    ) {
        let configuration = AddTokenFlowConfiguration(
            getAvailableTokenItems: getAvailableTokenItems,
            postAddBehavior: postAddBehavior
        )
        self.init(
            tokenItem: tokenItem,
            userWalletModels: userWalletModels,
            configuration: configuration,
            coordinator: coordinator
        )
    }
}

// MARK: - Routing

extension AddTokenFlowRedesignedViewModel {
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

private extension AddTokenFlowRedesignedViewModel {
    func pushCurrentState() {
        navigationStack.append(viewState)
    }

    func openConfirm(
        tokenItem: TokenItem,
        accountSelectorCell: AccountSelectorCellModel
    ) {
        navigationStack.removeAll()
        configuration.analyticsLogger.logAddTokenScreenOpened()

        let availableTokenItems = configuration.getAvailableTokenItems(accountSelectorCell)

        viewState = Self.makeConfirmViewState(
            tokenItem: tokenItem,
            accountSelectorCell: accountSelectorCell,
            userWalletModels: userWalletModels,
            configuration: configuration,
            isAccountSelectionAvailable: oneAndOnlyAccount == nil,
            onAccountTapped: { [weak self] in
                self?.openAccountPicker(currentAccountSelectorCell: accountSelectorCell, tokenItem: tokenItem)
            },
            onNetworkTapped: { [weak self] in
                self?.openNetworkPicker(accountSelectorCell: accountSelectorCell, tokenItems: availableTokenItems)
            },
            onConfirmTapped: { [weak self] result in
                self?.handleConfirmResult(result, accountSelectorCell: accountSelectorCell)
            }
        )
    }

    func openNetworkPicker(
        accountSelectorCell: AccountSelectorCellModel,
        tokenItems: [TokenItem]
    ) {
        pushCurrentState()

        let pickerVM = NetworkSelectorViewModel(
            tokenItems: tokenItems,
            isTokenAdded: { [configuration] tokenItem in
                configuration.isTokenAdded(tokenItem, accountSelectorCell.cryptoAccountModel)
            },
            onSelectNetwork: { [weak self] selectedTokenItem in
                self?.handleNetworkSelected(
                    tokenItem: selectedTokenItem,
                    accountSelectorCell: accountSelectorCell
                )
            },
            onCancel: { [weak self] in
                self?.back()
            }
        )

        viewState = .networkPicker(viewModel: pickerVM)
    }

    func openAccountPicker(
        currentAccountSelectorCell: AccountSelectorCellModel,
        tokenItem: TokenItem
    ) {
        pushCurrentState()

        configuration.analyticsLogger.logAccountSelectorOpened()

        let pickerVM = AccountSelectorViewModel(
            selectedItem: currentAccountSelectorCell.cryptoAccountModel,
            userWalletModels: userWalletModels,
            cryptoAccountModelsFilter: makeCryptoAccountModelsFilter(),
            availabilityProvider: makeAccountAvailabilityProvider(),
            dropsLockedAccountSections: true,
            onSelect: { [weak self] selectedAccount in
                self?.handleAccountSelected(
                    accountSelectorCell: selectedAccount,
                    tokenItem: tokenItem
                )
            }
        )

        viewState = .accountPicker(viewModel: pickerVM)
    }

    func handleNetworkSelected(
        tokenItem: TokenItem,
        accountSelectorCell: AccountSelectorCellModel
    ) {
        openConfirm(tokenItem: tokenItem, accountSelectorCell: accountSelectorCell)
    }

    func handleAccountSelected(
        accountSelectorCell: AccountSelectorCellModel,
        tokenItem: TokenItem
    ) {
        let availableTokenItems = configuration.getAvailableTokenItems(accountSelectorCell)

        let matchingTokenItem = availableTokenItems.first { $0.networkId == tokenItem.networkId }
            ?? availableTokenItems.first
            ?? tokenItem

        openConfirm(tokenItem: matchingTokenItem, accountSelectorCell: accountSelectorCell)
    }

    func handleConfirmResult(_ result: Result<TokenItem, Error>, accountSelectorCell: AccountSelectorCellModel) {
        switch result {
        case .success(let addedToken):
            coordinator?.presentSuccessToast(with: Localization.marketsTokenAdded)
            FeedbackGenerator.success()

            switch configuration.postAddBehavior {
            case .executeAction(let action):
                action(addedToken, accountSelectorCell)
            case .showGetToken:
                coordinator?.addTokenFlowShowGetToken(for: addedToken, accountSelectorCell: accountSelectorCell)
            }

        case .failure(let error):
            coordinator?.presentErrorToast(with: error.localizedDescription)
            FeedbackGenerator.error()
        }
    }
}

// MARK: - Confirm state factory

private extension AddTokenFlowRedesignedViewModel {
    static func makeConfirmViewState(
        tokenItem: TokenItem,
        accountSelectorCell: AccountSelectorCellModel,
        userWalletModels: [any UserWalletModel],
        configuration: AddTokenFlowConfiguration,
        isAccountSelectionAvailable: Bool,
        onAccountTapped: @escaping () -> Void,
        onNetworkTapped: @escaping () -> Void,
        onConfirmTapped: @escaping (Result<TokenItem, Error>) -> Void
    ) -> ViewState {
        let availableTokenItems = configuration.getAvailableTokenItems(accountSelectorCell)
        return .confirm(viewModel: AddTokenConfirmViewModel(
            tokenItem: tokenItem,
            accountSelectorCell: accountSelectorCell,
            userWalletModels: userWalletModels,
            tokenItemIconInfoBuilder: TokenIconInfoBuilder(),
            isAccountSelectionAvailable: isAccountSelectionAvailable,
            isNetworkSelectionAvailable: availableTokenItems.count > 1,
            analyticsLogger: configuration.analyticsLogger,
            isTokenAdded: configuration.isTokenAdded,
            onAccountTapped: onAccountTapped,
            onNetworkTapped: onNetworkTapped,
            onConfirmTapped: onConfirmTapped
        ))
    }
}

// MARK: - Helpers

private extension AddTokenFlowRedesignedViewModel {
    func userWalletConfig(for accountSelectorItem: AccountSelectorViewModel.AccountSelectorItem) -> UserWalletConfig? {
        userWalletModelsKeyedById[accountSelectorItem.userWalletId]?.config
    }

    func makeCryptoAccountModelsFilter() -> (AccountSelectorViewModel.AccountSelectorItem) -> Bool {
        let customFilter = configuration.accountFilter
        return { [weak self] accountSelectorItem in
            guard let config = self?.userWalletConfig(for: accountSelectorItem),
                  config.hasFeature(.multiCurrency) else { return false }
            guard let customFilter else { return true }
            return customFilter(AddTokenFlowConfiguration.AccountContext(
                account: accountSelectorItem.cryptoAccountModel,
                supportedBlockchains: config.supportedBlockchains
            ))
        }
    }

    func makeAccountAvailabilityProvider() -> (AccountSelectorViewModel.AccountSelectorItem) -> AccountAvailability {
        guard let customProvider = configuration.accountAvailabilityProvider else {
            return { _ in .available }
        }
        return { [weak self] accountSelectorItem in
            let config = self?.userWalletConfig(for: accountSelectorItem)
            return customProvider(AddTokenFlowConfiguration.AccountContext(
                account: accountSelectorItem.cryptoAccountModel,
                supportedBlockchains: config?.supportedBlockchains ?? []
            ))
        }
    }
}

// MARK: - ViewState

extension AddTokenFlowRedesignedViewModel {
    enum ViewState: Equatable {
        case confirm(viewModel: AddTokenConfirmViewModel)
        case networkPicker(viewModel: NetworkSelectorViewModel)
        case accountPicker(viewModel: AccountSelectorViewModel)

        var id: String {
            switch self {
            case .confirm: return "confirm"
            case .networkPicker: return "networkPicker"
            case .accountPicker: return "accountPicker"
            }
        }

        var title: String {
            switch self {
            case .confirm:
                return Localization.commonAddToken
            case .networkPicker:
                return Localization.commonChooseNetwork
            case .accountPicker(let viewModel):
                return viewModel.displayMode == .accounts
                    ? Localization.commonChooseAccount
                    : Localization.commonChooseWallet
            }
        }

        nonisolated static func == (lhs: ViewState, rhs: ViewState) -> Bool {
            switch (lhs, rhs) {
            case (.confirm(let l), .confirm(let r)): return l == r
            case (.networkPicker(let l), .networkPicker(let r)): return l == r
            case (.accountPicker(let l), .accountPicker(let r)): return l == r
            default: return false
            }
        }
    }
}
