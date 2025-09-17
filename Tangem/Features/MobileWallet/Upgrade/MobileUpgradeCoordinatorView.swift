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
        NavigationView {
            content
                .navigationLinks(links)
                .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Subviews

private extension MobileUpgradeCoordinatorView {
    var content: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                MobileUpgradeView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    var links: some View {
        NavHolder()
            .navigation(item: $coordinator.onboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .navigationBarHidden(true)
            }
            .emptyNavigationLink()
    }

    var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
    }
}
