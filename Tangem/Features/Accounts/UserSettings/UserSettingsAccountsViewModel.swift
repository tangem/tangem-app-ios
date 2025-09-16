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
import TangemLocalization
import TangemFoundation

final class UserSettingsAccountsViewModel: ObservableObject {
    // MARK: - State

    @Published var accountRows: [UserSettingsAccountRowViewData] = []
    @Published private(set) var addNewAccountButton: AddListItemButton.ViewData?
    @Published private(set) var archivedAccountButton: ArchivedAccountsButtonViewData?

    // MARK: - Dependencies

    private weak var coordinator: UserSettingsAccountsRoutable?
    private let canAddNewAccountPublisher: AnyPublisher<Bool, Never>
    private let archivedAccountsPublisher: AnyPublisher<AccountModel, Never>
    private let userWalletId: UserWalletId
    private let accountModelsManager: any AccountModelsManager
    private var bag: Set<AnyCancellable> = []

    init(
        accountModels: [AccountModel],
        userWalletId: UserWalletId,
        accountModelsManager: any AccountModelsManager,
        canAddNewAccountPublisher: AnyPublisher<Bool, Never>,
        archivedAccountsPublisher: AnyPublisher<AccountModel, Never>,
        coordinator: UserSettingsAccountsRoutable?
    ) {
        self.canAddNewAccountPublisher = canAddNewAccountPublisher
        self.archivedAccountsPublisher = archivedAccountsPublisher
        self.coordinator = coordinator
        self.userWalletId = userWalletId
        self.accountModelsManager = accountModelsManager

        accountRows = accountModels.flatMap {
            AccountModelMapper.map(
                from: $0,
                onTap: { [weak self] in
                    self?.onTapAccount(account: $0)
                }
            )
        }

        bind()
    }

    private func bind() {
        canAddNewAccountPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, enabled in
                viewModel.addNewAccountButton = AddListItemButton.ViewData(
                    text: Localization.accountFormCreateButton,
                    isEnabled: enabled,
                    action: {
                        viewModel.onTapNewAccount()
                    }
                )
            }
            .store(in: &bag)

        archivedAccountsPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, accountModel in
                viewModel.archivedAccountButton = ArchivedAccountsButtonViewData(
                    text: Localization.accountArchivedAccounts,
                    action: { viewModel.onTapArchivedAccounts(accountModel: accountModel) }
                )
            }
            .store(in: &bag)
    }

    private func onTapAccount(account: CommonCryptoAccountModel) {
        // [REDACTED_TODO_COMMENT]
    }

    private func onTapArchivedAccounts(accountModel: AccountModel) {
        // [REDACTED_TODO_COMMENT]
    }

    private func onTapNewAccount() {
        coordinator?.addNewAccount(
            userWalletId: userWalletId,
            accountIndex: accountModelsManager.totalCryptoAccountsCount + 1,
            accountModelsManager: accountModelsManager
        )
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
