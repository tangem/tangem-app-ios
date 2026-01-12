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
import TangemAssets
import struct TangemUIUtils.AlertBinder

final class AccountDetailsViewModel: ObservableObject {
    typealias AccountDetailsRoutable =
        any BaseAccountDetailsRoutable &
        CryptoAccountDetailsRoutable

    // MARK: - State

    @Published private(set) var accountName: String = ""
    @Published private(set) var accountIcon = AccountModelUtils.UI.newAccountIcon()
    @Published var alert: AlertBinder?
    @Published var archiveAccountDialogPresented = false

    @Published private(set) var archivingState: ArchivingState?

    // MARK: - Dependencies

    private let account: any BaseAccountModel
    private let accountModelsManager: AccountModelsManager
    private weak var coordinator: AccountDetailsRoutable?

    // MARK: - Internal state

    private let actions: [Action]
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
        archivingState = actions.contains(.archive) ? .readyToBeArchived : nil

        bind()
        applySnapshot()
    }

    deinit {
        archiveAccountTask?.cancel()
    }

    // MARK: - View data

    var accountIconViewData: AccountIconView.ViewData {
        AccountModelUtils.UI.iconViewData(icon: account.icon, accountName: account.name)
    }

    var canBeEdited: Bool {
        actions.contains(.edit)
    }

    var canManageTokens: Bool {
        actions.contains(.manageTokens)
    }

    // MARK: - Methods

    func onFirstAppear() {
        Analytics.log(.accountSettingsScreenOpened)
    }

    func archiveAccount() {
        archivingState = .archivingInProgress
        archiveAccountTask?.cancel()

        archiveAccountTask = Task { [weak self] in
            guard let self else {
                return
            }
            
            await self.account.resolve(using: ArchiveAccountResolver(viewModel: self))
        }
    }

    // MARK: - Routing

    func showShouldArchiveDialog() {
        Analytics.log(.accountSettingsButtonArchiveAccount)
        archiveAccountDialogPresented = true
    }

    func handleDialogDismissed() {
        if archivingState == .readyToBeArchived {
            Analytics.log(.accountSettingsButtonCancelAccountArchivation)
        }
    }

    func openEditAccount() {
        Analytics.log(.accountSettingsButtonEdit)
        coordinator?.editAccount()
    }

    func openManageTokens() {
        Analytics.log(.accountSettingsButtonManageTokens)
        coordinator?.manageTokens()
    }

    func getArchivingButtonTitle(from state: ArchivingState) -> String {
        switch state {
        case .archivingInProgress:
            Localization.accountDetailsArchiving
        case .readyToBeArchived:
            Localization.accountDetailsArchive
        }
    }

    func getArchivingButtonColor(from state: ArchivingState) -> Color {
        switch state {
        case .archivingInProgress:
            Colors.Text.disabled

        case .readyToBeArchived:
            Colors.Text.warning
        }
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
        Analytics.log(.accountSettingsAccountArchived)
        coordinator?.close()

        Toast(view: SuccessToast(text: Localization.accountArchiveSuccessMessage))
            .present(layout: .top(padding: 24), type: .temporary(interval: 4))
    }

    @MainActor
    private func handleAccountArchivingFailure(error: AccountArchivationError) {
        archivingState = .readyToBeArchived

        Analytics.log(event: .accountSettingsAccountError, params: [
            .source: Analytics.ParameterValue.accountSourceArchive.rawValue,
            .errorDescription: String(describing: error),
        ])

        let title: String
        let message: String
        let buttonText: String

        switch error {
        case .participatesInReferralProgram:
            title = Localization.accountCouldNotArchiveReferralProgramTitle
            message = Localization.accountCouldNotArchiveReferralProgramMessage
            buttonText = Localization.commonGotIt

        case .unknownError:
            title = Localization.commonSomethingWentWrong
            message = Localization.accountGenericErrorDialogMessage
            buttonText = Localization.commonOk
        }

        alert = AlertBuilder.makeAlertWithDefaultPrimaryButton(
            title: title,
            message: message,
            buttonText: buttonText
        )

        AccountsLogger.error("Failed to archive account", error: error)
    }
}

// MARK: - Details actions

extension AccountDetailsViewModel {
    enum Action {
        case edit
        case archive
        case manageTokens
    }
}

// MARK: - ArchivingState

extension AccountDetailsViewModel {
    enum ArchivingState {
        case readyToBeArchived
        case archivingInProgress
    }
}

// MARK: - ArchiveAccountResolver

extension AccountDetailsViewModel {
    private struct ArchiveAccountResolver: AccountModelResolving {
        let viewModel: AccountDetailsViewModel
        
        func resolve(accountModel: any CryptoAccountModel) async -> Void {
            do throws(AccountArchivationError) {
                try await accountModel.archive()
                await viewModel.handleAccountArchivingSuccess()
            } catch {
                await viewModel.handleAccountArchivingFailure(error: error)
            }
        }
        
        func resolve(accountModel: any SmartAccountModel) async -> Void {
            // No archiving action for SmartAccountModel
        }
        
        func resolve(accountModel: any VisaAccountModel) async -> Void {
            // No archiving action for VisaAccountModel
        }
    }
}
