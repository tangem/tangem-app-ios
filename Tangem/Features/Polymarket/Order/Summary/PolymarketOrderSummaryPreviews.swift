//
//  PolymarketOrderSummaryPreviews.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemPolymarket

// MARK: - Previews

#Preview("Yes") {
    PolymarketOrderSummaryView(viewModel: .preview(outcomeIndex: 0))
}

#Preview("No — Dark") {
    PolymarketOrderSummaryView(viewModel: .preview(outcomeIndex: 1))
        .preferredColorScheme(.dark)
}

@MainActor
private extension PolymarketOrderSummaryViewModel {
    static func preview(outcomeIndex: Int) -> PolymarketOrderSummaryViewModel {
        PolymarketOrderSummaryViewModel(
            model: .preview(outcomeIndex: outcomeIndex),
            account: nil,
            placementService: PolymarketOrderPlacementServiceStub(),
            coordinator: nil
        )
    }
}

private struct PolymarketOrderPlacementServiceStub: PolymarketOrderPlacementService {
    func place(
        quote: PolymarketOrderQuote,
        market: PolymarketMarket,
        outcome: PolymarketOutcome
    ) async throws -> PolymarketOrderPlacement {
        throw CancellationError()
    }
}
