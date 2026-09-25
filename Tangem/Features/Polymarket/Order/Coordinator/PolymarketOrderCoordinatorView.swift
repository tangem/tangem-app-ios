//
//  PolymarketOrderCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct PolymarketOrderCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketOrderCoordinator

    var body: some View {
        coordinator.viewModel.map { viewModel in
            PolymarketOrderView(viewModel: viewModel)
                .toolbar(.hidden, for: .navigationBar)
                .background(FeedPopGestureEnabler())
                .navigationLinks(links)
                .sheet(item: $coordinator.sheet) { sheet in
                    switch sheet {
                    case .slippageSelector(let viewModel):
                        PolymarketSlippageSelectorView(viewModel: viewModel)
                    case .feeBreakdown(let viewModel):
                        PolymarketFeeBreakdownSheetView(viewModel: viewModel)
                    }
                }
        }
    }

    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.destination) { destination in
                switch destination {
                case .summary(let viewModel):
                    PolymarketOrderSummaryView(viewModel: viewModel)
                case .result(let viewModel):
                    PolymarketOrderResultView(viewModel: viewModel)
                        .navigationLinks(positionLinks)
                }
            }
    }

    private var positionLinks: some View {
        NavHolder()
            .navigation(item: $coordinator.positionDetailsCoordinator) { coordinator in
                PolymarketPositionDetailsCoordinatorView(coordinator: coordinator)
                    .background(PolymarketPopGestureDisabler())
            }
    }
}
