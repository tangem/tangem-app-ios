//
//  JointAccountManagementCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct JointAccountManagementCoordinatorView: View {
    @ObservedObject var coordinator: JointAccountManagementCoordinator

    var dismissStyle: JointAccountInviteMembersView.DismissStyle = .close

    var body: some View {
        switch dismissStyle {
        case .close:
            NavigationStack(path: $coordinator.path) {
                root
                    // Attached outside of the root switch so that the destination is registered before any step gets pushed
                    .navigationDestination(for: JointAccountManagementCoordinator.Step.self) { destination(for: $0) }
            }
        case .back:
            root
        }
    }

    private var root: some View {
        ZStack {
            switch coordinator.root {
            case .onboarding(let viewModel, _):
                JointAccountOnboardingView(viewModel: viewModel)
            case .inviteMembers(let viewModel):
                JointAccountInviteMembersView(viewModel: viewModel, dismissStyle: dismissStyle)
            case nil:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func destination(for step: JointAccountManagementCoordinator.Step) -> some View {
        switch step {
        case .accountForm(let viewModel):
            AccountFormView(viewModel: viewModel)
        case .membersCount(let viewModel):
            JointAccountMembersCountView(viewModel: viewModel)
        case .memberName(let viewModel):
            JointAccountMemberNameView(viewModel: viewModel)
        case .inviteMembers(let viewModel):
            JointAccountInviteMembersView(viewModel: viewModel, dismissStyle: .close)
        }
    }
}
