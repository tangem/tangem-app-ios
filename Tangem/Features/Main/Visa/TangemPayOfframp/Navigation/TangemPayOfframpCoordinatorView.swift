//
//  TangemPayOfframpCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayOfframpCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayOfframpCoordinator

    var body: some View {
        ZStack {
            NavigationStack {
                if let rootViewModel = coordinator.rootViewModel {
                    WithdrawHubView(viewModel: rootViewModel)
                }
            }

            sheets
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .floatingSheetContent(for: TangemPayWithdrawNoteSheetViewModel.self) {
                TangemPayPopupView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayWithdrawInProgressSheetViewModel.self) {
                TangemPayWithdrawInProgressSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayNoDepositAddressSheetViewModel.self) {
                TangemPayNoDepositAddressSheetView(viewModel: $0)
            }
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
    }
}
