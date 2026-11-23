//
//  LendingWithdrawCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct LendingWithdrawCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: LendingWithdrawCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            ZStack {
                if let amountViewModel = coordinator.amountViewModel {
                    LendingWithdrawAmountView(viewModel: amountViewModel)
                }
            }
            .navigationDestination(for: LendingWithdrawCoordinator.Route.self, destination: destination)
        }
    }

    @ViewBuilder
    private func destination(_ route: LendingWithdrawCoordinator.Route) -> some View {
        switch route {
        case .confirmation:
            if let confirmViewModel = coordinator.confirmViewModel {
                LendingWithdrawConfirmView(viewModel: confirmViewModel)
            }
        }
    }
}
