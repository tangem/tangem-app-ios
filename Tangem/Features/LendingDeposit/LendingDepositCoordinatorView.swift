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
        NavigationStack {
            if let amountViewModel = coordinator.amountViewModel {
                LendingDepositAmountView(viewModel: amountViewModel)
            }
        }
    }
}
