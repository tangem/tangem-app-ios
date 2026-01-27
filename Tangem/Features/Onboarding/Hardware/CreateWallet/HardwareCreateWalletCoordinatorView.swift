//
//  HardwareCreateWalletCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct HardwareCreateWalletCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: HardwareCreateWalletCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                HardwareCreateWalletView(viewModel: viewModel)
                    .navigationLinks(links)
            }
        }
    }
}

// MARK: - Subviews

private extension HardwareCreateWalletCoordinatorView {
    var links: some View {
        NavHolder()
            .navigation(item: $coordinator.onboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .navigationBarHidden(true)
            }
    }
}
