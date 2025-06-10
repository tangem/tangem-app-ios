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
