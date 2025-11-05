//
//  AccountDetailsViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import TangemUI
import TangemAccounts
import TangemFoundation
import TangemLocalization
import struct TangemUIUtils.AlertBinder

final class AccountDetailsViewModel: ObservableObject {
    typealias AccountDetailsRoutable =
        any BaseAccountDetailsRoutable &
        CryptoAccountDetailsRoutable

    // MARK: - State

    @Published private(set) var accountName: String = ""
    @Published private(set) var accountIcon = AccountModel.Icon(name: .letter, color: .azure)
    @Published var alert: AlertBinder?
    @Published var archiveAccountDialogPresented = false

    // MARK: - Dependencies

    private let account: any BaseAccountModel
    private let accountModelsManager: AccountModelsManager
    private weak var coordinator: AccountDetailsRoutable?

    // MARK: - Internal state

    private let actions: [AccountDetailsAction]
    private var archiveAccountTask: Task<Void, Never>?
    private var bag = Set<AnyCancellable>()

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
        AccountModelUtils.UI.iconViewData(icon: account.icon, accountName: account.name)
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
        archiveAccountTask?.cancel()
        archiveAccountTask = runTask(in: self) { viewModel in
            do {
                let identifier = viewModel.account.id
                try await viewModel.accountModelsManager.archiveCryptoAccount(withIdentifier: identifier)
                await viewModel.handleAccountArchivingSuccess()
            } catch {
                await viewModel.handleAccountArchivingFailure(error: error)
            }
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

    @MainActor
    private func handleAccountArchivingSuccess() {
        coordinator?.close()

        Toast(view: SuccessToast(text: Localization.accountArchiveSuccessMessage))
            .present(layout: .top(padding: 24), type: .temporary(interval: 4))
    }

    @MainActor
    private func handleAccountArchivingFailure(error: Error) {
        let title: String
        let message: String
        let buttonTitle: String

        switch error {
        case let error as ArchivedCryptoAccountConditionsValidator.Error where error == .participatesInReferralProgram:
            title = Localization.accountCouldNotArchiveReferralProgramTitle
            message = Localization.accountCouldNotArchiveReferralProgramMessage
            buttonTitle = Localization.commonGotIt
        default:
            title = Localization.commonSomethingWentWrong
            message = Localization.accountCouldNotArchive
            buttonTitle = Localization.commonOk
        }

        alert = AlertBuilder.makeAlert(
            title: title,
            message: message,
            primaryButton: .default(Text(buttonTitle))
        )

        AccountsLogger.error("Failed to archive account", error: error)
    }
}

enum AccountDetailsAction {
    case edit
    case archive
    case manageTokens
}
