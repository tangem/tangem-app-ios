//
//  HardwareBackupTypesCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct HardwareBackupTypesCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: HardwareBackupTypesCoordinator

    init(coordinator: HardwareBackupTypesCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                HardwareBackupTypesView(viewModel: rootViewModel)
            }

            sheets
        }
    }
}

// MARK: - Subviews

private extension HardwareBackupTypesCoordinatorView {
    var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.hardwareCreateWalletCoordinator, content: makeHardwareCreateWalletSheetContent)
            .sheet(item: $coordinator.onboardingCoordinator, content: makeOnboardingSheetContent)
            .sheet(item: $coordinator.mobileUpgradeCoordinator, content: makeMobileUpgradeSheetContent)
            .floatingSheetContent(for: MobileBackupToUpgradeNeededViewModel.self) {
                MobileBackupToUpgradeNeededView(viewModel: $0)
            }
    }

    func makeHardwareCreateWalletSheetContent(coordinator: HardwareCreateWalletCoordinator) -> some View {
        NavigationStack {
            HardwareCreateWalletCoordinatorView(coordinator: coordinator)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        CloseTextButton(action: self.coordinator.onHardwareCreateWalletCloseTap)
                    }
                }
        }
        .presentation(modal: true, onDismissalAttempt: coordinator.onDismissalAttempt, onDismissed: nil)
        .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
            self.coordinator.modalKeeper = value
        })
    }

    func makeOnboardingSheetContent(coordinator: OnboardingCoordinator) -> some View {
        OnboardingCoordinatorView(coordinator: coordinator)
            .presentation(modal: true, onDismissalAttempt: coordinator.onDismissalAttempt, onDismissed: nil)
            .onPreferenceChange(ModalSheetPreferenceKey.self, perform: { value in
                self.coordinator.modalKeeper = value
            })
    }

    func makeMobileUpgradeSheetContent(coordinator: MobileUpgradeCoordinator) -> some View {
        MobileUpgradeCoordinatorView(coordinator: coordinator)
            .presentation(modal: true, onDismissalAttempt: coordinator.onDismissalAttempt, onDismissed: nil)
    }
}
