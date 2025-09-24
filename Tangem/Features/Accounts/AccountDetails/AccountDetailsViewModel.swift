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
        any BaseEditableAccountDetailsRoutable &
        CryptoAccountDetailsRoutable &
        ArchivableAccountRoutable

    // MARK: - State

    @Published private(set) var accountName: String = ""
    @Published private(set) var accountIcon = AccountModel.Icon(name: .letter, color: .azure)

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

    var accountIconNameMode: AccountIconView.NameMode {
        switch account.icon.name {
        case .letter:
            .letter(String(account.name.first ?? "_"))
        default:
            .imageType(AccountModelUtils.UI.iconAsset(from: account.icon.name))
        }
    }

    var accountIconColor: Color {
        AccountModelUtils.UI.iconColor(from: account.icon.color)
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

    // MARK: - Routing

    func archiveAccount() {
        coordinator?.openArchiveAccountDialog { [weak self] in
            guard let self else { return }
            try accountModelsManager.archiveCryptoAccount(withIdentifier: account.id)
        }
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
