//
//  PolymarketPositionStatsPreviews.swift
//  TangemPolymarketUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Previews

#Preview("Showcase") {
    PolymarketPositionStatsShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketPositionStatsShowcase()
        .preferredColorScheme(.dark)
}

private struct PolymarketPositionStatsShowcase: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PolymarketPositionStatsGrid(tiles: .winning)

                PolymarketPositionStatsGrid(tiles: .losing)

                PolymarketPositionStatsGrid(tiles: .long)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

private extension [PolymarketPositionStatTile.Model] {
    static let winning: [PolymarketPositionStatTile.Model] = [
        .init(id: "size", caption: "Qty of Tokens", value: "1,250.00"),
        .init(id: "price", caption: "Position Price Changes", value: "64¢ → 71¢"),
        .init(id: "unrealized", caption: "Unrealized PnL", value: "+ $87.50", tone: .positive, onHintTap: {}),
        .init(id: "realized", caption: "Realized Profit", value: "+ $420.00", tone: .positive, onHintTap: {}),
    ]

    static let losing: [PolymarketPositionStatTile.Model] = [
        .init(id: "unrealized", caption: "Unrealized PnL", value: "− $87.50", tone: .negative, onHintTap: {}),
        .init(id: "realized", caption: "Realized Profit", value: "− $420.00", tone: .negative, onHintTap: {}),
    ]

    static let long: [PolymarketPositionStatTile.Model] = [
        .init(id: "size", caption: "Qty of Tokens", value: "1,250,000.00"),
        .init(id: "price", caption: "Position Price Changes", value: "0.001¢ → 99.999¢", onHintTap: {}),
    ]
}
