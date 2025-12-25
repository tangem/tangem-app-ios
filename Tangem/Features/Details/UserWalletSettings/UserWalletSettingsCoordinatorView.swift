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

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                UserWalletSettingsView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

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
            .navigation(item: $coordinator.mobileBackupTypesCoordinator) {
                MobileBackupTypesCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.accountDetailsCoordinator) {
                AccountDetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.archivedAccountsCoordinator) {
                ArchivedAccountsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.mobileRemoveWalletViewModel) {
                MobileRemoveWalletView(viewModel: $0)
            }
            .onChange(of: coordinator.noActiveCreateOrArchiveAccountFlows) { hasNoFlows in
                if hasNoFlows {
                    coordinator.rootViewModel?.showAccountsPendingAlertIfNeeded()
                }
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
            }
            .sheet(item: $coordinator.mobileUpgradeCoordinator) {
                MobileUpgradeCoordinatorView(coordinator: $0)
                    .presentation(modal: true, onDismissalAttempt: $0.onDismissalAttempt, onDismissed: nil)
            }
            .floatingSheetContent(for: TransactionNotificationsModalViewModel.self) {
                TransactionNotificationsModalView(viewModel: $0)
            }
            .floatingSheetContent(for: MobileBackupNeededViewModel.self) {
                MobileBackupNeededView(viewModel: $0)
            }
            .floatingSheetContent(for: MobileRemoveWalletNotificationViewModel.self) {
                MobileRemoveWalletNotificationView(viewModel: $0)
            }
            .floatingSheetContent(for: MobileBackupToUpgradeNeededViewModel.self) {
                MobileBackupToUpgradeNeededView(viewModel: $0)
            }
            .sheet(
                item: $coordinator.accountFormViewModel,
                onDismiss: {
                    coordinator.accountCreationFlowClosed = true
                }
            ) { viewModel in
                NavigationStack {
                    AccountFormView(viewModel: viewModel)
                }
                .presentation(onDismissalAttempt: viewModel.onClose)
                .presentationCornerRadius(24)
            }
    }
}
