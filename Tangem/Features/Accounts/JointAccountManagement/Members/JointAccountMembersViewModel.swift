//
//  JointAccountMembersViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import SwiftUI
import TangemAccounts
import TangemFoundation
import TangemLocalization
import TangemUI
import struct TangemUIUtils.AlertBinder

final class JointAccountMembersViewModel: ObservableObject {
    @Published private(set) var title: Title?
    @Published private(set) var slots: [JointAccountMembersViewSlotViewModel] = []
    @Published private(set) var footer: String?
    @Published private(set) var actions: [Action] = []
    @Published private(set) var isActivating = false
    @Published var alert: AlertBinder?

    let summary: Summary
    let signingActionButtonType: SigningActionButtonViewType

    private let jointAccount: any JointAccountModel
    private let contentProvider: any JointAccountMembersViewModelContentProvider
    private weak var coordinator: JointAccountMembersRoutable?

    private var frequentUpdatesSubscription: AnyCancellable?

    init(
        jointAccount: any JointAccountModel,
        contentProvider: any JointAccountMembersViewModelContentProvider,
        userWalletConfig: UserWalletConfig,
        coordinator: JointAccountMembersRoutable
    ) {
        self.jointAccount = jointAccount
        self.contentProvider = contentProvider
        self.coordinator = coordinator

        signingActionButtonType = SigningActionButtonViewTypeBuilder().build(config: userWalletConfig)
        summary = Summary(jointAccount: jointAccount)

        bind()
    }

    func onWillAppear() {
        frequentUpdatesSubscription = jointAccount.jointAccountMembersService.requestFrequentUpdates()
    }

    func onWillDisappear() {
        frequentUpdatesSubscription = nil
    }

    func onApprovalsInfoTap() {
        coordinator?.openAboutSignatures(policy: jointAccount.policy)
    }

    @MainActor
    func onActionTap(_ action: Action) {
        switch action {
        case .confirmSharedAddress(let isEnabled):
            guard isEnabled, !isActivating else {
                return
            }

            isActivating = true

            runTask(in: self) { viewModel in
                await viewModel.performActivation()
            }
        }
    }

    func onCloseTap() {
        coordinator?.closeMembers()
    }
}

// MARK: - Private

private extension JointAccountMembersViewModel {
    func bind() {
        contentProvider.titlePublisher
            .eraseToOptional()
            .assign(to: &$title)

        contentProvider.slotsPublisher
            .assign(to: &$slots)

        contentProvider.footerPublisher
            .assign(to: &$footer)

        contentProvider.actionsPublisher
            .assign(to: &$actions)
    }

    @MainActor
    func performActivation() async {
        defer { isActivating = false }

        do throws(AccountEditError) {
            try await jointAccount.activate()
        } catch .unknownError(let underlying) where underlying.isCancellationError {
            return
        } catch {
            alert = AccountEditErrorAlertBuilder.makeAlert(for: error)
            return
        }

        coordinator?.closeMembers()

        Toast(view: SuccessToast(text: Localization.jointAccountActivatedSnackbar))
            .present(layout: .top(padding: Constants.toastTopPadding), type: .temporary(interval: Constants.toastInterval))
    }
}

// MARK: - Auxiliary types

extension JointAccountMembersViewModel {
    enum Title: Equatable {
        case header(text: String, subtitle: String?)
        case navigationBar(text: String)
    }

    enum Action: Hashable {
        case confirmSharedAddress(isEnabled: Bool)
    }

    struct Summary {
        let iconViewData: AccountIconView.ViewData
        let name: String
        let membersCount: String
        let requiredApprovals: String
    }
}

private extension JointAccountMembersViewModel.Summary {
    init(jointAccount: any JointAccountModel) {
        let policy = jointAccount.policy

        self.init(
            iconViewData: AccountModelUtils.UI.iconViewData(accountModel: jointAccount),
            name: jointAccount.name,
            membersCount: Localization.jointAccountMembersCount(policy.membersCount),
            requiredApprovals: Localization.jointAccountInviteMembersApprovalsValue(policy.signersCount, policy.membersCount)
        )
    }
}

// MARK: - Constants

private extension JointAccountMembersViewModel {
    enum Constants {
        static let toastTopPadding: CGFloat = 24
        static let toastInterval: TimeInterval = 4
    }
}
