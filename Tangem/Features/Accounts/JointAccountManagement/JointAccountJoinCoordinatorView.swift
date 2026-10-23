//
//  JointAccountJoinCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

struct JointAccountJoinCoordinatorView: View {
    @ObservedObject var coordinator: JointAccountJoinCoordinator

    var body: some View {
        if let jointAccountManagementCoordinator = coordinator.jointAccountManagementCoordinator {
            JointAccountManagementCoordinatorView(coordinator: jointAccountManagementCoordinator)
        } else {
            joinFlow
        }
    }

    private var joinFlow: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack {
                DesignSystem.Color.bgPrimary.ignoresSafeArea()

                if let rootViewModel = coordinator.rootViewModel {
                    JointAccountJoinView(viewModel: rootViewModel)
                }
            }
            // Attached outside of the `if let` so that the destination is registered before any step gets pushed
            .navigationDestination(for: JointAccountJoinCoordinator.Step.self) { destination(for: $0) }
        }
        .modal(
            item: $coordinator.walletSelectorViewModel,
            contentLayout: .intrinsic,
            navigation: .title(Localization.commonChooseWallet)
        ) {
            AccountSelectorView(viewModel: $0, style: .modal)
        }
        .modal(
            item: $coordinator.memberDetailsViewModel,
            contentLayout: .intrinsic,
            navigation: .closeButton()
        ) {
            JointAccountMemberDetailsView(viewModel: $0)
        }
    }

    @ViewBuilder
    private func destination(for step: JointAccountJoinCoordinator.Step) -> some View {
        switch step {
        case .memberName(let viewModel):
            JointAccountMemberNameView(viewModel: viewModel)
        }
    }
}
