//
//  TangemPayOnboardingCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayOnboardingCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayOnboardingCoordinator

    var body: some View {
        ZStack {
            if let residencyCoordinator = coordinator.residencyCoordinator {
                TangemPayResidencyCoordinatorView(coordinator: residencyCoordinator)
                    .transition(.opacity)
            } else if let rootViewModel = coordinator.rootViewModel {
                TangemPayOnboardingView(viewModel: rootViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.default, value: coordinator.residencyCoordinator?.id)
    }
}
