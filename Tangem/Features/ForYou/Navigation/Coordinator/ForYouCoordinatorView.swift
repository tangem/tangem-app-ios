//
//  ForYouCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct ForYouCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: ForYouCoordinator

    var body: some View {
        content
            .navigation(item: $coordinator.earnListCoordinator, destination: EarnDetailCoordinatorView.init)
            .navigation(item: $coordinator.portfolioTokenDetailsCoordinator, destination: TokenDetailsCoordinatorView.init)
            .sheet(item: $coordinator.stakingCoordinator) {
                StakingDetailsCoordinatorView(coordinator: $0)
                    .stakingNavigationView()
                    .softTopScrollEdgeEffect()
            }
            .sheet(item: $coordinator.yieldPromoCoordinator) { yieldPromoCoordinator in
                NavigationStack {
                    YieldModulePromoCoordinatorView(coordinator: yieldPromoCoordinator).toolbar {
                        NavigationToolbarButton.close(
                            placement: .topBarLeading,
                            action: yieldPromoCoordinator.dismiss
                        )
                    }
                }
                .softTopScrollEdgeEffect()
            }
            .sheet(item: $coordinator.yieldActiveCoordinator) {
                YieldModuleActiveCoordinatorView(coordinator: $0)
                    .softTopScrollEdgeEffect()
            }
            .sheet(item: $coordinator.addFundsCoordinator) {
                ActionButtonsBuyCoordinatorView(coordinator: $0)
                    .softTopScrollEdgeEffect()
            }
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
                    .softTopScrollEdgeEffect()
            }
            .sheet(item: $coordinator.tokenSummaryViewModel, onDismiss: coordinator.tokenSummaryDidDismiss) {
                TokenSummaryView(viewModel: $0)
                    .presentationDetents([.large])
                    .softTopScrollEdgeEffect()
            }
            .floatingSheetContent(for: ReceiveMainViewModel.self, viewBuilder: ReceiveMainView.init)
    }
}

private extension ForYouCoordinatorView {
    // MARK: - View properties

    var content: some View {
        coordinator.rootViewModel.map {
            ForYouView(
                viewModel: $0,
                onBackButtonAction: coordinator.dismiss
            )
        }
    }
}
