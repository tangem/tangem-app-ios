//
//  UserSettingsAccountsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import Combine
import CombineExt
import TangemLocalization
import TangemFoundation
import TangemAccounts

final class UserSettingsAccountsViewModel: ObservableObject {
    // MARK: - Published State

    @Published var accountRows: [AccountRow] = []
    @Published private(set) var addNewAccountButton: AddListItemButton.ViewData?
    @Published private(set) var archivedAccountsButton: ArchivedAccountsButtonViewData?

    // MARK: - Dependencies

    private let accountModelsManager: AccountModelsManager
    private let accountsReorderer: UserSettingsAccountsReorderer
    private let userWalletConfig: UserWalletConfig
    private weak var coordinator: UserSettingsAccountsRoutable?

    private var cachedAccountRows: [AnyHashable: AccountRow] = [:]
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        accountModelsManager: AccountModelsManager,
        userWalletConfig: UserWalletConfig,
        coordinator: UserSettingsAccountsRoutable?
    ) {
        self.accountModelsManager = accountModelsManager
        self.userWalletConfig = userWalletConfig
        self.coordinator = coordinator
        accountsReorderer = UserSettingsAccountsReorderer(
            accountModelsReorderer: accountModelsManager,
            debounceInterval: Constants.accountsReorderingDebounceInterval
        )

        bind()
    }

    // MARK: - Public

    var moreThatOneActiveAccount: Bool {
        accountRows.count > 1
    }

    // MARK: - Binding

    private func bind() {
        bindAccountRows()
        bindArchivedAccountsButton()
        bindAddNewAccountButton()
        bindPendingReorder()
    }

    private func bindAccountRows() {
        accountModelsManager
            .cryptoAccountModelsPublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, accounts in
                viewModel.updateAccountRows(from: accounts)
            }
            .store(in: &bag)
    }

    private func bindArchivedAccountsButton() {
        accountModelsManager
            .hasArchivedCryptoAccountsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, hasArchivedAccounts in
                guard hasArchivedAccounts else {
                    return nil
                }

                return ArchivedAccountsButtonViewData(text: Localization.accountArchivedAccounts) { [weak viewModel] in
                    viewModel?.onTapArchivedAccounts()
                }
            }
            .receiveOnMain()
            .assign(to: \.archivedAccountsButton, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func bindAddNewAccountButton() {
        accountModelsManager
            .accountModelsPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .map { viewModel, accountModels in
                viewModel.makeAddNewAccountButtonViewData(from: accountModels)
            }
            .receiveOnMain()
            .assign(to: \.addNewAccountButton, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func bindPendingReorder() {
        $accountRows
            .removeDuplicates { lhs, rhs in
                lhs.map(\.id) == rhs.map(\.id)
            }
            .pairwise()
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                let (oldRows, newRows) = input
                viewModel.accountsReorderer.schedulePendingReorderIfNeeded(
                    oldRows: oldRows,
                    newRows: newRows,
                    persistentIdentifierProvider: Self.extractPersistentIdentifier(from:)
                )
            }
            .store(in: &bag)
    }

    // MARK: - View Data Factory

    private func makeAddNewAccountButtonViewData(from accountModels: [AccountModel]) -> AddListItemButton.ViewData {
        let accountCount = accountModels.cryptoAccountsCount
        let isLimitReached = accountCount >= AccountModelUtils.maxNumberOfAccounts
        let buttonState = makeAddNewAccountButtonState(isLimitReached: isLimitReached)

        return AddListItemButton.ViewData(
            text: Localization.accountFormCreateButton,
            state: buttonState
        )
    }

    private func makeAddNewAccountButtonState(isLimitReached: Bool) -> AddListItemButton.State {
        if isLimitReached {
            .disabled(action: { [weak self] in
                self?.handleAccountLimitReached()
            })
        } else {
            .enabled(action: { [weak self] in
                self?.onTapNewAccount()
            })
        }
    }

    // MARK: - Actions

    private func onTapAccount(account: any BaseAccountModel) {
        Analytics.log(.walletSettingsButtonOpenExistingAccount)
        coordinator?.openAccountDetails(
            account: account,
            accountModelsManager: accountModelsManager,
            userWalletConfig: userWalletConfig
        )
    }

    private func onTapArchivedAccounts() {
        Analytics.log(.walletSettingsButtonArchivedAccounts)
        coordinator?.openArchivedAccounts(accountModelsManager: accountModelsManager)
    }

    private func onTapNewAccount() {
        Analytics.log(event: .walletSettingsButtonAddAccount, params: [.productType: userWalletConfig.productType.rawValue])
        coordinator?.addNewAccount(accountModelsManager: accountModelsManager)
    }

    private func handleAccountLimitReached() {
        coordinator?.handleAccountsLimitReached()
    }

    // MARK: - Utilities

    private func updateAccountRows(from accounts: [any BaseAccountModel]) {
        let currentIds = Set(accounts.map { $0.id.toAnyHashable() })
        cachedAccountRows = cachedAccountRows.filter { currentIds.contains($0.key) }

        accountRows = accounts.map { account in
            let id = account.id.toAnyHashable()

            if let cached = cachedAccountRows[id] {
                return cached
            }

            let viewModel = AccountRowButtonViewModel(accountModel: account) { [weak self] in
                self?.onTapAccount(account: account)
            }
            let accountRow = AccountRow(viewModel: viewModel, accountModel: account)
            cachedAccountRows[id] = accountRow

            return accountRow
        }
    }

    private static func extractPersistentIdentifier(
        from accountRow: AccountRow
    ) -> any AccountModelPersistentIdentifierConvertible {
        accountRow.accountModel.id
    }
}

// MARK: - Auxiliary types

extension UserSettingsAccountsViewModel {
    struct ArchivedAccountsButtonViewData: Identifiable {
        let text: String
        let action: () -> Void

        var id: String {
            text
        }
    }

    /// An opaque wrapper to prevent an exposure of the `BaseAccountModel` associated with the row.
    struct AccountRow: Identifiable {
        var id: AccountRowButtonViewModel.ID { viewModel.id }
        let viewModel: AccountRowButtonViewModel
        fileprivate let accountModel: any BaseAccountModel

        fileprivate init(
            viewModel: AccountRowButtonViewModel,
            accountModel: any BaseAccountModel
        ) {
            self.viewModel = viewModel
            self.accountModel = accountModel
        }
    }
}

// MARK: - Constants

private extension UserSettingsAccountsViewModel {
    enum Constants {
        static let accountsReorderingDebounceInterval = 1.0
    }
}
