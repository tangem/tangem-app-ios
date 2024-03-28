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
        ZStack {
            content
            sheets
        }
        .navigationBarHidden(coordinator.mainCoordinator == nil)
        .animation(.default, value: coordinator.mainCoordinator == nil)
    }

    @ViewBuilder
    private var content: some View {
        if let mainCoordinator = coordinator.mainCoordinator {
            MainCoordinatorView(coordinator: mainCoordinator)
        } else if let welcomeViewModel = coordinator.welcomeViewModel {
            WelcomeView(viewModel: welcomeViewModel)
                .navigationLinks(links)
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.pushedOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.promotionCoordinator) {
                PromotionCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.legacyTokenListCoordinator) {
                LegacyTokenListCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
    }
}
