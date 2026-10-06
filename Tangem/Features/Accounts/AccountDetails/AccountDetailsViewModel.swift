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
import TangemAccessibilityIdentifiers
import struct TangemUIUtils.AlertBinder

final class AccountDetailsViewModel: ObservableObject {
    typealias AccountDetailsRoutable =
        any BaseAccountDetailsRoutable &
        CryptoAccountDetailsRoutable

    // MARK: - State

    @Published private(set) var title: String = ""
    @Published private(set) var accountName: String = ""
    @Published private(set) var accountIcon: AccountModel.Icon = .composite(AccountModelUtils.UI.newAccountIcon())
    @Published private(set) var managementRowViewModels: [DefaultRowViewModel] = []
    @Published private(set) var supportedNetworksHint: AttributedString?
    @Published private(set) var archiveRowViewModel: DefaultRowViewModel?
    @Published var alert: AlertBinder?
    @Published var archiveAccountDialogPresented = false

    @Published private(set) var archivingState: ArchivingState? {
        didSet { updateArchiveRow() }
    }

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

        setupView()
        bind()
    }

    deinit {
        archiveAccountTask?.cancel()
    }

    // MARK: - View data

    var accountIconViewData: AccountIconView.ViewData {
        AccountModelUtils.UI.iconViewData(icon: accountIcon, accountName: accountName)
    }

    var canBeEdited: Bool {
        actions.contains(.edit)
    }

    var isArchivingInProgress: Bool {
        archivingState == .archivingInProgress
    }

    // MARK: - Methods

    func onFirstAppear() {
        Analytics.log(.accountSettingsScreenOpened)
    }

    func archiveAccount() {
        Analytics.log(event: .accountSettingsButtonArchiveAccountConfirmation, params: getAccountAnalyticsParameters())
        archivingState = .archivingInProgress
        archiveAccountTask?.cancel()

        archiveAccountTask = Task { [weak self] in
            guard let self else {
                return
            }

            await account.resolve(using: ArchiveAccountResolver(viewModel: self)).value
        }
    }

    // MARK: - Routing

    func showShouldArchiveDialog() {
        Analytics.log(event: .accountSettingsButtonArchiveAccount, params: getAccountAnalyticsParameters())
        archiveAccountDialogPresented = true
    }

    func handleDialogDismissed() {
        if archivingState == .readyToBeArchived {
            Analytics.log(event: .accountSettingsButtonCancelAccountArchivation, params: getAccountAnalyticsParameters())
        }
    }

    func openEditAccount() {
        Analytics.log(.accountSettingsButtonEdit)
        coordinator?.editAccount()
    }

    func openSupportedNetworks() {
        coordinator?.openSupportedNetworks()
    }

    func openJointAccountMembers() {
        guard let jointAccount = account as? any JointAccountModel else {
            return
        }

        coordinator?.openJointAccountMembers(jointAccount: jointAccount)
    }

    func openManageTokens() {
        Analytics.log(event: .accountSettingsButtonManageTokens, params: getAccountAnalyticsParameters())
        coordinator?.manageTokens()
    }

    // MARK: - Setup

    private func setupView() {
        applySnapshot()
        updateArchiveRow()

        switch account {
        case is any JointAccountModel:
            title = Localization.commonJointAccount
            supportedNetworksHint = makeSupportedNetworksHint()
        default:
            title = Localization.accountDetailsTitle
            managementRowViewModels = makeManagementRowViewModels(membersText: nil)
        }
    }

    private func bind() {
        account.didChangePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in viewModel.applySnapshot() }
            .store(in: &bag)

        if let jointAccount = account as? any JointAccountModel {
            bindJointAccountMembers(of: jointAccount)
        }
    }

    private func bindJointAccountMembers(of jointAccount: any JointAccountModel) {
        jointAccount.didChangePublisher.prepend(())
            .combineLatest(jointAccount.jointAccountMembersService.slotsPublisher)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { $0.makeMembersText(status: jointAccount.status, slots: $1.1) }
            .withWeakCaptureOf(self)
            .map { $0.makeManagementRowViewModels(membersText: $1) }
            .assign(to: &$managementRowViewModels)
    }

    private func applySnapshot() {
        accountName = account.name
        accountIcon = account.icon.erased
    }

    private func updateArchiveRow() {
        archiveRowViewModel = archivingState.map { makeArchiveRowViewModel(state: $0) }
    }

    // MARK: - Factories

    private func makeManagementRowViewModels(membersText: String?) -> [DefaultRowViewModel] {
        var rowViewModels: [DefaultRowViewModel] = []

        if let membersText {
            let jointAccountMembersRowViewModel = DefaultRowViewModel(
                title: Localization.jointAccountMembersTitle,
                detailsType: .text(membersText),
                accessibilityIdentifier: AccountsAccessibilityIdentifiers.accountDetailsJointMembersButton,
                action: { [weak self] in self?.openJointAccountMembers() }
            )

            rowViewModels.append(jointAccountMembersRowViewModel)
        }

        if actions.contains(.manageTokens) {
            let manageTokensRowViewModel = DefaultRowViewModel(
                title: Localization.addTokensTitle,
                accessibilityIdentifier: AccountsAccessibilityIdentifiers.accountDetailsManageTokensButton,
                action: { [weak self] in self?.openManageTokens() }
            )

            rowViewModels.append(manageTokensRowViewModel)
        }

        return rowViewModels
    }

    private func makeArchiveRowViewModel(state: ArchivingState) -> DefaultRowViewModel {
        switch state {
        case .readyToBeArchived:
            DefaultRowViewModel(
                title: Localization.accountDetailsArchive,
                accessibilityIdentifier: AccountsAccessibilityIdentifiers.accountDetailsArchiveButton,
                action: { [weak self] in self?.showShouldArchiveDialog() }
            )
        case .archivingInProgress:
            DefaultRowViewModel(
                title: Localization.accountDetailsArchiving,
                detailsType: .loader,
                accessibilityIdentifier: AccountsAccessibilityIdentifiers.accountDetailsArchiveButton
            )
        }
    }

    private func makeSupportedNetworksHint() -> AttributedString {
        let moreInfo = Localization.jointAccountMoreInfo
        var hint = AttributedString(Localization.jointAccountSettingsNetworksInfo + " " + moreInfo)
        hint.font = Fonts.Regular.caption1
        hint.foregroundColor = Colors.Text.tertiary

        if let range = hint.range(of: moreInfo) {
            hint[range].foregroundColor = Colors.Text.accent
            // Tap on "link" will handle as navigation
            hint[range].link = URL(string: "about:blank")
        }

        return hint
    }

    private func makeMembersText(status: JointAccountStatus, slots: [JointAccountSlot]) -> String? {
        guard slots.isNotEmpty else {
            return nil
        }

        switch status {
        case .pending:
            return Localization.accountDetailsJointMembersProgress(slots.members.count, slots.count)
        case .confirming, .active:
            return Localization.accountDetailsJointMembersCount(slots.count)
        case .cancelled, .unknown:
            return nil
        }
    }

    private func getAccountAnalyticsParameters() -> [Analytics.ParameterKey: String] {
        account.analyticsParameters(with: SingleAccountAnalyticsBuilder())
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
            .error: String(describing: error),
        ])

        alert = AccountArchivationErrorAlertBuilder.makeAlert(for: error)

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

private extension AccountDetailsViewModel {
    struct ArchiveAccountResolver: AccountModelResolving {
        typealias Result = Task<Void, Never>

        let viewModel: AccountDetailsViewModel

        func resolve(accountModel: any CryptoAccountModel) -> Result {
            Task {
                do throws(AccountArchivationError) {
                    try await accountModel.archive()
                    await viewModel.handleAccountArchivingSuccess()
                } catch {
                    await viewModel.handleAccountArchivingFailure(error: error)
                }
            }
        }

        /// TangemPay does not support archiving
        func resolve(accountModel: any TangemPayAccountModel) -> Task<Void, Never> {
            Task {}
        }

        /// Polymarket does not support archiving
        func resolve(accountModel: any PolymarketAccountModel) -> Task<Void, Never> {
            Task {}
        }

        /// Collectibles does not support archiving
        func resolve(accountModel: any CollectiblesAccountModel) -> Task<Void, Never> {
            Task {}
        }
    }
}
