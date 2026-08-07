//
//  JointAccountManagementCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class JointAccountManagementCoordinator: CoordinatorObject {
    // MARK: - Navigation actions

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root view model

    @Published private(set) var rootViewModel: JointAccountOnboardingViewModel?

    /// Steps pushed on top of the onboarding, which is the root of the flow's navigation stack.
    @Published var path: [Step] = []

    // MARK: - Dependencies

    private var options: Options?

    init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options

        rootViewModel = JointAccountOnboardingViewModel(coordinator: self)
    }
}

// MARK: - Options

extension JointAccountManagementCoordinator {
    struct Options {
        let accountModelsManager: any AccountModelsManager
        let userWalletConfig: UserWalletConfig
    }
}

// MARK: - Steps

extension JointAccountManagementCoordinator {
    enum Step {
        case accountForm(viewModel: AccountFormViewModel)
        case membersCount(viewModel: JointAccountMembersCountViewModel)
    }
}

/// The steps are identified by their view models, which live for as long as the step stays in the stack.
extension JointAccountManagementCoordinator.Step: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.accountForm(let lhs), .accountForm(let rhs)): lhs === rhs
        case (.membersCount(let lhs), .membersCount(let rhs)): lhs === rhs
        default: false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .accountForm(let viewModel): hasher.combine(ObjectIdentifier(viewModel))
        case .membersCount(let viewModel): hasher.combine(ObjectIdentifier(viewModel))
        }
    }
}

// MARK: - JointAccountOnboardingRoutable

extension JointAccountManagementCoordinator: JointAccountOnboardingRoutable {
    func closeOnboarding() {
        dismiss()
    }

    func continueOnboarding() {
        guard let options else {
            return
        }

        let creationHelper = JointAccountCreationHelper()
        let creator = JointAccountFormViewCreator(
            accountModelsManager: options.accountModelsManager,
            creationHelper: creationHelper
        )

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

    func continueMembersCount() {
        // [REDACTED_TODO_COMMENT]
    }
}
