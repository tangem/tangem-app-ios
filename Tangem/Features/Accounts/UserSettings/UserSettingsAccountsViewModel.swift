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

    @Published var accountRows: [_UserSettingsAccountRowViewData] = []
    @Published private(set) var addNewAccountButton: AddListItemButton.ViewData?
    @Published private(set) var archivedAccountButton: ArchivedAccountsButtonViewData?

    // MARK: - Dependencies

    private let accountModelsManager: AccountModelsManager
    private let accountsReorderer: UserSettingsAccountsReorderer
    private let userWalletConfig: UserWalletConfig
    private weak var coordinator: UserSettingsAccountsRoutable?
    private var bag = Set<AnyCancellable>()

    // MARK: - Init

    init(
        accountModels: [AccountModel],
        accountModelsManager: AccountModelsManager,
        accountModelsReorderer: AccountModelsReordering,
        userWalletConfig: UserWalletConfig,
        coordinator: UserSettingsAccountsRoutable?
    ) {
        self.accountModelsManager = accountModelsManager
        self.userWalletConfig = userWalletConfig
        self.coordinator = coordinator

        accountsReorderer = UserSettingsAccountsReorderer(
            accountModelsReorderer: accountModelsReorderer,
            debounceInterval: Constants.accountsReorderingDebounceInterval
        )

        accountRows = accountModels.flatMap { accountModel in
            AccountModelToUserSettingsViewDataMapper.map(
                from: accountModel,
                onTap: { [weak self] accountModel in
                    self?.onTapAccount(account: accountModel)
                }
            )
        }

        bind()
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
            .assign(to: \.archivedAccountButton, on: self, ownership: .weak)
            .store(in: &bag)

        accountModelsManager
            .accountModelsPublisher
            .withWeakCaptureOf(self)
            .map { viewModel, accountModels in
                viewModel.makeAddNewAccountButtonViewData(from: accountModels)
            }
            .receiveOnMain()
            .assign(to: \.addNewAccountButton, on: self, ownership: .weak)
            .store(in: &bag)

        $accountRows
            .pairwise()
            .withWeakCaptureOf(self)
            .sink { viewModel, input in
                let (oldRows, newRows) = input
                viewModel.accountsReorderer.schedulePendingReorderIdNeeded(oldRows: oldRows, newRows: newRows)
            }
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

// MARK: - Auxiliary types

extension UserSettingsAccountsViewModel {
    struct ArchivedAccountsButtonViewData: Identifiable {
        let text: String
        let action: () -> Void

        var id: String {
            text
        }
    }

    // [REDACTED_TODO_COMMENT]
    struct _UserSettingsAccountRowViewData: Identifiable {
        var id: AnyHashable {
            viewData.id
        }

        let viewData: UserSettingsAccountRowViewData
        /** private */ let persId: any AccountModelPersistentIdentifierConvertible

        init(viewData: UserSettingsAccountRowViewData, persId: any AccountModelPersistentIdentifierConvertible) {
            self.viewData = viewData
            self.persId = persId
        }
    }
}

// MARK: - Constants

private extension UserSettingsAccountsViewModel {
    enum Constants {
        static let accountsReorderingDebounceInterval = 1.0
    }
}
