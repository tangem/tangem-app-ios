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
        NavigationStack {
            if let rootViewModel = coordinator.rootViewModel {
                TangemPayMobileOnboardingView(viewModel: rootViewModel)
                    .navigationBarHidden(true)
            }
        }
        .sheet(item: $coordinator.webViewContainerViewModel) {
            WebViewContainer(viewModel: $0)
        }
    }
}
