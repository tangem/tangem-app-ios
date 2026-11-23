//
//  TangemPayVerifiedCoordinatorView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayVerifiedCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayVerifiedCoordinator

    var body: some View {
        content
            .navigationLinks(links)
    }

    @ViewBuilder
    private var content: some View {
        if let successViewModel = coordinator.successViewModel {
            TangemPayOnboardingSuccessView(viewModel: successViewModel)
        } else if let viewModel = coordinator.verifiedViewModel {
            TangemPayVerifiedView(viewModel: viewModel)
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.selectPlanCoordinator) {
                TangemPaySelectPlanCoordinatorView(coordinator: $0)
            }
    }
}
