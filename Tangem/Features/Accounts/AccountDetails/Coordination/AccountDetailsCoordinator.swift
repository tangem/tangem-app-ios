//
//  AccountDetailsCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class AccountDetailsCoordinator: CoordinatorObject {
    // MARK: - Navigation actions

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private var options: Options?

    // MARK: - Root view model

    @Published private(set) var rootViewModel: AccountDetailsViewModel?

    // MARK: - Child coordinators

    @Published var manageTokensCoordinator: ManageTokensCoordinator?

    // MARK: - Child view models

    @Published var editAccountViewModel: AccountFormViewModel?

    init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        rootViewModel = AccountDetailsViewModel(
            account: options.account,
            accountModelsManager: options.accountModelsManager,
            coordinator: self
        )
    }
}

// MARK: - Options

extension AccountDetailsCoordinator {
    struct Options {
        let account: any BaseAccountModel
        let userWalletConfig: UserWalletConfig
        let accountModelsManager: AccountModelsManager
    }
}

// MARK: - BaseAccountDetailsRoutable

extension AccountDetailsCoordinator: BaseAccountDetailsRoutable {
    func editAccount() {
        guard let options else { return }

        editAccountViewModel = AccountFormViewModel(
            accountModelsManager: options.accountModelsManager,
            flowType: .edit(account: options.account),
            closeAction: { [weak self] _ in
                self?.editAccountViewModel = nil
            }
        )
    }

    func close() {
        dismiss()
    }
}

// MARK: - CryptoAccountDetailsRoutable

extension AccountDetailsCoordinator: CryptoAccountDetailsRoutable {
    func manageTokens() {
        // [REDACTED_TODO_COMMENT]
        guard let options, let cryptoAccount = options.account as? any CryptoAccountModel else {
            return
        }

        let coordinator = ManageTokensCoordinator(
            dismissAction: { [weak self] in
                self?.manageTokensCoordinator = nil
            },
            popToRootAction: popToRootAction
        )

        let context = AccountsAwareManageTokensContext(
            accountModelsManager: options.accountModelsManager,
            currentAccount: cryptoAccount
        )

        coordinator.start(
            with: ManageTokensCoordinator.Options(
                context: context,
                userWalletConfig: options.userWalletConfig
            )
        )

        manageTokensCoordinator = coordinator
    }
}
