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
                        .addWalletPresentation(coordinator.addWalletCoordinator)
                }

                sheets
            }
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.referralCoordinator) {
                ReferralCoordinatorView(coordinator: $0)
            }
    }

    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.modalOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
                    .softTopScrollEdgeEffect()
            }
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
