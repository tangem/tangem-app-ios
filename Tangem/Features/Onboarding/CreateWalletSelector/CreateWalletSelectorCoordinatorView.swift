//
//  CreateWalletSelectorCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct CreateWalletSelectorCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: CreateWalletSelectorCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                CreateWalletSelectorView(viewModel: viewModel)
                    .navigationBarHidden(true)
                    .navigationLinks(links)
            }

            if let viewModel = coordinator.rootPromoViewModel {
                CreateWalletSelectorPromoView(viewModel: viewModel)
                    .navigationBarHidden(true)
                    .navigationLinks(links)
            }
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.onboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
                    .navigationBarHidden(true)
            }
            .navigation(item: $coordinator.mobileCreateWalletCoordinator) {
                MobileCreateWalletCoordinatorView(coordinator: $0)
            }
    }
}
