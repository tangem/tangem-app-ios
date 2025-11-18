//
//  AccountDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts
import SwiftUI
import TangemUI
import Combine
import TangemLocalization

final class AccountDetailsViewModel: ObservableObject {
    typealias AccountDetailsRoutable =
        any BaseAccountDetailsRoutable &
        CryptoAccountDetailsRoutable

    // MARK: - State

    @Published private(set) var accountName: String = ""
    @Published private(set) var accountIcon = AccountModel.Icon(name: .letter, color: .azure)
    @Published var archiveAccountDialogPresented = false

    // MARK: - Dependencies

    private let account: any BaseAccountModel
    private let accountModelsManager: AccountModelsManager
    private let actions: [AccountDetailsAction]

    private var bag = Set<AnyCancellable>()

    private weak var coordinator: AccountDetailsRoutable?

    init(
        account: any BaseAccountModel,
        accountModelsManager: AccountModelsManager,
        coordinator: AccountDetailsRoutable
    ) {
        self.account = account
        self.accountModelsManager = accountModelsManager
        self.coordinator = coordinator
        actions = AccountDetailsActionsProvider.getAvailableActions(for: account)

        bind()
        applySnapshot()
    }

    // MARK: - View data

    var accountIconViewData: AccountIconView.ViewData {
        AccountIconView.ViewData(
            backgroundColor: AccountModelUtils.UI.iconColor(from: account.icon.color),
            nameMode: AccountModelUtils.UI.nameMode(from: account.icon.name, accountName: account.name)
        )
    }

    var canBeArchived: Bool {
        actions.contains(.archive)
    }

    var canBeEdited: Bool {
        actions.contains(.edit)
    }

    var canManageTokens: Bool {
        actions.contains(.manageTokens)
    }

    // MARK: - Methods

    func archiveAccount() {
        do {
            try accountModelsManager.archiveCryptoAccount(withIdentifier: account.id)

            coordinator?.close()

            Toast(view: SuccessToast(text: Localization.accountArchiveSuccessMessage))
                .present(layout: .top(padding: 24), type: .temporary(interval: 4))
        } catch {
            Toast(view: WarningToast(text: Localization.genericError))
                .present(layout: .top(padding: 24), type: .temporary(interval: 4))
        }
    }

    // MARK: - Routing

    func showShouldArchiveDialog() {
        archiveAccountDialogPresented = true
    }

    func openEditAccount() {
        coordinator?.editAccount()
    }

    func openManageTokens() {
        coordinator?.manageTokens()
    }

    // MARK: - Private

    private func bind() {
        account.didChangePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { vm, _ in vm.applySnapshot() }
            .store(in: &bag)
    }

    private func applySnapshot() {
        accountName = account.name
        accountIcon = account.icon
    }
}

enum AccountDetailsAction {
    case edit
    case archive
    case manageTokens
}
