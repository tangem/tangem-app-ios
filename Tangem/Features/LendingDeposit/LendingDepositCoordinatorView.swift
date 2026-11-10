//
//  LendingDepositCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct LendingDepositCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: LendingDepositCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack {
                if let amountViewModel = coordinator.amountViewModel {
                    LendingDepositAmountView(viewModel: amountViewModel)
                }
            }
            .navigationDestination(for: LendingDepositCoordinator.Route.self, destination: destination)
        }
    }

    @ViewBuilder
    private func destination(_ route: LendingDepositCoordinator.Route) -> some View {
        switch route {
        case .confirmation:
            if let confirmViewModel = coordinator.confirmViewModel {
                LendingDepositConfirmView(viewModel: confirmViewModel)
            }
        }
    }
}
