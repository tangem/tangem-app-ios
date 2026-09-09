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
            NavigationStack(path: $coordinator.path) {
                ZStack {
                    if let rootViewModel = coordinator.rootViewModel {
                        WithdrawHubView(viewModel: rootViewModel)
                    }
                }
                .navigationDestination(
                    for: TangemPayOfframpCoordinator.Route.self,
                    destination: destination
                )
            }

            sheets
        }
    }

    @ViewBuilder
    private func destination(_ route: TangemPayOfframpCoordinator.Route) -> some View {
        switch route {
        case .recentRecipients:
            if let store = coordinator.recentRecipientsStore {
                let viewModel = RecentRecipientsViewModel(
                    recentRecipientsStore: store,
                    output: { [weak coordinator] bankAccountId in
                        coordinator?.startWizard(recipient: .saved(bankAccountId: bankAccountId))
                    }
                )
                RecentRecipientsView(viewModel: viewModel)
            }

        case .transferInput:
            if let viewModel = coordinator.transferInputViewModel {
                TransferInputView(viewModel: viewModel)
            }
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
