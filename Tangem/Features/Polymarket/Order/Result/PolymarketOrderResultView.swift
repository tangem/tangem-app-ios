//
//  PolymarketOrderResultView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemPolymarket
import TangemPolymarketUI
import TangemUI

struct PolymarketOrderResultView: View {
    @ObservedObject var viewModel: PolymarketOrderResultViewModel

    var body: some View {
        content
            .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var content: some View {
        if let details = viewModel.details {
            screen.details { PolymarketOrderResultDetailsView(model: details) }
        } else {
            screen
        }
    }

    private var statusIcon: StatusIcon {
        let icon = StatusIcon(viewModel.glyph)

        guard let tint = viewModel.glyphTint else { return icon }

        return icon.tint(tint)
    }

    private var screen: StatusScreen<StatusIcon, EmptyView, EmptyView> {
        let screen = StatusScreen(
            title: viewModel.title,
            description: viewModel.description,
            actionTitle: viewModel.actionTitle,
            action: { viewModel.handleViewAction(viewModel.action) }
        )
        .appearance(viewModel.appearance)
        .actionLoading(viewModel.isAwaitingPosition)
        .actionDisabled(viewModel.isActionDisabled)
        .footerAxis(.horizontal)
        .assetSlot { statusIcon }

        guard let secondaryActionTitle = viewModel.secondaryActionTitle else { return screen }

        return screen.secondaryAction(title: secondaryActionTitle) { viewModel.handleViewAction(.toMainTapped) }
    }
}

// MARK: - Previews

#Preview("Placed") {
    PolymarketOrderResultView(viewModel: .preview(state: .placed))
}

#Preview("Partially placed") {
    PolymarketOrderResultView(viewModel: .preview(state: .partiallyPlaced))
}

#Preview("No fill") {
    PolymarketOrderResultView(viewModel: .preview(state: .noFill))
}

#Preview("Still processing — Dark") {
    PolymarketOrderResultView(viewModel: .preview(state: .stillProcessing))
        .preferredColorScheme(.dark)
}

private extension PolymarketOrderResultViewModel {
    static func preview(state: State) -> PolymarketOrderResultViewModel {
        let market = PolymarketMarket.preview

        return PolymarketOrderResultViewModel(
            state: state,
            content: .init(
                market: .make(market: market, outcome: market.outcomes[1], eventTitle: "2026 FIFA World Cup winner"),
                placedAt: Date(),
                orderedAmount: 4000,
                filledAmount: 2000,
                tokensBought: 500,
                resolutionDate: Date().addingTimeInterval(60 * 60 * 24 * 365),
                executionPrice: Decimal(string: "0.42"),
                side: .buy,
                feeText: "$1.40"
            ),
            coordinator: nil
        )
    }
}
