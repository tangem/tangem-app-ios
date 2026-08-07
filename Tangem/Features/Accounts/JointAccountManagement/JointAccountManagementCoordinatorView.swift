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

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack {
                if let rootViewModel = coordinator.rootViewModel {
                    JointAccountOnboardingView(viewModel: rootViewModel)
                }
            }
            // Attached outside of the `if let` so that the destination is registered before any step gets pushed
            .navigationDestination(for: JointAccountManagementCoordinator.Step.self) { destination(for: $0) }
        }
    }

    @ViewBuilder
    private func destination(for step: JointAccountManagementCoordinator.Step) -> some View {
        switch step {
        case .accountForm(let viewModel):
            AccountFormView(viewModel: viewModel)
        case .membersCount(let viewModel):
            JointAccountMembersCountView(viewModel: viewModel)
        }
    }
}
