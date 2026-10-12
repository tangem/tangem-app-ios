//
//  PolymarketPositionHeaderPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Previews

#Preview("Showcase") {
    PolymarketPositionHeaderShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketPositionHeaderShowcase()
        .preferredColorScheme(.dark)
}

private struct PolymarketPositionHeaderShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PolymarketPositionHeader(model: .winning)

                PolymarketPositionHeader(model: .losing)

                PolymarketPositionHeader(model: .settled)
            }
            .padding(.vertical, 24)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

private extension PolymarketPositionHeader.Model {
    static let winning = PolymarketPositionHeader.Model(
        iconURL: nil,
        changeText: "10.94% ($40.50)",
        changeType: .positive,
        valueText: "$4,000.10",
        question: "Will Uzbekistan win the 2026 FIFA World Cup?",
        outcomeTitle: "Yes",
        outcomeStyle: PolymarketOutcomeStyle(outcomeIndex: 0),
        payoutAmount: "$4,400.02"
    )

    static let losing = PolymarketPositionHeader.Model(
        iconURL: nil,
        changeText: "8.10% ($32.40)",
        changeType: .negative,
        valueText: "$367.60",
        question: "Will France not win the 2026 FIFA World Cup?",
        outcomeTitle: "No",
        outcomeStyle: PolymarketOutcomeStyle(outcomeIndex: 1),
        payoutAmount: nil
    )

    static let settled = PolymarketPositionHeader.Model(
        iconURL: nil,
        changeText: "0.00% ($0.00)",
        changeType: .neutral,
        valueText: "$0.00",
        question: "Will the German Super League NRW T10 match between Westfalen Royals and SC Krefeld end in a draw?",
        outcomeTitle: "No",
        outcomeStyle: PolymarketOutcomeStyle(outcomeIndex: 1),
        payoutAmount: "$1,000.00"
    )
}
