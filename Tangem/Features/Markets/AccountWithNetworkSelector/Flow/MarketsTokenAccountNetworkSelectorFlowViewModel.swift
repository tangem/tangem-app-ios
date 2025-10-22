//
//  MarketsTokenAccountNetworkSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

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

        if let oneAndOnlyAccount {
            openNetworkSelection(
                cryptoAccount: oneAndOnlyAccount,
                context: .root
            )
        } else {
            openAccountSelector(
                selectedItem: nil,
                context: .root,
                onSelectAccount: { [weak self] baseAccountModel in
                    guard let cryptoAccountModel = baseAccountModel as? (any CryptoAccountModel) else {
                        return
                    }

                    self?.openNetworkSelection(
                        cryptoAccount: cryptoAccountModel,
                        context: .fromChooseAccount
                    )
                }
            )
        }
    }

    private var oneAndOnlyAccount: (any CryptoAccountModel)? {
        let availableUserWalletModels = userWalletDataProvider.userWalletModels.filter { !$0.isUserWalletLocked }

        guard
            let firstAndOnlyUserWalletModel = availableUserWalletModels.first,
            availableUserWalletModels.count == 1
        else {
            return nil
        }

        switch firstAndOnlyUserWalletModel.accountModelsManager.accountModels.first {
        case .standard(let cryptoAccounts):
            switch cryptoAccounts {
            case .multiple(let cryptoAccountModels):
                if let firstAndOnlyCryptoAccount = cryptoAccountModels.first, cryptoAccountModels.count == 1 {
                    return firstAndOnlyCryptoAccount
                }

                return nil

            case .single(let cryptoAccountModel):
                return cryptoAccountModel
            }

        case nil:
            return nil
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

    private func pushCurrentState() {
        navigationStack.append(viewState)
    }

    private func openNetworkSelection(
        cryptoAccount: any CryptoAccountModel,
        context: NavigationContext
    ) {
        // Push current state to stack before navigating
        // This allows going back from networkSelector to accountSelector in normal flow
        pushCurrentState()

        viewState = .networksSelection(
            viewModel: MarketsNetworkSelectorViewModel(
                data: inputData,
                selectedUserWalletModel: userWalletDataProvider.selectedUserWalletModel,
                selectedAccount: cryptoAccount
            ),
            context: context
        )
    }

    private func openAccountSelector(
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

    // [REDACTED_TODO_COMMENT]
    /*
     private func openAddToken() {
         // From addToken screen, user cannot go back
         // Clear the navigation stack
         navigationStack.removeAll()

         viewState = .addToken(viewModel: AddTokenViewModel(...))
     }

     private func openGetToken() {
         pushCurrentState()
         viewState = .getToken(viewModel: GetTokenViewModel(...))
     }
     */
}
