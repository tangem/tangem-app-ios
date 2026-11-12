//
//  AllServicesCoordinatorView.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct AllServicesCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AllServicesCoordinator

    var body: some View {
        NavigationStack {
            ZStack {
                if let viewModel = coordinator.rootViewModel {
                    AllServicesView(viewModel: viewModel)
                        .navigationLinks(links)
                }

                sheets
            }
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.addWalletSelectorCoordinator) {
                AddWalletSelectorCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.referralCoordinator) {
                ReferralCoordinatorView(coordinator: $0)
            }
    }

    private var sheets: some View {
        NavHolder()
            .fullScreenCover(item: $coordinator.accountFormViewModel, onDismiss: coordinator.accountFormDidDismiss) { viewModel in
                NavigationStack {
                    AccountFormView(viewModel: viewModel)
                }
                .softTopScrollEdgeEffect()
            }
            .fullScreenCover(item: $coordinator.jointAccountManagementCoordinator) {
                JointAccountManagementCoordinatorView(coordinator: $0)
                    .softTopScrollEdgeEffect()
            }
            .userWalletSelectorModal(item: $coordinator.walletSelectorViewModel, onDismiss: coordinator.walletSelectorDidDismiss)
    }
}
