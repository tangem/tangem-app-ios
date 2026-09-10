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
    let viewModel: PolymarketOrderResultViewModel

    var body: some View {
        if let details = viewModel.details {
            screen.details { PolymarketOrderResultDetailsView(model: details) }
        } else {
            screen
        }
    }

    private var screen: StatusScreen<StatusIcon, EmptyView, EmptyView> {
        StatusScreen(
            title: viewModel.title,
            description: viewModel.description,
            actionTitle: Localization.predictionPlaceResultToMain,
            action: { viewModel.handleViewAction(.toMainTapped) }
        )
        .appearance(viewModel.appearance)
        .assetSlot { StatusIcon(viewModel.glyph) }
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
                resolutionDate: Date().addingTimeInterval(60 * 60 * 24 * 365)
            ),
            coordinator: nil
        )
    }
}
