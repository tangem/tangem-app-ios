//
//  MobileCreateWalletCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MobileCreateWalletCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: MobileCreateWalletCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.rootViewModel {
                MobileCreateWalletView(viewModel: viewModel)
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
    }
}
