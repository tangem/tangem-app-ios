//
//  TangemPayMainCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

struct TangemPayMainCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayMainCoordinator

    var body: some View {
        ZStack {
            if let rootViewModel = coordinator.rootViewModel {
                TangemPayMainView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    @ViewBuilder
    private var links: some View {
        EmptyView()
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .floatingSheetContent(for: ReceiveMainViewModel.self) {
                ReceiveMainView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayNoDepositAddressSheetViewModel.self) {
                TangemPayNoDepositAddressSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayPinCheckViewModel.self) {
                TangemPayPinCheckView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayWithdrawInProgressSheetViewModel.self) {
                TangemPayWithdrawInProgressSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayAddFundsSheetViewModel.self) {
                TangemPayAddFundsSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayFreezeSheetViewModel.self) {
                TangemPayFreezeSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayTransactionDetailsViewModel.self) {
                TangemPayTransactionDetailsView(viewModel: $0)
            }
            .sheet(item: $coordinator.expressCoordinator) {
                ExpressCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.addToApplePayGuideViewModel) {
                TangemPayAddToAppPayGuideView(viewModel: $0)
            }
            .sheet(item: $coordinator.tangemPayPinViewModel) {
                TangemPayPinView(viewModel: $0)
            }
            .sheet(item: $coordinator.termsAndLimitsViewModel) {
                WebViewContainer(viewModel: $0)
            }
            .bottomSheet(
                item: $coordinator.pendingExpressTxStatusBottomSheet,
                backgroundColor: Colors.Background.tertiary
            ) {
                PendingExpressTxStatusBottomSheetView(viewModel: $0)
            }
    }
}
