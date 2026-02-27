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
        NavigationContainer(root: content, router: coordinator.navigationRouter)
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
        .navigationLinks(links)
    }

    private var links: some View {
        NavHolder()
            .navigationDestination(for: CreateWalletSelectorCoordinator.self) {
                CreateWalletSelectorCoordinatorView(coordinator: $0)
            }
            .navigationDestination(for: OnboardingCoordinator.self) {
                OnboardingCoordinatorView(coordinator: $0)
                    .navigationBarHidden(true)
            }
            .navigationDestination(for: MobileCreateWalletCoordinator.self) {
                MobileCreateWalletCoordinatorView(coordinator: $0)
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
