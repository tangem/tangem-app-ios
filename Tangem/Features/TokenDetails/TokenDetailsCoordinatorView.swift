//
//  TokenDetailsCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct TokenDetailsCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TokenDetailsCoordinator

    var body: some View {
        ZStack {
            if let viewModel = coordinator.tokenDetailsViewModel {
                TokenDetailsView(viewModel: viewModel)
                    .navigationLinks(links)
            }

            sheets
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.tokenDetailsCoordinator) {
                TokenDetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.stakingDetailsCoordinator) {
                StakingDetailsCoordinatorView(coordinator: $0)
            }
            .navigation(item: $coordinator.yieldModulePromoCoordinator) {
                YieldModulePromoCoordinatorView(coordinator: $0)
            }
            .modifyView { view in
                if coordinator.isRedesign {
                    view.fullScreenCover(item: $coordinator.marketsTokenDetailsCoordinator) { marketsTokenDetailsCoordinator in
                        MarketsTokenDetailsCoordinatorView(coordinator: marketsTokenDetailsCoordinator)
                    }
                } else {
                    view.navigation(item: $coordinator.marketsTokenDetailsCoordinator) { marketsTokenDetailsCoordinator in
                        MarketsTokenDetailsCoordinatorView(coordinator: marketsTokenDetailsCoordinator)
                    }
                }
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }

        NavHolder()
            .sheet(item: $coordinator.yieldModuleActiveCoordinator) {
                YieldModuleActiveCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.pendingExpressTxStatusBottomSheetViewModel) { viewModel in
                PendingExpressTxStatusBottomSheetView(viewModel: viewModel)
            }
            .floatingSheetContent(for: ReceiveMainViewModel.self) {
                ReceiveMainView(viewModel: $0)
            }
            .floatingSheetContent(for: YieldModuleBalanceInfoViewModel.self) {
                YieldModuleBalanceInfoView(viewModel: $0)
            }
            .floatingSheetContent(for: CloreMigrationViewModel.self) {
                CloreMigrationView(viewModel: $0)
            }
            .floatingSheetContent(for: DynamicAddressesUnavailableSheetViewModel.self) {
                DynamicAddressesUnavailableSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: DynamicAddressesDisableSheetViewModel.self) {
                DynamicAddressesDisableSheetView(viewModel: $0)
            }
            .sheet(item: $coordinator.dynamicAddressesEnterViewModel) {
                DynamicAddressesEnterView(viewModel: $0)
            }
    }
}
