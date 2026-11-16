//
//  LendingPositionCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct LendingPositionCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: LendingPositionCoordinator

    var body: some View {
        ZStack {
            if let positionViewModel = coordinator.positionViewModel {
                LendingPositionView(viewModel: positionViewModel)
            }
        }
        .sheet(item: $coordinator.withdrawCoordinator) {
            LendingWithdrawCoordinatorView(coordinator: $0)
        }
        .sheet(item: $coordinator.depositCoordinator) {
            LendingDepositCoordinatorView(coordinator: $0)
        }
        .alert(item: $coordinator.alert) { $0.alert }
    }
}
