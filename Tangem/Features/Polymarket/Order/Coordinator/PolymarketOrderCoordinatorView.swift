//
//  PolymarketOrderCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct PolymarketOrderCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: PolymarketOrderCoordinator

    var body: some View {
        coordinator.viewModel.map { viewModel in
            PolymarketOrderView(viewModel: viewModel)
                .toolbar(.hidden, for: .navigationBar)
                .background(FeedPopGestureEnabler())
                .navigationLinks(links)
                .modal(
                    item: $coordinator.sheet,
                    header: sheetHeader(for:),
                    content: sheetContent(for:)
                )
                .scrollIndicators(.hidden)
        }
    }

    private func sheetHeader(for sheet: PolymarketOrderCoordinator.Sheet) -> some View {
        FeedModalHeaderView(title: sheetTitle(for: sheet), onClose: { coordinator.sheet = nil })
    }

    private func sheetTitle(for sheet: PolymarketOrderCoordinator.Sheet) -> String {
        switch sheet {
        case .slippageSelector: Localization.predictionPlaceSlippage
        case .feeBreakdown: Localization.predictionPlaceFee
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: PolymarketOrderCoordinator.Sheet) -> some View {
        switch sheet {
        case .slippageSelector(let viewModel):
            PolymarketSlippageSelectorView(viewModel: viewModel)
                .legacyFooter { PolymarketSlippageSelectorFooterView(viewModel: viewModel) }
        case .feeBreakdown(let viewModel):
            PolymarketFeeBreakdownSheetView(viewModel: viewModel)
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
                        .background(PopGestureDisabler())
                }
            }
    }
}
