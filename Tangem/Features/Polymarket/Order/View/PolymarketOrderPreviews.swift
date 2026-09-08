//
//  PolymarketOrderPreviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemPolymarket

// MARK: - Previews

#Preview("Yes") {
    PolymarketOrderView(viewModel: .preview(outcomeIndex: 0))
}

#Preview("No — Dark") {
    PolymarketOrderView(viewModel: .preview(outcomeIndex: 1))
        .preferredColorScheme(.dark)
}

@MainActor
private extension PolymarketOrderViewModel {
    static func preview(outcomeIndex: Int) -> PolymarketOrderViewModel {
        let market = PolymarketMarket.preview

        let model = PolymarketOrderModel(
            market: market,
            outcome: market.outcomes[outcomeIndex],
            apiProvider: PolymarketOrderPreviewAPIProvider(),
            geoblockStateProvider: PolymarketOrderPreviewGeoblockStateProvider(),
            balancePublisher: .just(output: Decimal(30000))
        )

        return PolymarketOrderViewModel(model: model, coordinator: nil)
    }
}

private extension PolymarketMarket {
    static let preview = PolymarketMarket(
        id: "preview",
        title: "Will Uzbekistan win the 2026 FIFA World Cup?",
        groupItemTitle: nil,
        imageURL: nil,
        iconURL: nil,
        status: .active,
        isNegRisk: false,
        isAcceptingOrders: true,
        startDate: nil,
        endDate: nil,
        volume: 1_240_000,
        volume24h: nil,
        liquidity: nil,
        orderIndex: nil,
        outcomes: [
            PolymarketOutcome(assetId: "yes", title: "Yes", probability: 0.15),
            PolymarketOutcome(assetId: "no", title: "No", probability: 0.85),
        ]
    )
}
