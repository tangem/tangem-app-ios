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
    // MARK: - Navigation actions

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var root: Root?

    /// Steps pushed on top of the root of the flow's navigation stack.
    @Published var path: [Step] = []

    // MARK: - Child view models

    @Published var aboutSignaturesViewModel: JointAccountAboutSignaturesViewModel?
    @Published var memberDetailsViewModel: JointAccountMemberDetailsViewModel?

    private var isCreationWalletFixed = false

    init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        switch options {
        case .creation(let creationHelper, let isWalletFixed):
            isCreationWalletFixed = isWalletFixed
            root = .onboarding(JointAccountOnboardingViewModel(creationHelper: creationHelper, coordinator: self))

        case .members(let jointAccount, let userWalletConfig):
            root = .members(makeMembersViewModel(jointAccount: jointAccount, userWalletConfig: userWalletConfig))
        }
    }
}

// MARK: - Options

extension JointAccountManagementCoordinator {
    enum Options {
        case creation(JointAccountCreationHelper, isWalletFixed: Bool)
        case members(jointAccount: any JointAccountModel, userWalletConfig: UserWalletConfig)
    }
}

// MARK: - Root

extension JointAccountManagementCoordinator {
    enum Root {
        case onboarding(JointAccountOnboardingViewModel)
        case members(JointAccountMembersViewModel)
    }
}

// MARK: - Steps

extension JointAccountManagementCoordinator {
    enum Step {
        case accountForm(viewModel: AccountFormViewModel)
        case membersCount(viewModel: JointAccountMembersCountViewModel)
        case memberName(viewModel: JointAccountMemberNameViewModel)
        case members(viewModel: JointAccountMembersViewModel)
    }
}

/// The steps are identified by their view models, which live for as long as the step stays in the stack.
extension JointAccountManagementCoordinator.Step: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.accountForm(let lhs), .accountForm(let rhs)): lhs === rhs
        case (.membersCount(let lhs), .membersCount(let rhs)): lhs === rhs
        case (.memberName(let lhs), .memberName(let rhs)): lhs === rhs
        case (.members(let lhs), .members(let rhs)): lhs === rhs
        default: false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .accountForm(let viewModel): hasher.combine(ObjectIdentifier(viewModel))
        case .membersCount(let viewModel): hasher.combine(ObjectIdentifier(viewModel))
        case .memberName(let viewModel): hasher.combine(ObjectIdentifier(viewModel))
        case .members(let viewModel): hasher.combine(ObjectIdentifier(viewModel))
        }
    }
}

// MARK: - JointAccountOnboardingRoutable

extension JointAccountManagementCoordinator: JointAccountOnboardingRoutable {
    func closeOnboarding() {
        dismiss()
    }

    func continueOnboarding(creationHelper: JointAccountCreationHelper) {
        // A single wallet leaves nothing to choose, so the form shows no wallet row at all
        let walletSelection: AccountFormWalletSelection = if selectableUserWalletModels.count <= 1 {
            .hidden
        } else if isCreationWalletFixed {
            .fixed
        } else {
            .selectable
        }

        let creator = JointAccountFormViewCreator(creationHelper: creationHelper, walletSelection: walletSelection)

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
    func openInviteMembers(jointAccount: any JointAccountModel, userWalletConfig: UserWalletConfig) {
        let viewModel = makeMembersViewModel(jointAccount: jointAccount, userWalletConfig: userWalletConfig)
        path.append(.members(viewModel: viewModel))
    }
}

// MARK: - JointAccountAboutSignaturesRoutable

extension JointAccountManagementCoordinator: JointAccountAboutSignaturesRoutable {
    func closeAboutSignatures() {
        aboutSignaturesViewModel = nil
    }
}

// MARK: - JointAccountMembersRoutable

extension JointAccountManagementCoordinator: JointAccountMembersRoutable {
    func closeMembers() {
        dismiss()
    }

    func openAboutSignatures(policy: JointAccountPolicy) {
        aboutSignaturesViewModel = JointAccountAboutSignaturesViewModel(policy: policy, coordinator: self)
    }
}

// MARK: - JointAccountMembersViewSlotRoutable

extension JointAccountManagementCoordinator: JointAccountMembersViewSlotRoutable {
    func shareInvite(url: URL, accountName: String) {
        let itemSource = JointAccountInviteActivityItemSource(url: url, accountName: accountName)

        AppPresenter.shared.show(UIActivityViewController(activityItems: [itemSource], applicationActivities: nil))
    }

    func openMemberDetails(name: String, address: String, accentColor: Color) {
        memberDetailsViewModel = JointAccountMemberDetailsViewModel(
            name: name,
            address: address,
            accentColor: accentColor,
            coordinator: self
        )
    }
}

// MARK: - JointAccountMemberDetailsRoutable

extension JointAccountManagementCoordinator: JointAccountMemberDetailsRoutable {
    func closeMemberDetails() {
        memberDetailsViewModel = nil
    }
}

// MARK: - Members

private extension JointAccountManagementCoordinator {
    func makeMembersViewModel(jointAccount: any JointAccountModel, userWalletConfig: UserWalletConfig) -> JointAccountMembersViewModel {
        JointAccountMembersViewModel(
            jointAccount: jointAccount,
            contentProvider: CommonJointAccountMembersViewModelContentProvider(jointAccount: jointAccount, routable: self),
            userWalletConfig: userWalletConfig,
            coordinator: self
        )
    }
}

// MARK: - Wallet selection

private extension JointAccountManagementCoordinator {
    /// The wallets a joint account can be created in — the ones that offer to add an account at all and still have
    /// room for a joint one.
    var selectableUserWalletModels: [any UserWalletModel] {
        UserWalletModelsProvider.accountCreationCandidates(for: .joint)
    }
}
