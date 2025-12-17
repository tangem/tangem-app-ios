//
//  MobileUpgradeCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MobileUpgradeCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MobileUpgradeCoordinator

    var body: some View {
        NavigationStack {
            content
                .navigationLinks(links)
        }
    }
}

// MARK: - Subviews

private extension MobileUpgradeCoordinatorView {
    var content: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                MobileUpgradeView(viewModel: rootViewModel)
            }
        }
    }

    var links: some View {
        NavHolder()
            .navigation(item: $coordinator.onboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .navigationBarHidden(true)
            }
    }
}
