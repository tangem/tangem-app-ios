//
//  UserSettingsAccountsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemUIUtils
import Combine
import CombineExt
import TangemLocalization
import TangemFoundation

final class UserSettingsAccountsViewModel: ObservableObject {
    // MARK: - Published State

    @Published var accountRows: [UserSettingsAccountRowViewData] = []
    @Published private(set) var addNewAccountButton: AddListItemButton.ViewData?
    @Published private(set) var archivedAccountButton: ArchivedAccountsButtonViewData?

    // MARK: - Dependencies

    private let accountModelsManager: AccountModelsManager
    private let userWalletConfig: UserWalletConfig
    private weak var coordinator: UserSettingsAccountsRoutable?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        accountModels: [AccountModel],
        accountModelsManager: AccountModelsManager,
        userWalletConfig: UserWalletConfig,
        coordinator: UserSettingsAccountsRoutable?
    ) {
        self.accountModelsManager = accountModelsManager
        self.userWalletConfig = userWalletConfig
        self.coordinator = coordinator

        accountRows = accountModels.flatMap {
            AccountModelToUserSettingsViewDataMapper.map(
                from: $0,
                onTap: { [weak self] in
                    self?.onTapAccount(account: $0)
                }
            )
        }

        bind()
        print("❇️ init \(objectDescription(self)) ❇️")
    }

    deinit {
        print("🔴 deinit \(objectDescription(self)) 🔴")
    }

    // MARK: - Public

    var moreThatOneActiveAccount: Bool {
        accountRows.count > 1
    }

    func makeAccountRowInput(from model: UserSettingsAccountRowViewData) -> AccountRowViewModel.Input {
        AccountRowViewModel.Input(
            iconData: model.accountIconViewData,
            name: model.name,
            subtitle: model.description,
            balancePublisher: model.balancePublisher,
            availability: .available
        )
    }

    // MARK: - Binding

    private func bind() {
        bindArchivedAccountsButton()
        bindAddNewAccountButton()
    }

    private func bindArchivedAccountsButton() {
        accountModelsManager.hasArchivedCryptoAccountsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, hasArchivedAccounts in
                guard hasArchivedAccounts else {
                    return nil
                }

                return ArchivedAccountsButtonViewData(text: Localization.accountArchivedAccounts) { [weak viewModel] in
                    viewModel?.onTapArchivedAccounts()
                }
            }
            .assign(to: \.archivedAccountButton, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func bindAddNewAccountButton() {
        accountModelsManager.accountModelsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, accountModels in
                viewModel.makeAddNewAccountButtonViewData(from: accountModels)
            }
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
