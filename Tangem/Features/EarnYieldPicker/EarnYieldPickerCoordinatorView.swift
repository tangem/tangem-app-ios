//
//  EarnYieldPickerCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct EarnYieldPickerCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: EarnYieldPickerCoordinator

    var body: some View {
        NavigationStack {
            if let viewModel = coordinator.pickerViewModel {
                EarnYieldPickerView(viewModel: viewModel)
            }
        }
        .sheet(item: $coordinator.lendingDepositCoordinator) {
            LendingDepositCoordinatorView(coordinator: $0)
        }
        .alert(item: $coordinator.alert) { $0.alert }
        .modal(
            item: $coordinator.getTokenSheet,
            contentLayout: { _ in .intrinsic },
            navigation: { .title($0.title) }
        ) {
            EarnGetTokenSheetView(viewModel: $0)
        }
    }
}
