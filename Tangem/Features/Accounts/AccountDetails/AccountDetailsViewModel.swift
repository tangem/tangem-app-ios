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
import TangemMacro
import struct TangemUIUtils.AlertBinder

final class AccountDetailsViewModel: ObservableObject {
    typealias AccountDetailsRoutable = any BaseAccountDetailsRoutable & CryptoAccountDetailsRoutable & JointAccountDetailsRoutable

    // MARK: - State

    @Published private(set) var navigationTitle: String = ""
    @Published private(set) var accountName: String = ""
    @Published private(set) var accountIcon: AccountModel.Icon = .composite(AccountModelUtils.UI.newAccountIcon())
    @Published private(set) var accountSubtitle: AccountSubtitle = .nameLabel
    @Published private(set) var additionalAccountInfo: [AdditionalAccountInfo] = []
    @Published private(set) var actions: [Action] = []
    @Published private(set) var managementFooter: AttributedString?
    @Published private(set) var archivingState: ArchivingState?
    @Published var alert: AlertBinder?
    @Published var archiveAccountDialogPresented = false

    var accountIconViewData: AccountIconView.ViewData {
        AccountModelUtils.UI.iconViewData(icon: accountIcon, accountName: accountName)
    }

    var canBeEdited: Bool {
        actions.contains(where: \.isEdit)
    }

    var managementActions: [Action] {
        actions.filter { action in
            switch action {
            case .jointMembers, .manageTokens: true
            case .edit, .archive: false
            }
        }
    }

    // MARK: - Dependencies

    private let account: any BaseAccountModel
    private let accountModelsManager: AccountModelsManager
    private weak var coordinator: AccountDetailsRoutable?

    // MARK: - Internal state

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

        let builder = AccountDetailsBuilder(router: coordinator)
        apply(content: account.resolve(using: AccountDetailsViewContentResolver(builder: builder)))
        bind(builder: builder)
    }

    deinit {
        archiveAccountTask?.cancel()
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

    func onActionTap(_ action: Action) {
        switch action {
        case .edit:
            openEditAccount()
        case .archive:
            showShouldArchiveDialog()
        case .jointMembers(_, let action):
            action()
        case .manageTokens:
            openManageTokens()
        }
    }

    func onAdditionalAccountInfoTap(_ info: AdditionalAccountInfo) {
        switch info {
        case .jointSignaturesCount(_, _, let action):
            action()
        }
    }

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

    func openManageTokens() {
        Analytics.log(event: .accountSettingsButtonManageTokens, params: getAccountAnalyticsParameters())
        coordinator?.manageTokens()
    }

    // MARK: - Setup

    private func bind(builder: AccountDetailsBuilder) {
        account
            .resolve(using: AccountDetailsViewContentPublisherResolver(builder: builder))
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.apply(content: $1) }
            .store(in: &bag)
    }

    private func apply(content: Content) {
        navigationTitle = content.navigationTitle
        accountName = content.name
        accountIcon = content.icon
        accountSubtitle = content.accountSubtitle
        additionalAccountInfo = content.additionalAccountInfo
        actions = content.actions
        managementFooter = content.managementFooter
        updateArchivingState()
    }

    private func updateArchivingState() {
        guard archivingState != .archivingInProgress else {
            return
        }

        archivingState = actions.contains(where: \.isArchive) ? .readyToBeArchived : nil
    }

    private func getAccountAnalyticsParameters() -> [Analytics.ParameterKey: String] {
        account.analyticsParameters(with: SingleAccountAnalyticsBuilder())
    }

    @MainActor
    private func handleAccountArchivingSuccess() {
        Analytics.log(.accountSettingsAccountArchived)
        coordinator?.close()

        let snackbar = TangemSnackbar(title: Localization.accountArchiveSuccessMessage)
            .icon(DesignSystem.Icons.Success.regular20)
            .iconColor(DesignSystem.Color.iconAccentBlue)
        LegacyToast(view: snackbar).present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
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

// MARK: - Content

extension AccountDetailsViewModel {
    struct Content {
        let navigationTitle: String
        let name: String
        let icon: AccountModel.Icon
        let accountSubtitle: AccountSubtitle
        let additionalAccountInfo: [AdditionalAccountInfo]
        let actions: [Action]
        let managementFooter: AttributedString?
    }

    enum AccountSubtitle {
        case nameLabel
        case membersCount(Int)
    }

    enum AdditionalAccountInfo {
        case jointSignaturesCount(signersCount: Int, membersCount: Int, action: () -> Void)
    }

    @CaseFlagable
    enum Action {
        case edit
        case archive
        case jointMembers(value: String?, action: () -> Void)
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

// MARK: - Constants

private extension AccountDetailsViewModel {
    enum Constants {
        static let toastTopPadding: CGFloat = 14
    }
}

// MARK: - ArchiveAccountResolver

private extension AccountDetailsViewModel {
    struct ArchiveAccountResolver: AccountModelResolving {
        typealias Result = Task<Void, Never>

        let viewModel: AccountDetailsViewModel

        func resolve(accountModel: any StandardCryptoAccountModel) -> Result {
            archive(accountModel)
        }

        func resolve(accountModel: any JointAccountModel) -> Result {
            archive(accountModel)
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

        private func archive(_ accountModel: some CryptoAccountModel) -> Result {
            Task {
                do throws(AccountArchivationError) {
                    try await accountModel.archive()
                    await viewModel.handleAccountArchivingSuccess()
                } catch {
                    await viewModel.handleAccountArchivingFailure(error: error)
                }
            }
        }
    }
}

// MARK: - AccountDetailsViewContentResolver

private extension AccountDetailsViewModel {
    struct AccountDetailsViewContentResolver: AccountModelResolving {
        let builder: AccountDetailsBuilder

        func resolve(accountModel: any StandardCryptoAccountModel) -> Content {
            builder.makeContent(standardAccount: accountModel)
        }

        func resolve(accountModel: any JointAccountModel) -> Content {
            builder.makeContent(jointAccount: accountModel, slots: [])
        }

        func resolve(accountModel: any TangemPayAccountModel) -> Content {
            builder.makeContent(accountWithoutActions: accountModel)
        }

        func resolve(accountModel: any PolymarketAccountModel) -> Content {
            builder.makeContent(accountWithoutActions: accountModel)
        }

        func resolve(accountModel: any CollectiblesAccountModel) -> Content {
            builder.makeContent(accountWithoutActions: accountModel)
        }
    }
}

// MARK: - AccountDetailsViewContentPublisherResolver

private extension AccountDetailsViewModel {
    struct AccountDetailsViewContentPublisherResolver: AccountModelResolving {
        typealias Result = AnyPublisher<Content, Never>

        let builder: AccountDetailsBuilder

        func resolve(accountModel: any StandardCryptoAccountModel) -> Result {
            accountModel.didChangePublisher
                .prepend(())
                .map { builder.makeContent(standardAccount: accountModel) }
                .eraseToAnyPublisher()
        }

        func resolve(accountModel: any JointAccountModel) -> Result {
            accountModel.didChangePublisher
                .prepend(())
                .combineLatest(accountModel.jointAccountMembersService.slotsPublisher)
                .map { _, slots in builder.makeContent(jointAccount: accountModel, slots: slots) }
                .eraseToAnyPublisher()
        }

        func resolve(accountModel: any TangemPayAccountModel) -> Result {
            makeContentWithoutActionsPublisher(account: accountModel)
        }

        func resolve(accountModel: any PolymarketAccountModel) -> Result {
            makeContentWithoutActionsPublisher(account: accountModel)
        }

        func resolve(accountModel: any CollectiblesAccountModel) -> Result {
            makeContentWithoutActionsPublisher(account: accountModel)
        }

        private func makeContentWithoutActionsPublisher(account: any BaseAccountModel) -> Result {
            account.didChangePublisher
                .prepend(())
                .map { builder.makeContent(accountWithoutActions: account) }
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - AccountDetailsBuilder

private extension AccountDetailsViewModel {
    struct AccountDetailsBuilder {
        private weak var router: AccountDetailsRoutable?

        init(router: AccountDetailsRoutable) {
            self.router = router
        }

        func makeContent(standardAccount: any StandardCryptoAccountModel) -> Content {
            Content(
                navigationTitle: Localization.accountDetailsTitle,
                name: standardAccount.name,
                icon: standardAccount.icon.erased,
                accountSubtitle: .nameLabel,
                additionalAccountInfo: [],
                actions: [
                    .edit,
                    standardAccount.isMainAccount ? nil : .archive,
                    .manageTokens,
                ].compactMap { $0 },
                managementFooter: nil
            )
        }

        func makeContent(jointAccount: any JointAccountModel, slots: [JointAccountSlot]) -> Content {
            let policy = jointAccount.policy
            let membersAction = makeMembersAction(jointAccount: jointAccount, slots: slots)
            let signaturesCountInfo = AdditionalAccountInfo.jointSignaturesCount(
                signersCount: policy.signersCount,
                membersCount: policy.membersCount,
                action: { router?.openAboutSignatures(policy: policy) }
            )
            let isActive = jointAccount.jointAccountStatusProvider.status.isActive

            return Content(
                navigationTitle: Localization.commonJointAccount,
                name: jointAccount.name,
                icon: jointAccount.icon.erased,
                accountSubtitle: .membersCount(policy.membersCount),
                additionalAccountInfo: [signaturesCountInfo],
                actions: [membersAction, .archive, isActive ? .manageTokens : nil].compactMap { $0 },
                managementFooter: isActive ? makeSupportedNetworksHint() : nil
            )
        }

        func makeContent(accountWithoutActions account: any BaseAccountModel) -> Content {
            Content(
                navigationTitle: Localization.accountDetailsTitle,
                name: account.name,
                icon: account.icon.erased,
                accountSubtitle: .nameLabel,
                additionalAccountInfo: [],
                actions: [],
                managementFooter: nil
            )
        }

        private func makeMembersAction(jointAccount: any JointAccountModel, slots: [JointAccountSlot]) -> Action? {
            guard slots.isNotEmpty else {
                return nil
            }

            let value: String?

            switch jointAccount.jointAccountStatusProvider.status {
            case .pending:
                value = Localization.accountDetailsJointMembersJoined(slots.members.count, slots.count)
            case .confirming:
                let confirmedCount = slots.members.filter { $0.signature != nil }.count
                value = Localization.accountDetailsJointMembersConfirmed(confirmedCount, slots.count)
            case .active:
                value = nil
            case .untrusted, .cancelled, .unknown:
                return nil
            }

            return .jointMembers(value: value, action: { router?.openJointAccountMembers(jointAccount: jointAccount) })
        }

        private func makeSupportedNetworksHint() -> AttributedString {
            let moreInfo = Localization.jointAccountMoreInfo
            var hint = AttributedString(Localization.accountDetailsJointNetworksInfo + " " + moreInfo)
            hint.foregroundColor = DesignSystem.Color.textSecondary

            if let range = hint.range(of: moreInfo) {
                hint[range].foregroundColor = DesignSystem.Color.textAccentBlue
                // Tap on "link" will handle as navigation
                hint[range].link = URL(string: "about:blank")
            }

            return hint
        }
    }
}
