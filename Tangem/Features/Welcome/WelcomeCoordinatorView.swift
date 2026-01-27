//
//  WelcomeCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct WelcomeCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WelcomeCoordinator

    var body: some View {
        NavigationStack {
            content
                .navigationLinks(links)
        }
    }

    private var content: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                WelcomeView(viewModel: rootViewModel)
            }

            sheets

            ZStack { // for transition animation
                if let onboardingCoordinator = coordinator.welcomeOnboardingCoordinator {
                    WelcomeOnboardingCoordinatorView(coordinator: onboardingCoordinator)
                        .transition(.opacity)
                }
            }
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.createWalletSelectorCoordinator) {
                CreateWalletSelectorCoordinatorView(coordinator: $0)
            }
    }

    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.promotionCoordinator) {
                PromotionCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.searchTokensViewModel) {
                WelcomeSearchTokensView(viewModel: $0)
            }
    }
}
