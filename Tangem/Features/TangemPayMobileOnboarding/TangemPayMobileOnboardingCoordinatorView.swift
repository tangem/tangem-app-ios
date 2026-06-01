//
//  TangemPayMobileOnboardingCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TangemPayMobileOnboardingCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayMobileOnboardingCoordinator

    var body: some View {
        ZStack {
            NavigationStack {
                if let rootViewModel = coordinator.rootViewModel {
                    TangemPayMobileOnboardingView(viewModel: rootViewModel)
                        .navigationBarHidden(true)
                }
            }

            if let onboardingCoordinator = coordinator.onboardingCoordinator {
                OnboardingCoordinatorView(coordinator: onboardingCoordinator)
                    .background(Colors.Background.primary.ignoresSafeArea())
                    .transition(.opacity)
            }

            if coordinator.isProcessing {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
            }
        }
        .sheet(item: $coordinator.webViewContainerViewModel) {
            WebViewContainer(viewModel: $0)
        }
    }
}
