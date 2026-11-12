//
//  AddWalletCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct AddWalletCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AddWalletCoordinator

    var body: some View {
        NavHolder()
            .navigation(item: $coordinator.onboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .navigationBarHidden(true)
            }
            .navigation(item: $coordinator.socialWalletViewModel) {
                MobileSocialWalletView(viewModel: $0)
            }
            .modal(
                item: $coordinator.sheetViewModel,
                contentLayout: { _ in .intrinsic },
                navigation: AddWalletSheetView.navigation,
                onDismiss: { [weak coordinator] in
                    coordinator?.handleSheetDismiss()
                }
            ) {
                AddWalletSheetView(viewModel: $0)
            }
    }
}

// MARK: - Presentation

extension View {
    func addWalletPresentation(_ coordinator: AddWalletCoordinator?) -> some View {
        background {
            if let coordinator {
                AddWalletCoordinatorView(coordinator: coordinator)
            }
        }
    }
}
