//
//  TangemPayCurrentPlanCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayCurrentPlanCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayCurrentPlanCoordinator

    var body: some View {
        if let viewModel = coordinator.currentPlanViewModel {
            TangemPayCurrentPlanView(viewModel: viewModel)
                .navigationLinks(links)
                .sheet(item: $coordinator.termsAndLimitsViewModel) {
                    WebViewContainer(viewModel: $0)
                }
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.selectPlanCoordinator) {
                TangemPaySelectPlanCoordinatorView(coordinator: $0)
            }
    }
}
