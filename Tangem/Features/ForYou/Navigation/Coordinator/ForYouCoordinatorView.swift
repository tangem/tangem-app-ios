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
            .navigation(item: $coordinator.stakingCoordinator, destination: StakingDetailsCoordinatorView.init)
            .navigation(item: $coordinator.yieldPromoCoordinator, destination: YieldModulePromoCoordinatorView.init)
            .navigation(item: $coordinator.portfolioTokenDetailsCoordinator, destination: TokenDetailsCoordinatorView.init)
            .sheet(item: $coordinator.yieldActiveCoordinator, content: YieldModuleActiveCoordinatorView.init)
            .sheet(item: $coordinator.swapTokenSelectorViewModel, onDismiss: coordinator.runPendingSwapAction) {
                ForYouSwapTokenSelectorView(viewModel: $0)
            }
            .sheet(item: $coordinator.addFundsCoordinator, content: ActionButtonsBuyCoordinatorView.init)
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.tokenSummaryViewModel, onDismiss: coordinator.runPendingSwapAction) {
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
