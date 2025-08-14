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
            if let createViewModel = coordinator.createViewModel {
                CreateWalletSelectorView(viewModel: createViewModel)
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
            .emptyNavigationLink()
    }
}
