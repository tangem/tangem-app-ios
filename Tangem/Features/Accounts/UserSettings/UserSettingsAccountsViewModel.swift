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

    @Published var accountRowViewModels: [AccountRowButtonViewModel] = []
    @Published private(set) var addNewAccountButton: AddListItemButton.ViewData?
    @Published private(set) var archivedAccountsButton: ArchivedAccountsButtonViewData?

    // MARK: - Dependencies

    private let accountModelsManager: AccountModelsManager
    private let userWalletConfig: UserWalletConfig
    private weak var coordinator: UserSettingsAccountsRoutable?

    private var cachedViewModels: [AnyHashable: AccountRowButtonViewModel] = [:]
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

        bind()
    }

    // MARK: - Public

    var moreThatOneActiveAccount: Bool {
        accountRowViewModels.count > 1
    }

    // MARK: - Binding

    private func bind() {
        bindAccountRowButtonViewModels()
        bindArchivedAccountsButton()
        bindAddNewAccountButton()
    }

    private func bindAccountRowButtonViewModels() {
        accountModelsManager.accountModelsPublisher
            .map { Self.extractVisibleAccounts(from: $0) }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, accounts in
                viewModel.updateAccountRowButtonViewModels(from: accounts)
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

    // MARK: - View Data Factory

    private func makeAddNewAccountButtonViewData(from accountModels: [AccountModel]) -> AddListItemButton.ViewData {
        let accountCount = countAccounts(accountModels)
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
        coordinator?.openAccountDetails(
            account: account,
            accountModelsManager: accountModelsManager,
            userWalletConfig: userWalletConfig
        )
    }

    private func onTapArchivedAccounts() {
        coordinator?.openArchivedAccounts(accountModelsManager: accountModelsManager)
    }

    private func onTapNewAccount() {
        coordinator?.addNewAccount(accountModelsManager: accountModelsManager)
    }

    private func handleAccountLimitReached() {
        coordinator?.handleAccountsLimitReached()
    }

    // MARK: - Utilities

    private func updateAccountRowButtonViewModels(from accounts: [any BaseAccountModel]) {
        let currentIds = Set(accounts.map { $0.id.toAnyHashable() })
        cachedViewModels = cachedViewModels.filter { currentIds.contains($0.key) }

        accountRowViewModels = accounts.map { account in
            let id = account.id.toAnyHashable()

            if let cached = cachedViewModels[id] {
                return cached
            }

            let newVM = AccountRowButtonViewModel(accountModel: account) { [weak self] in
                self?.onTapAccount(account: account)
            }
            cachedViewModels[id] = newVM
            return newVM
        }
    }

    private static func extractVisibleAccounts(from accountModels: [AccountModel]) -> [any BaseAccountModel] {
        accountModels.flatMap { accountModel -> [any BaseAccountModel] in
            switch accountModel {
            case .standard(.single):
                // Single accounts are not displayed in the UI
                return []
            case .standard(.multiple(let cryptoAccountModels)):
                return cryptoAccountModels
            }
        }
    }

    private func countAccounts(_ accountModels: [AccountModel]) -> Int {
        accountModels.reduce(0) { count, accountModel in
            // When new account types appear, clarify with your manager
            // Whether those accounts should participate in this logic
            switch accountModel {
            case .standard(.single):
                return count + 1
            case .standard(.multiple(let cryptoAccountModels)):
                return count + cryptoAccountModels.count
            }
        }
    }
}

extension UserSettingsAccountsViewModel {
    struct ArchivedAccountsButtonViewData: Identifiable {
        let text: String
        let action: () -> Void

        var id: String {
            text
        }
    }
}
