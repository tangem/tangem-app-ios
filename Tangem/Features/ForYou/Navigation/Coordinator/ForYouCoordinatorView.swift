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
            }
            .sheet(item: $coordinator.yieldActiveCoordinator, content: YieldModuleActiveCoordinatorView.init)
            .sheet(item: $coordinator.addFundsCoordinator, content: ActionButtonsBuyCoordinatorView.init)
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.tokenSummaryViewModel, onDismiss: coordinator.tokenSummaryDidDismiss) {
                TokenSummaryView(viewModel: $0)
                    .presentationDetents([.large])
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
