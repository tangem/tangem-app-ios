//
//  WelcomeCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI

struct WelcomeCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WelcomeCoordinator

    var body: some View {
        NavigationView {
            content
                .navigationLinks(links)
                .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
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

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.createWalletSelectorCoordinator) {
                CreateWalletSelectorCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.importWalletSelectorCoordinator) {
                ImportWalletSelectorCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.promotionCoordinator) {
                PromotionCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.searchTokensViewModel) {
                WelcomeSearchTokensView(viewModel: $0)
            }
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
    }
}
