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

final class UserSettingsAccountsViewModel: ObservableObject {
    // MARK: - State

    @Published var accountRows: [UserSettingsAccountRowViewData] = []
    @Published private(set) var addNewAccountButton: AddListItemButton.ViewData?
    @Published private(set) var archivedAccountButton: ArchivedAccountsButtonViewData?

    private let accountModelsManager: AccountModelsManager
    private weak var coordinator: UserSettingsAccountsRoutable?
    private var bag = Set<AnyCancellable>()

    init(
        accountModels: [AccountModel],
        accountModelsManager: AccountModelsManager,
        coordinator: UserSettingsAccountsRoutable?
    ) {
        self.accountModelsManager = accountModelsManager
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
    }

    private func bind() {
        Just(accountModelsManager.canAddCryptoAccounts)
            .withWeakCaptureOf(self)
            .map { viewModel, enabled in
                AddListItemButton.ViewData(
                    text: Localization.accountFormCreateButton,
                    isEnabled: enabled,
                    action: { [weak self] in
                        self?.onTapNewAccount()
                    }
                )
            }
            .assign(to: \.addNewAccountButton, on: self, ownership: .weak)
            .store(in: &bag)

        accountModelsManager.hasArchivedCryptoAccounts
            .withWeakCaptureOf(self)
            .map { viewModel, hasArchivedAccounts in
                hasArchivedAccounts
                    ? ArchivedAccountsButtonViewData(text: Localization.accountArchivedAccounts, action: viewModel.onTapArchivedAccounts)
                    : nil
            }
            .assign(to: \.archivedAccountButton, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func onTapAccount(account: any BaseAccountModel) {
        coordinator?.openAccountDetails(account: account, accountModelsManager: accountModelsManager)
    }

    private func onTapArchivedAccounts() {
        // [REDACTED_TODO_COMMENT]
    }

    private func onTapNewAccount() {
        coordinator?.addNewAccount(accountModelsManager: accountModelsManager)
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
