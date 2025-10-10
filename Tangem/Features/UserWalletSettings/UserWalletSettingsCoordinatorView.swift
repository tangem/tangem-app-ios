//
//  UserWalletSettingsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct UserWalletSettingsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: UserWalletSettingsCoordinator

    init(coordinator: UserWalletSettingsCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                UserWalletSettingsView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.manageTokensCoordinator) {
                ManageTokensCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.referralCoordinator) {
                ReferralCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.scanCardSettingsCoordinator) {
                ScanCardSettingsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.mobileBackupTypesViewModel) {
                MobileBackupTypesView(viewModel: $0)
            }
            .navigation(item: $coordinator.accountDetailsCoordinator) {
                AccountDetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.archivedAccountsCoordinator) {
                ArchivedAccountsCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.modalOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }
            .sheet(item: $coordinator.mobileUpgradeCoordinator) {
                MobileUpgradeCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
                    .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                        coordinator.modalOnboardingCoordinatorKeeper = value
                    })
            }
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
            .floatingSheetContent(for: TransactionNotificationsModalViewModel.self) {
                TransactionNotificationsModalView(viewModel: $0)
            }
            .floatingSheetContent(for: MobileBackupNeededViewModel.self) {
                MobileBackupNeededView(viewModel: $0)
            }
            .sheet(item: $coordinator.accountFormViewModel) { viewModel in
                NavigationView {
                    AccountFormView(viewModel: viewModel)
                }
                .presentation(onDismissalAttempt: viewModel.onClose)
                .presentationCornerRadiusBackport(24)
            }
    }
}
