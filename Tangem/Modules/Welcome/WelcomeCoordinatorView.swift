//
//  WelcomeCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct WelcomeCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WelcomeCoordinator

    var body: some View {
        NavigationView {
            ZStack {
                if let welcomeModel = coordinator.welcomeViewModel {
                    WelcomeView(viewModel: welcomeModel)
                        .navigationLinks(links)
                }

                sheets
            }
        }
        .navigationViewStyle(.stack)
        .accentColor(Colors.Text.primary1)
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.mainCoordinator) {
                MainCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.pushedOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.shopCoordinator) {
                ShopCoordinatorView(coordinator: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.tokenListCoordinator) {
                TokenListCoordinatorView(coordinator: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.disclaimerViewModel) {
                DisclaimerView(viewModel: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
    }
}
