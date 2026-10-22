//
//  TangemPayMobileOnboardingCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayMobileOnboardingCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayMobileOnboardingCoordinator

    var body: some View {
        ZStack {
            if let tangemPayOnboardingCoordinator = coordinator.tangemPayOnboardingCoordinator {
                TangemPayOnboardingCoordinatorView(coordinator: tangemPayOnboardingCoordinator)
                    .transition(.opacity)
            } else {
                NavigationStack {
                    if let rootViewModel = coordinator.rootViewModel {
                        TangemPayMobileOnboardingView(viewModel: rootViewModel)
                    }
                }
                .environment(\.colorScheme, .dark)
                .transition(.opacity)
            }
        }
        .animation(.default, value: coordinator.tangemPayOnboardingCoordinator?.id)
        .sheet(item: $coordinator.webViewContainerViewModel) {
            WebViewContainer(viewModel: $0)
        }
    }
}
