//
//  JointAccountManagementCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

final class JointAccountManagementCoordinator: CoordinatorObject {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // MARK: - Navigation actions

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var root: Root?

    /// Steps pushed on top of the root of the flow's navigation stack.
    @Published var path: [Step] = []

    init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        switch options {
        case .creation(let creationOptions):
            root = .onboarding(JointAccountOnboardingViewModel(coordinator: self), creationOptions)

        case .members(let jointAccount):
            // The account already exists, so the flow opens where the creation flow ends up
            root = .inviteMembers(
                JointAccountInviteMembersViewModel(
                    jointAccount: jointAccount,
                    coordinator: self
                )
            )
        }
    }
}

// MARK: - Options

extension JointAccountManagementCoordinator {
    enum Options {
        case creation(CreationOptions)
        case members(jointAccount: any JointAccountModel)
    }

    struct CreationOptions {
        /// The wallet the flow starts in — the form step lets the user pick another one to create the account in.
        let userWalletModel: any UserWalletModel
    }
}

// MARK: - Root

extension JointAccountManagementCoordinator {
    enum Root {
        /// The options are carried by the step that needs them, so that they cannot outlive the flow they start.
        case onboarding(JointAccountOnboardingViewModel, CreationOptions)
        case inviteMembers(JointAccountInviteMembersViewModel)
    }
}

// MARK: - Steps

extension JointAccountManagementCoordinator {
    enum Step {
        case accountForm(viewModel: AccountFormViewModel)
        case membersCount(viewModel: JointAccountMembersCountViewModel)
        case memberName(viewModel: JointAccountMemberNameViewModel)
        case inviteMembers(viewModel: JointAccountInviteMembersViewModel)
    }
}

/// The steps are identified by their view models, which live for as long as the step stays in the stack.
extension JointAccountManagementCoordinator.Step: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.accountForm(let lhs), .accountForm(let rhs)): lhs === rhs
        case (.membersCount(let lhs), .membersCount(let rhs)): lhs === rhs
        case (.memberName(let lhs), .memberName(let rhs)): lhs === rhs
        case (.inviteMembers(let lhs), .inviteMembers(let rhs)): lhs === rhs
        default: false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .accountForm(let viewModel): hasher.combine(ObjectIdentifier(viewModel))
        case .membersCount(let viewModel): hasher.combine(ObjectIdentifier(viewModel))
        case .memberName(let viewModel): hasher.combine(ObjectIdentifier(viewModel))
        case .inviteMembers(let viewModel): hasher.combine(ObjectIdentifier(viewModel))
        }
    }
}

// MARK: - JointAccountOnboardingRoutable

extension JointAccountManagementCoordinator: JointAccountOnboardingRoutable {
    func closeOnboarding() {
        dismiss()
    }

    func continueOnboarding() {
        guard case .onboarding(_, let creationOptions) = root else {
            return
        }

        let creationHelper = JointAccountCreationHelper(userWalletModel: creationOptions.userWalletModel)

        // A single wallet leaves nothing to choose, so the form shows no wallet row at all
        let onWalletTap: (() -> Void)? = selectableUserWalletModels.count > 1
            ? { [weak self] in self?.openWalletSelection(creationHelper: creationHelper) }
            : nil

        let creator = JointAccountFormViewCreator(creationHelper: creationHelper, onWalletTap: onWalletTap)

        let viewModel = AccountFormViewModel(flowType: .create(creator: creator), coordinator: self)
        path.append(.accountForm(viewModel: viewModel))
    }
}

// MARK: - AccountFormViewModelRoutable

extension JointAccountManagementCoordinator: AccountFormViewModelRoutable {
    func closeAccountForm(outcome: AccountFormOutcome) {
        switch outcome {
        case .completed(.joint(let creationHelper)):
            let viewModel = JointAccountMembersCountViewModel(creationHelper: creationHelper, coordinator: self)
            path.append(.membersCount(viewModel: viewModel))

        case .completed(.crypto):
            assertionFailure("Only the joint account form is presented by this flow")

        case .cancelled:
            // The close button of a step leaves the whole flow, the way back to the previous step is the back button
            dismiss()
        }
    }
}

// MARK: - JointAccountMembersCountRoutable

extension JointAccountManagementCoordinator: JointAccountMembersCountRoutable {
    func closeMembersCount() {
        dismiss()
    }

    func continueMembersCount(creationHelper: JointAccountCreationHelper) {
        let viewModel = JointAccountMemberNameViewModel(
            helper: JointAccountCreationMemberNameHelper(creationHelper: creationHelper, routable: self),
            coordinator: self
        )

        path.append(.memberName(viewModel: viewModel))
    }
}

// MARK: - JointAccountMemberNameRoutable

extension JointAccountManagementCoordinator: JointAccountMemberNameRoutable {
    func closeMemberName() {
        dismiss()
    }
}

// MARK: - JointAccountCreationMemberNameRoutable

extension JointAccountManagementCoordinator: JointAccountCreationMemberNameRoutable {
    func openInviteMembers(jointAccount: any JointAccountModel) {
        let viewModel = JointAccountInviteMembersViewModel(
            jointAccount: jointAccount,
            coordinator: self
        )

        path.append(.inviteMembers(viewModel: viewModel))
    }
}

// MARK: - JointAccountInviteSafetyRoutable

extension JointAccountManagementCoordinator: JointAccountInviteSafetyRoutable {
    func closeInviteSafety() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - JointAccountInviteMembersRoutable

extension JointAccountManagementCoordinator: JointAccountInviteMembersRoutable {
    func closeInviteMembers() {
        dismiss()
    }

    func shareInvite(url: URL) {
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url.absoluteString], applicationActivities: nil))
    }

    func openInviteSafety() {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: JointAccountInviteSafetyViewModel(coordinator: self))
        }
    }

    func openMemberDetails(name: String, address: String, accentColor: Color) {
        let viewModel = JointAccountMemberDetailsViewModel(
            name: name,
            address: address,
            accentColor: accentColor,
            coordinator: self
        )

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openActivationConfirmation(onConfirm: @escaping () -> Void) {
        Task { @MainActor in
            floatingSheetPresenter.enqueue(
                sheet: JointAccountActivationConfirmationViewModel(onConfirm: onConfirm, coordinator: self)
            )
        }
    }
}

// MARK: - JointAccountActivationConfirmationRoutable

extension JointAccountManagementCoordinator: JointAccountActivationConfirmationRoutable {
    func confirmActivation(_ activate: @escaping () -> Void) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            activate()
        }
    }

    func cancelActivation() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - JointAccountMemberDetailsRoutable

extension JointAccountManagementCoordinator: JointAccountMemberDetailsRoutable {
    func closeMemberDetails() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - Wallet selection

private extension JointAccountManagementCoordinator {
    /// The wallets a joint account can be created in — the same condition that decides whether a wallet offers
    /// to add an account at all.
    var selectableUserWalletModels: [any UserWalletModel] {
        UserWalletModelsProvider
            .available(from: userWalletRepository.models)
            .filter(\.accountModelsManager.canAddCryptoAccounts)
    }

    func openWalletSelection(creationHelper: JointAccountCreationHelper) {
        Task { @MainActor in
            let accountSelectorViewModel = AccountSelectorViewModel(
                userWalletModels: selectableUserWalletModels,
                preferredDisplayMode: .wallets
            ) { [weak self] selectedCell in
                creationHelper.update(userWalletModel: selectedCell.userWalletModel)
                self?.floatingSheetPresenter.removeActiveSheet()
            }

            floatingSheetPresenter.enqueue(
                sheet: JointAccountWalletSelectionViewModel(
                    accountSelectorViewModel: accountSelectorViewModel,
                    close: floatingSheetPresenter.removeActiveSheet
                )
            )
        }
    }
}
